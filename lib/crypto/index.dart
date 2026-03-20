import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/localstorage/index.dart';

class EncryptionService {
  final _algorithm = X25519();
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  Future<KeyPair> generateKeyFromSyncCode({
    required String syncCode,
    String userSalt = 'salt',
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100,
      bits: 256, // This results in 32 bytes (256 / 8)
    );

    // 1. Turn Sync Code into a 32-byte Seed
    final seed = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(syncCode)),
      nonce: utf8.encode(userSalt), // Use user's UID as salt
    );

    final seedBytes = await seed.extractBytes();

    return await _algorithm.newKeyPairFromSeed(seedBytes);
  }

  Future<String> createIdentityKeyPair({
    required String uid,
    required String syncCode,
    isCheckPubkey = true,
  }) async {
    final keyPair = await generateKeyFromSyncCode(
      syncCode: syncCode,
      userSalt: uid,
    );

    final keyPairData = await keyPair.extract() as SimpleKeyPairData;

    final publicKey = await keyPairData.extractPublicKey();
    final privateKeyBytes = await keyPairData.extractPrivateKeyBytes();

    LocalStorageService().saveData(
      'identity_pri_key',
      base64Encode(privateKeyBytes),
    );

    return base64Encode(publicKey.bytes);
  }

  Future<String> createSignedPreKeyPair({
    required String uid,
    required String phone,
  }) async {
    final keyPair = await generateKeyFromSyncCode(
      syncCode: uid,
      userSalt: phone,
    );

    final keyPairData = await keyPair.extract() as SimpleKeyPairData;

    final publicKey = await keyPairData.extractPublicKey();
    final privateKeyBytes = await keyPairData.extractPrivateKeyBytes();

    LocalStorageService().saveData(
      'signed_pre_pri_key',
      base64Encode(privateKeyBytes),
    );

    return base64Encode(publicKey.bytes);
  }

  Future<String> createEphemeralKeyPair({required String phone}) async {
    final keyPair = await generateKeyFromSyncCode(syncCode: phone);

    final keyPairData = await keyPair.extract() as SimpleKeyPairData;

    final publicKey = await keyPairData.extractPublicKey();
    final privateKeyBytes = await keyPairData.extractPrivateKeyBytes();

    LocalStorageService().saveData(
      'eph_pri_key',
      base64Encode(privateKeyBytes),
    );
    return base64Encode(publicKey.bytes);
  }

  Future<SecretKey> createSharedSecretKey({
    required KeyPair myKeyPair,
    required PublicKey otherPublicKey,
  }) async {
    final sharedSecretKey = await _algorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: otherPublicKey,
    );

    return sharedSecretKey;
  }

  Future<SimpleKeyPair> reconstructKeyPair({required String key}) async {
    // 1. Get the Base64 string from your storage
    final String? base64PriKey = await LocalStorageService().getData(key);

    if (base64PriKey == null) {
      throw Exception("No private key found in storage");
    }

    // 2. Decode Base64 to bytes (Uint8List)
    final List<int> privateKeyBytes = base64.decode(base64PriKey);

    final keyPair = await _algorithm.newKeyPairFromSeed(privateKeyBytes);

    return keyPair;
  }

  PublicKey base64ToPublicKey(String base64Key) {
    // 1. Decode the string into raw bytes
    final List<int> keyBytes = base64.decode(base64Key);

    // 2. Wrap it in a SimplePublicKey object
    // Note: Specify the correct KeyPairType (X25519 is the default for E2EE)
    return SimplePublicKey(keyBytes, type: KeyPairType.x25519);
  }

  String decodeBase64ToString(String base64String) {
    try {
      // 1. Decode the Base64 string into a list of raw bytes
      List<int> decodedBytes = base64Decode(base64String);

      // 2. Decode the raw bytes into a readable UTF-8 string
      return utf8.decode(decodedBytes);
    } catch (e) {
      // 3. Catch errors (e.g., if the string isn't actually valid base64)
      print('Error decoding Base64: $e');
      return '';
    }
  }

  Future<SecretKeyData> derivedKey(String input) async {
    // 1. Convert the plain text string into UTF-8 bytes
    final data = utf8.encode(input);

    // 2. Wrap the bytes in the required SecretKey object
    final secretKey = SecretKey(data);

    // 3. Perform the HKDF derivation
    return await hkdf.deriveKey(
      secretKey: secretKey,
      nonce: utf8.encode("system"),
    );
  }

  Future<String> calcMasterKey({
    required KeyPair ownIdPriKey,
    required PublicKey otherSPpubKey,
    required KeyPair ownEphPriKey,
    required PublicKey otherIdPubKey,
  }) async {
    final a1 = await createSharedSecretKey(
      myKeyPair: ownIdPriKey,
      otherPublicKey: otherSPpubKey,
    );
    final a2 = await createSharedSecretKey(
      myKeyPair: ownEphPriKey,
      otherPublicKey: otherIdPubKey,
    );
    final a3 = await createSharedSecretKey(
      myKeyPair: ownEphPriKey,
      otherPublicKey: otherSPpubKey,
    );

    final k1 = await secretKeyToHex(a1);
    final k2 = await secretKeyToHex(a2);
    final k3 = await secretKeyToHex(a3);

    return k1 + k2 + k3;
  }

  Future<String> calcReceivingMasterKey({
    required KeyPair ownIdPriKey,
    required PublicKey otherIdPubKey,
    required KeyPair ownSPPriKey,
    required PublicKey otherEphPubKey,
  }) async {
    final a1 = await createSharedSecretKey(
      myKeyPair: ownSPPriKey,
      otherPublicKey: otherIdPubKey,
    );
    final a2 = await createSharedSecretKey(
      myKeyPair: ownIdPriKey,
      otherPublicKey: otherEphPubKey,
    );
    final a3 = await createSharedSecretKey(
      myKeyPair: ownSPPriKey,
      otherPublicKey: otherEphPubKey,
    );

    final k1 = await secretKeyToHex(a1);
    final k2 = await secretKeyToHex(a2);
    final k3 = await secretKeyToHex(a3);

    return k1 + k2 + k3;
  }

  Future<String> secretKeyToHex(SecretKey secretKey) async {
    // 1. Safely extract the raw bytes from the SecretKey object
    final List<int> keyBytes = await secretKey.extractBytes();

    // 2. Map each byte to a 2-character hex string and join them
    final String hexString = keyBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');

    return hexString;
  }

  SecretKey hexToSecretKey(String hexString) {
    final List<int> keyBytes = [];

    // Parse the string 2 characters at a time
    for (int i = 0; i < hexString.length; i += 2) {
      final hexPair = hexString.substring(i, i + 2);
      keyBytes.add(int.parse(hexPair, radix: 16));
    }

    // Rebuild the SecretKey object
    return SecretKey(keyBytes);
  }

  Future<String> calcMasterKeyGroup({
    required String otherIdKey,
    required String otherSPKey,
    required String otherEphKey,
  }) async {
    final a1 = await derivedKey(otherIdKey);
    final a2 = await derivedKey(otherSPKey);
    final a3 = await derivedKey(otherEphKey);

    final k1 = await secretKeyToHex(a1);
    final k2 = await secretKeyToHex(a2);
    final k3 = await secretKeyToHex(a3);

    return k1 + k2 + k3;
  }
}
