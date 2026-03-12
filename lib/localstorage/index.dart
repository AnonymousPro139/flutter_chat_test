import "package:flutter_secure_storage/flutter_secure_storage.dart";

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
}
