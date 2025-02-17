import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TransactionService {
  final String rpcUrl;
  final String privateKey;
  final String contractAddress;
  final Web3Client web3client;
  final DeployedContract contract;

  TransactionService._internal(this.rpcUrl, this.privateKey, this.contractAddress, this.web3client, this.contract);

  static Future<TransactionService> create() async {
    await dotenv.load(fileName: ".env");

    final String rpcUrl = "https://sepolia.infura.io/v3/${dotenv.env['INFURA_PROJECT_ID']}";
    final String privateKey = dotenv.env['PRIVATE_KEY']!;
    final String contractAddress = dotenv.env['CONTRACT_ADDRESS']!;

    final httpClient = Client();
    final web3client = Web3Client(rpcUrl, httpClient);

    // Load ABI from JSON file
    final String abiString = await rootBundle.loadString('assets/ExpenseManagerABI.json');
    final contract = DeployedContract(
      ContractAbi.fromJson(abiString, "ExpenseManager"),
      EthereumAddress.fromHex(contractAddress),
    );

    return TransactionService._internal(rpcUrl, privateKey, contractAddress, web3client, contract);
  }


}