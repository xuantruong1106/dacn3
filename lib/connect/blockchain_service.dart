import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/io_client.dart';
import 'dart:typed_data';

class BlockchainService {
  final String rpcUrl = "http://127.0.0.1:8545";
  final String privateKey =
      "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  final String contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _createAccount;
  late ContractFunction _transfer;
  late EthPrivateKey _credentials;
  late ContractFunction _getAccount;
  late ContractFunction _getBalance;

  DeployedContract get contract => _contract;
  Web3Client get clinet => _client;

  EthereumAddress getAddressFromPrivateKey(String privateKey) {
    final credentials = EthPrivateKey.fromHex(privateKey);
    return credentials.address;
  }

  BlockchainService() {
    final httpClient = HttpClient()
      ..connectionTimeout = Duration(seconds: 60)
      ..idleTimeout = Duration(seconds: 60);
    _client = Web3Client(rpcUrl, IOClient(httpClient));
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<void> init() async {
    try {
      String abi = await loadAbi();
      _contract = DeployedContract(
        ContractAbi.fromJson(abi, "AccountManager"),
        EthereumAddress.fromHex(contractAddress),
      );
      _createAccount = _contract.function("createAccount");
      _transfer = _contract.function("transfer");
      _getAccount = _contract.function("getAccount");
      _getBalance = _contract.function("getBalance");

      print("BlockchainService: Hợp đồng đã được khởi tạo.");
    } catch (e) {
      print("BlockchainService: Lỗi khi khởi tạo hợp đồng: $e");
    }
  }

  Future<String> loadAbi() async {
    try {
      final abiString =
          await rootBundle.loadString('assets/AccountManager.json');
      final abiJson = jsonDecode(abiString);
      return jsonEncode(abiJson["abi"]);
    } catch (e) {
      print("BlockchainService: Lỗi khi tải ABI: $e");
      return "";
    }
  }

  Future<Map<String, dynamic>> getAccount(String address) async {
  try {
    print('🟢 Checking getAccount for address: $address');

    // Kiểm tra địa chỉ hợp lệ
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
      print("🔴 Error: Invalid Ethereum address format!");
      return {};
    }

    final ethAddress = EthereumAddress.fromHex(address);
    print('🟢 EthereumAddress object created: $ethAddress');

    final result = await _client.call(
      contract: _contract,
      function: _getAccount,
      params: [ethAddress],
    );

    print('🟢 Raw result from contract: $result');

    if (result.isEmpty || result.length != 2) {
      print("🔴 getAccount: Unexpected result format");
      return {};
    }

    print('🟢 Decoding data...');
    final dynamic nameData = result[0];
    final dynamic isRegisteredData = result[1];

    print('🟢 Name Data Type: ${nameData.runtimeType}, Value: $nameData');
    print('🟢 isRegistered Data Type: ${isRegisteredData.runtimeType}, Value: $isRegisteredData');

    // Chuyển đổi dữ liệu về dạng mong đợi
    String name = nameData.toString(); // Ép kiểu về String
    bool isRegistered = isRegisteredData as bool;

    return {'name': name, 'isRegistered': isRegistered};
  } catch (e) {
    print('🔴 getAccount error: $e');
    return {};
  }
}


  Future<List<String>> createAccount(String username) async {

    try {
      final newCredentials = EthPrivateKey.createRandom(Random.secure());
      final newAddress = newCredentials.address.hex;
      final privateKeyHex =
          bytesToHex(newCredentials.privateKey, include0x: false);

      print(privateKeyHex);

      print("Tạo tài khoản mới với địa chỉ e: $newAddress");

      final txHash = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _createAccount,
          parameters: [EthereumAddress.fromHex(newAddress), username],
          maxGas: 100000,
        ),
        chainId: 31337,
      );

      print("Tạo tài khoản blockchain thành công, TX: $txHash");

      String fixPrivateKey(String privateKeyHex) {
        // Nếu dài hơn 64 ký tự, lấy 64 ký tự cuối cùng
        return privateKeyHex.length > 64
            ? privateKeyHex.substring(privateKeyHex.length - 64)
            : privateKeyHex;
      }

      return ['$newAddress', '$privateKeyHex'];
    } catch (e) {
      print("BlockchainService: Lỗi khi tạo tài khoản: $e");
      return [];
    }
  }

  Future<BigInt> getBalance(String address) async {
    try {
      final result = await _client.call(
        contract: _contract,
        function: _getBalance,
        params: [EthereumAddress.fromHex(address)],
      );

      return result[
          0]; // Assuming getBalance returns a single BigInt value (balance in wei)
    } catch (e) {
      print('getBalance: $e');
      return BigInt.zero;
    }
  }

  // 2️⃣ HÀM KIỂM TRA SỐ DƯ
  Future<bool> checkBalance(String senderPrivateKey, double amount) async {
    try {
      EthereumAddress senderAddress =
          getAddressFromPrivateKey(senderPrivateKey);

      EtherAmount balance = await _client.getBalance(senderAddress);
      EtherAmount gasPrice = await _client.getGasPrice();

      // Tính toán tổng số tiền cần thiết (số ETH muốn gửi + phí giao dịch)
      BigInt weiAmount = BigInt.from(amount * pow(10, 18));
      BigInt totalCost = weiAmount + (gasPrice.getInWei * BigInt.from(21000));

      if (balance.getInWei < totalCost) {
        print("Lỗi: Số dư không đủ để thực hiện giao dịch.");
        return false;
      }

      return true;
    } catch (e) {
      print("Lỗi khi kiểm tra số dư: $e");
      return false;
    }
  }

  Future<String> transferETH({
    required String senderPrivateKey,
    required String recipientAddress,
    required double amount,
  }) async {
    try {
      Credentials credentials = EthPrivateKey.fromHex(senderPrivateKey);
      EthereumAddress senderAddress = credentials.address;

      BigInt weiAmount = BigInt.from(amount * pow(10, 18));

      bool hasEnoughBalance = await checkBalance(senderPrivateKey, amount);
      if (!hasEnoughBalance) {
        return "Số dư không đủ để thực hiện giao dịch.";
      }

      EtherAmount gasPrice = await _client.getGasPrice();
      var gasEstimate = await _client.estimateGas(
        sender: senderAddress,
        to: EthereumAddress.fromHex(recipientAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, weiAmount),
      );

      String txHash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(recipientAddress),
          from: senderAddress,
          value: EtherAmount.fromBigInt(EtherUnit.wei, weiAmount),
          gasPrice: gasPrice,
          maxGas: gasEstimate.toInt(),
        ),
        chainId: 31337,
      );

      print("Giao dịch thành công! TX Hash: $txHash");
      return txHash;
    } catch (e) {
      print("Lỗi khi gửi giao dịch: $e");
      return "Giao dịch thất bại";
    }
  }
}
