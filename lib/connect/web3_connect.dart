import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

class Web3Connect {
  final String rpcUrl;
  final String privateKey;
  final String contractAddress;
  final Web3Client web3client;
  final DeployedContract contract;

  Web3Connect._internal(this.rpcUrl, this.privateKey, this.contractAddress, this.web3client, this.contract);

  static Future<Web3Connect> create() async {
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

    return Web3Connect._internal(rpcUrl, privateKey, contractAddress, web3client, contract);
  }

  Future<String> createAccount(String name) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final createAccountFunction = contract.function("createAccount");
    final result = await web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: createAccountFunction,
        parameters: [name],
      ),
      chainId: 11155111, // Sepolia testnet chain ID
    );

    // Assuming the contract returns the account address
    final receipt = await web3client.getTransactionReceipt(result);
    final accountAddress = receipt?.contractAddress?.hex ?? '';
    return accountAddress;
  }

  Future<void> addTransaction(int amount, String type) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final addTransactionFunction = contract.function("addTransaction");
    await web3client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: addTransactionFunction,
        parameters: [BigInt.from(amount), type],
      ),
      chainId: 11155111, // Sepolia testnet chain ID
    );
  }

  Future<BigInt> getTotalIncome() async {
    final getTotalIncomeFunction = contract.function("getTotalIncome");
    final result = await web3client.call(
      contract: contract,
      function: getTotalIncomeFunction,
      params: [],
    );
    return result.first as BigInt;
  }

  Future<BigInt> getTotalExpense() async {
    final getTotalExpenseFunction = contract.function("getTotalExpense");
    final result = await web3client.call(
      contract: contract,
      function: getTotalExpenseFunction,
      params: [],
    );
    return result.first as BigInt;
  }

  Future<BigInt> getBalance() async {
    final getBalanceFunction = contract.function("getBalance");
    final result = await web3client.call(
      contract: contract,
      function: getBalanceFunction,
      params: [],
    );
    return result.first as BigInt;
  }
}

final db = Web3Connect.create();

