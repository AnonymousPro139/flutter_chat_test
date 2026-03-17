import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/crypto/chacha.dart';
import 'package:test_firebase/firebase/storage/index.dart';
import 'package:test_firebase/localstorage/index.dart';

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

Future<String> fetchFileDecryptAndCreateTempFile({
  required String chatId,
  required String fileUrl,
  required String ssk,
  required String uniqueId,
}) async {
  final String isExistTemp = await LocalStorageService().isExistTemporaryFile(
    fname: uniqueId,
    ext: FbStorage().getExtension(fileUrl),
  );

  if (isExistTemp == '') {
    final Uint8List bytes = await FbStorage().fetchEncryptedFileData(
      chatId: chatId,
      fname: fileUrl,
    );

    final Uint8List decryptedBytes = await ChaCha20().decryptFile(
      encryptedBytes: bytes,
      key: ssk,
    );

    final fpath = await LocalStorageService().createTemporaryFile(
      decryptedBytes: decryptedBytes,
      fname: uniqueId,
      ext: FbStorage().getExtension(fileUrl),
    );

    return fpath;
  } else {
    return isExistTemp;
  }
}
