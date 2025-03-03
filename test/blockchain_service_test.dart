import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:dacn3/connect/blockchain_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late BlockchainService blockchainService;  
  
  setUp(() async {
    blockchainService = BlockchainService();
    await blockchainService.init();
  });
  
  test('Kiểm tra tải ABI', () async {
    String abi = await blockchainService.loadAbi();
    expect(abi.isNotEmpty, true, reason: 'ABI không được để trống');
  });
  
  test('Tạo tài khoản mới', () async {
    List<String> account = await blockchainService.createAccount("TestUser");
    expect(account.length, 2, reason: 'Phải trả về địa chỉ và private key');
    expect(account[0].startsWith("0x"), true, reason: 'Địa chỉ phải hợp lệ');
  });
  
  test('Lấy thông tin tài khoản', () async {
  List<String> account = await blockchainService.createAccount("TestUser");
  Map<String, dynamic> accountInfo = await blockchainService.getAccount(account[0]);

    expect(accountInfo, "TestUser", reason: 'Tên tài khoản phải khớp với giá trị đã tạo');
  });
  
  test('Kiểm tra số dư tài khoản', () async {
    List<String> account = await blockchainService.createAccount("TestUser");
    BigInt balance = await blockchainService.getBalance(account[0]);
    expect(balance, BigInt.zero, reason: 'Tài khoản mới phải có số dư ban đầu là 0');
  });
  
  test('Kiểm tra số dư trước khi giao dịch', () async {
    List<String> account = await blockchainService.createAccount("TestUser");
    bool hasEnough = await blockchainService.checkBalance(account[1], 0.01);
    expect(hasEnough, false, reason: 'Tài khoản mới không nên có đủ số dư');
  });
  
  test('Thực hiện giao dịch ETH', () async {
    List<String> sender = await blockchainService.createAccount("Sender");
    List<String> recipient = await blockchainService.createAccount("Recipient");
    
    // Nạp tiền vào tài khoản sender (testnet hoặc bằng phương pháp mock)
    // Giả định rằng đã có ETH trong tài khoản sender
    String txHash = await blockchainService.transferETH(
      senderPrivateKey: sender[1],
      recipientAddress: recipient[0],
      amount: 0.01,
    );
    
    expect(txHash.isNotEmpty, true, reason: 'TX Hash không được trống nếu giao dịch thành công');
  });
}
