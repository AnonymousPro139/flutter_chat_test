import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/localstorage/index.dart';

class EncryptionService {
  final _algorithm = X25519();

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

  /// Generates a new X25519 key pair and saves the private part locally.
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
}
