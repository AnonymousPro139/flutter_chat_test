import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:path_provider/path_provider.dart";
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

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

  Future<void> deleteTemporaryFile(String filePath) async {
    try {
      // 1. Create a File reference using the path returned by your creation function
      final file = File(filePath);

      // 2. Check if the file actually exists before trying to delete it
      if (await file.exists()) {
        await file.delete();
        print('Temporary file successfully deleted.');
      } else {
        print('File not found. It may have already been deleted.');
      }
    } catch (e) {
      // 3. Catch any file system errors (e.g., permission issues)
      print('Error deleting temporary file: $e');
    }
  }

  Future<String> isExistTemporaryFile({
    required String fname,
    required String ext,
  }) async {
    final tempDir = await getTemporaryDirectory();

    final tempFile = File('${tempDir.path}/dec_${fname}.${ext}');

    if (await tempFile.exists()) {
      return tempFile.path;
    } else {
      return '';
    }
  }

  bool isImage(String ext) {
    return [
          '.jpg',
          '.jpeg',
          '.png',
          '.heic',
          '.gif',
          '.webp',
          '.bmp',
        ].contains(ext)
        ? true
        : false;
  }

  String getExtension(String filename) {
    return p.extension(filename);
  }

  String getFileNameWithoutExt(String filename) {
    return p.basenameWithoutExtension(filename);
  }

  String getSimpleRandom() {
    int rnd = Random().nextInt(9000) + 1000;

    return '$rnd';
  }

  String cutSubStringLast(String str, {int len = 15}) {
    if (str.length > 10) {
      int startIndex = (str.length - len).clamp(0, str.length);
      return str.substring(startIndex);
    } else {
      return str;
    }
  }

  Future<File> compressImageIfNeeded(File file) async {
    String extension = p.extension(file.path).toLowerCase();

    if (!isImage(extension)) {
      return file; // It's a PDF, Video, etc. Return it untouched.
    }

    // 3. Setup a temporary path for the compressed output
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // 4. Compress the image
    // This physically shrinks the dimensions and reduces the JPEG quality
    XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70, // 70 is the sweet spot for chat apps (great look, tiny size)
      minWidth: 1080, // Prevent ultra-4K images from freezing the phone
      minHeight: 1080,
      format: CompressFormat.jpeg, // Standardize to JPEG to save space
    );

    if (compressedXFile == null) return file; // Fallback if compression fails

    return File(compressedXFile.path);
  }
}
