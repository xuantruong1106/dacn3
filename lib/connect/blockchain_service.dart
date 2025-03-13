// // ignore_for_file: avoid_print

// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:web3dart/web3dart.dart';
// import 'package:http/http.dart' as http;

// class BlockchainService {
//   static const String rpcUrl = "http://10.0.2.2:8545";
//   static const String privateKey =
//       "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
//   static const String contractAddress = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";

//   late Web3Client _client;
//   late DeployedContract _contract;
//   late EthPrivateKey _credentials;

//   late ContractFunction _createAccount;
//   late ContractFunction _deposit;
//   late ContractFunction _transfer;
//   late ContractFunction _getBalance;

//   // Singleton pattern
//   static final BlockchainService _instance = BlockchainService._internal();
//   factory BlockchainService() => _instance;
//   BlockchainService._internal() {
//     _client = Web3Client(rpcUrl, http.Client());
//     _credentials = EthPrivateKey.fromHex(privateKey);
//   }

//   Future<void> init() async {
//     try {
//       String abi = await _loadAbi();
//       _contract = DeployedContract(
//         ContractAbi.fromJson(abi, "AccountManager"),
//         EthereumAddress.fromHex(contractAddress),
//       );
//       _createAccount = _contract.function("createAccount");
//       _deposit = _contract.function("deposit");
//       _transfer = _contract.function("transfer");
//       _getBalance = _contract.function("getBalance");

//       print("BlockchainService: Contract initialized at $contractAddress");
//     } catch (e) {
//       print("BlockchainService: Error initializing contract: $e");
//       rethrow;
//     }
//   }

//   Future<String> _loadAbi() async {
//     try {
//       final abiString =
//           await rootBundle.loadString('assets/AccountManager.json');
//       final abiJson = jsonDecode(abiString);
//       return jsonEncode(abiJson["abi"]);
//     } catch (e) {
//       print("BlockchainService: Error loading ABI: $e");
//       rethrow;
//     }
//   }

//   Future<String> createAccount(String username) async {
//     try {
//       final txHash = await _client.sendTransaction(
//         _credentials,
//         Transaction.callContract(
//           contract: _contract,
//           function: _createAccount,
//           parameters: [username],
//           maxGas: 100000,
//         ),
//         chainId: 31337,
//       );
//       print("Account created successfully, TX: $txHash");
//       return txHash;
//     } catch (e) {
//       print("BlockchainService: Error creating account: $e");
//       return "";
//     }
//   }

//   Future<String> deposit(double amountInEth) async {
//     try {
//       final weiAmount = BigInt.from(amountInEth * 1000000000000000000);

//       final txHash = await _client.sendTransaction(
//         _credentials,
//         Transaction.callContract(
//           contract: _contract,
//           function: _deposit,
//           value: EtherAmount.fromBigInt(EtherUnit.wei, weiAmount),
//           maxGas: 100000, parameters: [],
//         ),
//         chainId: 31337,
//       );
//       print("Deposit successful, TX: $txHash");
//       return txHash;
//     } catch (e) {
//       print("BlockchainService: Error depositing: $e");
//       return "";
//     }
//   }

//   Future<String> transfer(String recipientAddress, BigInt amountInEth) async {
//     try {
//       print('BlockchainService transfer $recipientAddress, $amountInEth');
//       final txHash = await _client.sendTransaction(
//         _credentials,
//         Transaction.callContract(
//           contract: _contract,
//           function: _transfer,
//           parameters: [
//             EthereumAddress.fromHex(recipientAddress),
//             amountInEth,
//           ],
//           value: EtherAmount.fromBigInt(EtherUnit.wei, amountInEth), // Gửi ETH qua value
//           maxGas: 100000,
//         ),
//         chainId: 31337,
//       );
//       print("Transfer successful, TX: $txHash");
//       return txHash;
//     } catch (e) {
//       print("BlockchainService: Error transferring: $e");
//       return "";
//     }
//   }

//   Future<BigInt> checkBalance() async {
//     try {
//       final result = await _client.call(
//         contract: _contract,
//         function: _getBalance,
//         params: [],
//       );
//       print("Balance retrieved: ${result[0]} wei");
//       return result[0] as BigInt;
//     } catch (e) {
//       print("BlockchainService: Error getting balance: $e");
//       return BigInt.zero;
//     }
//   }

//   Future<Map<String, dynamic>> checkBeforeTransfer(String recipientAddress, double amountInEth) async {
//     try {
//       final weiAmount = BigInt.from(amountInEth * 1000000000000000000); // 1 ETH = 10^18 wei
//       final currentBalance = await checkBalance();

//       // Không kiểm tra số dư vì transfer() dùng msg.value, không trừ balance
//       print("BlockchainService: Balance before transfer: $currentBalance wei");

//       final txHash = await transfer(recipientAddress, weiAmount);
//       if (txHash == "") {
//         print("BlockchainService: Transfer failed");
//         return {'isSufficient': false, 'weiAmount': weiAmount};
//       }

//       final currentBalanceAfter = await checkBalance();
//       print('BlockchainService-checkBeforeTransfer-checkBalance: $currentBalanceAfter');
//       print('BlockchainService-checkBeforeTransfer: transfer done');

//       return {'isSufficient': true, 'weiAmount': weiAmount};
//     } catch (e) {
//       print("BlockchainService: Error checking balance before transfer: $e");
//       return {'isSufficient': false, 'weiAmount': BigInt.zero};
//     }
//   }
// }


// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

class BlockchainService {
  static const String rpcUrl = "http://10.0.2.2:8545";
  static const String privateKey =
      "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  static const String contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  late Web3Client _client;
  late DeployedContract _contract;
  late EthPrivateKey _credentials;

  late ContractFunction _createAccount;
  late ContractFunction _deposit;
  late ContractFunction _transfer;
  late ContractFunction _getBalance;

  // Singleton pattern
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal() {
    _client = Web3Client(rpcUrl, http.Client());
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<void> init() async {
    try {
      String abi = await _loadAbi();
      _contract = DeployedContract(
        ContractAbi.fromJson(abi, "AccountManager"),
        EthereumAddress.fromHex(contractAddress),
      );
      _createAccount = _contract.function("createAccount");
      _deposit = _contract.function("deposit");
      _transfer = _contract.function("transfer");
      _getBalance = _contract.function("getBalance");

      print("BlockchainService: Contract initialized at $contractAddress");
    } catch (e) {
      print("BlockchainService: Error initializing contract: $e");
      rethrow;
    }
  }

  Future<String> _loadAbi() async {
    try {
      final abiString =
          await rootBundle.loadString('assets/AccountManager.json');
      final abiJson = jsonDecode(abiString);
      return jsonEncode(abiJson["abi"]);
    } catch (e) {
      print("BlockchainService: Error loading ABI: $e");
      rethrow;
    }
  }

  Future<String> createAccount(String username) async {
    try {
      final txHash = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _createAccount,
          parameters: [username],
          maxGas: 100000,
        ),
        chainId: 31337,
      );
      print("Account created successfully, TX: $txHash");
      return txHash;
    } catch (e) {
      print("BlockchainService: Error creating account: $e");
      return "";
    }
  }

  Future<String> deposit(double amountInEth) async {
    try {
      final weiAmount = BigInt.from(amountInEth * 1000000000000000000);
      final txHash = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _deposit,
          value: EtherAmount.fromBigInt(EtherUnit.wei, weiAmount),
          maxGas: 100000,
          parameters: [],
        ),
        chainId: 31337,
      );
      print("Deposit successful, TX: $txHash");
      return txHash;
    } catch (e) {
      print("BlockchainService: Error depositing: $e");
      return "";
    }
  }

  Future<String> transfer(String recipientAddress, BigInt amountInEth) async {
    try {
      print('BlockchainService transfer $recipientAddress, $amountInEth');
      final txHash = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _transfer,
          parameters: [
            EthereumAddress.fromHex(recipientAddress),
            amountInEth,
          ],
          value: EtherAmount.fromBigInt(EtherUnit.wei, amountInEth), // Gửi ETH qua value
          maxGas: 100000,
        ),
        chainId: 31337,
      );
      print("Transfer successful, TX: $txHash");
      return txHash;
    } catch (e) {
      print("BlockchainService: Error transferring: $e");
      return "";
    }
  }

  Future<BigInt> checkBalance() async {
    try {
      final result = await _client.call(
        contract: _contract,
        function: _getBalance,
        params: [],
      );
      print("Balance retrieved: ${result[0]} wei");
      return result[0] as BigInt;
    } catch (e) {
      print("BlockchainService: Error getting balance: $e");
      return BigInt.zero;
    }
  }

  Future<BigInt> checkWalletBalance(String address) async {
    try {
      final balance = await _client.getBalance(EthereumAddress.fromHex(address));
      print("Wallet balance of $address: ${EtherAmount.fromBigInt(EtherUnit.wei, balance.getInWei).getValueInUnit(EtherUnit.ether)} ETH");
      return balance.getInWei;
    } catch (e) {
      print("Error getting wallet balance: $e");
      return BigInt.zero;
    }
  }

  Future<Map<String, dynamic>> checkBeforeTransfer(String recipientAddress, double amountInEth) async {
    try {
      final weiAmount = BigInt.from(amountInEth * 1000000000000000000);
      final senderAddress = _credentials.address.hex;
      final walletBalance = await checkWalletBalance(senderAddress);

      if (walletBalance < weiAmount) {
        print("BlockchainService: Insufficient wallet balance. Required: $weiAmount wei, Available: $walletBalance wei");
        return {'isSufficient': false, 'weiAmount': weiAmount};
      }

      final txHash = await transfer(recipientAddress, weiAmount);
      if (txHash == "") {
        print("BlockchainService: Transfer failed");
        return {'isSufficient': false, 'weiAmount': weiAmount};
      }

      final walletBalanceAfter = await checkWalletBalance(senderAddress);
      print('BlockchainService-checkBeforeTransfer-walletBalance: $walletBalanceAfter');
      print('BlockchainService-checkBeforeTransfer: transfer done');

      return {'isSufficient': true, 'weiAmount': weiAmount};
    } catch (e) {
      print("BlockchainService: Error checking balance before transfer: $e");
      return {'isSufficient': false, 'weiAmount': BigInt.zero};
    }
  }

  

}