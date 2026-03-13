import "dart:io";
import "dart:typed_data";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:path_provider/path_provider.dart";

class LocalStorageService {
  final _storage = const FlutterSecureStorage();

  void deleteKeys() async {
    await _storage.deleteAll();
  }

  void saveData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getData(String key) async {
    return await _storage.read(key: key);
  }

  Future<String> createTemporaryFile({
    required String fname,
    required String ext,
    required Uint8List decryptedBytes,
  }) async {
    final tempDir = await getTemporaryDirectory();

    // 2. Create a unique file name for this cached image
    final tempFile = File('${tempDir.path}/dec_${fname}.${ext}'); // .jpg

    // 3. Write your decrypted bytes to this temporary file
    await tempFile.writeAsBytes(decryptedBytes);

    return tempFile.path;
  }
}
