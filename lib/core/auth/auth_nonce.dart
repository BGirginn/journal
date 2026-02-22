import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

String generateNonce([int length = 32]) {
  if (length <= 0) {
    throw ArgumentError.value(length, 'length', 'Nonce length must be > 0');
  }
  final random = Random.secure();
  return List<String>.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}

String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
