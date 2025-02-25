import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/io_client.dart';
import 'dart:typed_data';

class BlockchainService {
  final String rpcUrl = "http://10.0.2.2:8545";
  final String privateKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  final String contractAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _createAccount;
  late EthPrivateKey _credentials;

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
      print("BlockchainService: Đã khởi tạo hợp đồng thành công.");
    } catch (e) {
      print("BlockchainService: Lỗi khi khởi tạo hợp đồng: $e");
    }
  }

  Future<String> createAccount(String username) async {
    try {
      final newCredentials = EthPrivateKey.createRandom(Random.secure());
      final newAddress = newCredentials.address.hex;
      print("Tạo tài khoản mới với địa chỉ: $newAddress");

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

      return newAddress;
    } catch (e) {
      print("BlockchainService: Lỗi khi tạo tài khoản: $e");
      return "";
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
}
