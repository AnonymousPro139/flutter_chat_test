import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/crypto/index.dart';

class ChaCha20 {
  // 1. Choose the algorithm
  final algorithm = Chacha20.poly1305Aead();

  // Note: ChaCha20 uses a 12-byte nonce. If you ever switch to
  // XChaCha20, change this to 24. The MAC is always 16 bytes.
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  Future<String> encrypt(String text, String sendingSSK) async {
    final hkdf = await EncryptionService().derivedKey(sendingSSK);

    // 1. Convert the string to raw UTF-8 bytes
    // final stringBytes = utf8.encode(sendingSSK);

    // // 2. Hash the bytes using SHA-256 to guarantee exactly 32 bytes
    // final hash = await Sha256().hash(stringBytes);

    // // 3. Create the SecretKey from the resulting 32-byte hash
    // final secretKey = SecretKey(hash.bytes);
    final secretKey = SecretKey(hkdf.bytes);

    // final secretKey = await algorithm.newSecretKey();

    final secretBox = await algorithm.encrypt(
      text.codeUnits,
      secretKey: secretKey,
    );

    // print('secretKey: ${secretKey}');
    // print('Nonce: ${secretBox.nonce}');
    // print('Ciphertext: ${secretBox.cipherText}');
    // print('MAC: ${secretBox.mac.bytes}');

    return secretBoxToJson(secretBox);
  }

  Future<String> decrypt(String data, String ssk) async {
    final hkdf = await EncryptionService().derivedKey(ssk);
    final secretKey = SecretKey(hkdf.bytes);
    final secretBox = secretBoxFromJson(data);

    final txt = await algorithm.decrypt(secretBox, secretKey: secretKey);

    return String.fromCharCodes(txt);
  }

  String secretBoxToJson(SecretBox box) {
    final map = {
      'cipher': base64.encode(box.cipherText),
      'iv': base64.encode(box.nonce),
      'mac': base64.encode(box.mac.bytes),
    };
    return jsonEncode(map);
  }

  SecretBox secretBoxFromJson(String jsonString) {
    final Map<String, dynamic> map = jsonDecode(jsonString);

    return SecretBox(
      base64.decode(map['cipher']),
      nonce: base64.decode(map['iv']),
      mac: Mac(base64.decode(map['mac'])),
    );
  }

  /// Encrypts a file and returns the raw encrypted bytes directly in memory.
  Future<Uint8List> encryptFile({
    required File inputFile,
    required String ssk,
  }) async {
    final hkdf = await EncryptionService().derivedKey(ssk);
    // Read the raw file bytes into RAM
    final fileBytes = await inputFile.readAsBytes();

    // Encrypt the bytes
    final secretBox = await algorithm.encrypt(
      fileBytes,
      secretKey: SecretKey(hkdf.bytes),
    );

    // Combine Nonce + MAC + Ciphertext and convert to Uint8List
    final encryptedData = <int>[
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ];

    return Uint8List.fromList(encryptedData);
  }

  Future<Uint8List> decryptFile({
    required Uint8List encryptedBytes,
    required String key,
  }) async {
    // 1. Validate the byte array length
    if (encryptedBytes.length < _nonceLength + _macLength) {
      throw Exception('Data is too small to be valid encrypted data.');
    }

    // 2. Extract the Nonce, MAC, and Ciphertext
    final nonce = encryptedBytes.sublist(0, _nonceLength);
    final macBytes = encryptedBytes.sublist(
      _nonceLength,
      _nonceLength + _macLength,
    );
    final ciphertext = encryptedBytes.sublist(_nonceLength + _macLength);

    // 3. Reconstruct the SecretBox
    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(macBytes));
    final hkdf = await EncryptionService().derivedKey(key);
    // 4. Decrypt the data
    // This throws MacAlgorithmException if the data was tampered with or the key is wrong.
    final decryptedBytes = await algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(hkdf.bytes),
    );

    // 5. Return the raw, decrypted file bytes
    return Uint8List.fromList(decryptedBytes);
  }
}
