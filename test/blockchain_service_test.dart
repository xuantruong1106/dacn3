import 'package:flutter_test/flutter_test.dart';
import '../lib/connect/blockchain_service.dart'; // Thay đổi đường dẫn nếu cần
import 'dart:math';

void main() {
  late BlockchainService blockchainService;

  // Khởi tạo BlockchainService trước mỗi test
  setUp(() {
    blockchainService = BlockchainService();
  });

  // Kiểm tra việc khởi tạo BlockchainService
  test('Khởi tạo BlockchainService', () async {
    await blockchainService.init();
    expect(blockchainService.clinet, isNotNull);
    expect(blockchainService.contract, isNotNull);
  });

  // Kiểm tra hàm createAccount
  test('Tạo tài khoản mới', () async {
    String username = "testuser";
    List<String> result = await blockchainService.createAccount(username);

    expect(result, isNotEmpty);
    expect(result.length, 2); // Địa chỉ và private key
    expect(result[0], isNotEmpty); // Địa chỉ mới tạo
    expect(result[1], isNotEmpty); // Private key mới tạo
  });

  // Kiểm tra hàm getAccount
  test('Lấy tài khoản', () async {
    String address = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Địa chỉ ví test
    String accountInfo = await blockchainService.getAccount(address);

    expect(accountInfo, isNotEmpty);
  });

  // Kiểm tra hàm validateRecipient
  test('Kiểm tra tính hợp lệ của địa chỉ người nhận', () async {
    String recipientAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Địa chỉ ví test
    bool isValid = await blockchainService.validateRecipient(recipientAddress);

    expect(isValid, isTrue); // Giả sử địa chỉ là hợp lệ
  });

  // Kiểm tra hàm checkBalance
  test('Kiểm tra số dư', () async {
    String senderPrivateKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Private key test
    double amount = 0.1;

    bool hasEnoughBalance = await blockchainService.checkBalance(senderPrivateKey, amount);

    expect(hasEnoughBalance, isTrue); // Giả sử người gửi có đủ số dư
  });

  // Kiểm tra hàm transferETH
  test('Chuyển ETH', () async {
    String senderPrivateKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Private key test
    String recipientAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Địa chỉ người nhận
    double amount = 0.1; // Số ETH cần chuyển

    String txHash = await blockchainService.transferETH(
      senderPrivateKey: senderPrivateKey,
      recipientAddress: recipientAddress,
      amount: amount,
    );

    expect(txHash, isNotEmpty);
  });
}
