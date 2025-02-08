import 'dart:math';

String generateRandomCardNumber() {
  final random = Random();
  String cardNumber = '';
  for (int i = 0; i < 16; i++) {
    cardNumber += random.nextInt(10).toString();
  }
  return cardNumber;
}

String generateRandomCVV() {
  final random = Random();
  String cvv = '';
  for (int i = 0; i < 3; i++) {
    cvv += random.nextInt(10).toString();
  }
  return cvv;
}