import 'dart:math';

String generateRandomCVV() {
  final random = Random();
  String cvv = '';
  for (int i = 0; i < 3; i++) {
    cvv += random.nextInt(10).toString();
  }
  return cvv;
}