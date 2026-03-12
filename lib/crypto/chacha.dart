import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/crypto/index.dart';

class ChaCha20 {
  // 1. Choose the algorithm
  final algorithm = Chacha20.poly1305Aead();

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
    print("data ${data}");
    print("ssk ${ssk}");

    final hkdf = await EncryptionService().derivedKey(ssk);
    final secretKey = SecretKey(hkdf.bytes);
    final secretBox = secretBoxFromJson(data);

    print("secretBox ${secretBox}");

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
}
