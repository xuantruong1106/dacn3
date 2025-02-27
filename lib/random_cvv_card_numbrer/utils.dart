import 'dart:math';

String generateRandomCVV() {
  final random = Random();
  String cvv = '';
  for (int i = 0; i < 3; i++) {
    cvv += random.nextInt(10).toString();
  }
  return cvv;
}


String generateRandomhash() {
  final random = Random();
  String hash = '';
  for (int i = 0; i < 12; i++) {
    hash += random.nextInt(30).toString();
  }
  return hash;
}