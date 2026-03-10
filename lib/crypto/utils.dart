import 'dart:convert';

import 'package:cryptography/cryptography.dart';

Future<String> createSha256Hash(String input) async {
  // 1. Initialize the SHA256 algorithm
  final algorithm = Sha256();

  // 2. Convert the input string to bytes
  final bytes = utf8.encode(input);

  // 3. Calculate the hash
  final hash = await algorithm.hash(bytes);

  // 4. Return the hash as a Hexadecimal string (common for Firestore)
  // return hash.bytes
  //     .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
  //     .join();

  // ALTERNATIVE: Use base64 if you prefer shorter strings
  return base64Encode(hash.bytes);
}
