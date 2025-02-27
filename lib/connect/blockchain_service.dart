import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/io_client.dart';
import 'dart:typed_data';

class BlockchainService {
  final String rpcUrl = "http://10.0.2.2:8545";
  final String privateKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
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

      print("BlockchainService: Đã khởi tạo hợp đồng thành công.");
    } catch (e) {
      print("BlockchainService: Lỗi khi khởi tạo hợp đồng: $e");
    }
  }

Future<String> getAccount(String address) async {
  try {
    print('getAccount-address: $address ${EthereumAddress.fromHex(address)}');
    final result = await _client.call(
      contract: _contract,
      function: _getAccount,
      params: [EthereumAddress.fromHex(address)],
    );
    print('error in here');

    // Ensure the result has the expected structure
    if (result.isEmpty || result.length != 2) {
      print("getAccount: Unexpected result format");
      return '';
    }

    String name = result[0];
    bool isRegistered = result[1];

    // Debug prints
    print("Account Name: $name");
    print("Is Registered: $isRegistered");

    return name;
  } catch (e) {
    print('getAccount error: $e');
    return '';
  }
}



Future<BigInt> getBalance(String address) async {
  try {
    final result = await _client.call(
      contract: _contract,
      function: _getBalance,
      params: [EthereumAddress.fromHex(address)],
    );

    return result[0];  // Assuming getBalance returns a single BigInt value (balance in wei)
  } catch (e) {
    print('getBalance: $e');
    return BigInt.zero;
  }
}

  Future<List<String>> createAccount(String username) async {
    try {
          final newCredentials = EthPrivateKey.createRandom(Random.secure());
          final newAddress = newCredentials.address.hex;
          final privateKeyHex = bytesToHex(newCredentials.privateKey, include0x: false);

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

          return [ '$newAddress', '$privateKeyHex'];

    } catch (e) {
      print("BlockchainService: Lỗi khi tạo tài khoản: $e");
      return [];
    }
  }

  Future<String> loadAbi() async {
    try {
      final abiString = await rootBundle.loadString('assets/AccountManager.json');
      final abiJson = jsonDecode(abiString);
      return jsonEncode(abiJson["abi"]);
    } catch (e) {
      print("BlockchainService: Lỗi khi tải ABI: $e");
      return "";
    }
  }

  Future<bool> validateRecipient(String recipientAddress) async {
    try {
      EthereumAddress address = EthereumAddress.fromHex(recipientAddress);
      EtherAmount balance = await _client.getBalance(address);
      
      // Nếu số dư tồn tại, người nhận hợp lệ
      if (balance.getInWei >= BigInt.zero) {
        return true;
      }
    } catch (e) {
      print("Lỗi khi kiểm tra địa chỉ người nhận: $e");
    }
    
    return false; // Địa chỉ không hợp lệ
  }

  // 2️⃣ HÀM KIỂM TRA SỐ DƯ
  Future<bool> checkBalance(String senderPrivateKey, double amount) async {
    try {
      // Tạo Credentials từ private key để lấy địa chỉ ví người gửi
      Credentials credentials = EthPrivateKey.fromHex(senderPrivateKey);
      EthereumAddress senderAddress = credentials.address; // Đã sửa lỗi extractAddress()

      // Lấy số dư của người gửi
      EtherAmount balance = await _client.getBalance(senderAddress);

      // Chuyển đổi số ETH sang Wei
      BigInt weiAmount = BigInt.from(amount * 1e18);

      if (balance.getInWei < weiAmount) {
        print("Lỗi: Số dư không đủ để thực hiện giao dịch");
        return false;
      }

      return true;
    } catch (e) {
      print("Lỗi khi kiểm tra số dư: $e");
      return false;
    }
  }

  // Future<String> transferETH({
  //   required String senderPrivateKey,
  //   required String recipientAddress,
  //   required double amount, // Số ETH cần chuyển
  // }) async {
  //   try {
  //     // 3️⃣ Chuyển đổi ETH sang Wei
  //     BigInt weiAmount = BigInt.from(amount * 1e12);

  //     // 4️⃣ Load tài khoản từ private key
  //     Credentials credentials = EthPrivateKey.fromHex(senderPrivateKey);
  //     EthereumAddress senderAddress = credentials.address;

  //     // // 5️⃣ Tạo giao dịch
  //     // Transaction tx = Transaction.callContract(
  //     //   contract: _contract,
  //     //   function: _transfer,
  //     //   parameters: [EthereumAddress.fromHex(recipientAddress), weiAmount],
  //     //   maxGas: 100000,
  //     // );

  //     String tx = await _client.sendTransaction(
  //       credentials,
  //       Transaction(
  //         to: EthereumAddress.fromHex(recipientAddress),
  //         from: senderAddress,
  //         value: EtherAmount.fromBigInt (EtherUnit.ether, weiAmount),
  //         maxGas: 100000,
  //       ),
  //       chainId: 31337,  // Testnet chain id
  //     );

  //     // 6️⃣ Ký và gửi giao dịch
  //     String txHash = await _client.sendTransaction(credentials, tx as Transaction, chainId: 31337); 

  //     print("Giao dịch thành công! TX Hash: $txHash");
  //     return txHash;
  //   } catch (e) {
  //     print("Lỗi khi gửi giao dịch: $e");
  //     return "Giao dịch thất bại";
  //   }
  // }
  Future<String> transferETH({
  required String senderPrivateKey,
  required String recipientAddress,
  required double amount, // Số ETH cần chuyển
}) async {
  try {
    // Chuyển đổi ETH sang Wei
    BigInt weiAmount = BigInt.from(amount * 1e18); // Ensure conversion is correct (1 ETH = 1e18 Wei)

    // Load tài khoản từ private key
    Credentials credentials = EthPrivateKey.fromHex(senderPrivateKey);
    EthereumAddress senderAddress = credentials.address;

    // Kiểm tra số dư của người gửi
    EtherAmount senderBalance = await _client.getBalance(senderAddress);
    if (senderBalance.getInWei < weiAmount + BigInt.from(21000 * 100)) {
      // 21000 gas là gas cơ bản cho một giao dịch chuyển ETH, điều chỉnh nếu cần
      print("Số dư không đủ để thực hiện giao dịch (bao gồm phí gas).");
      return "Số dư không đủ để thực hiện giao dịch.";
    }

    // Estimating gas for the transaction
    var gasEstimate = await _client.estimateGas(
      sender: senderAddress,
      to: EthereumAddress.fromHex(recipientAddress),
      value: EtherAmount.fromBigInt(EtherUnit.ether, weiAmount),
    );

    // Tạo giao dịch
    String txHash = await _client.sendTransaction(
      credentials,
      Transaction(
        to: EthereumAddress.fromHex(recipientAddress),
        from: senderAddress,
        value: EtherAmount.fromBigInt(EtherUnit.ether, weiAmount),
        gasPrice: EtherAmount.inWei(BigInt.from(28711)), // gas price (điều chỉnh theo nhu cầu)
        maxGas: gasEstimate.toInt(),
      ),
      chainId: 31337,  // Testnet chain id
    );

    print("Giao dịch thành công! TX Hash: $txHash");
    return txHash;
  } catch (e) {
    print("Lỗi khi gửi giao dịch: $e");
    return "Giao dịch thất bại";
  }
}

}
