import 'package:cryptography/cryptography.dart';
import 'package:test_firebase/crypto/index.dart';

class SessionManager {
  // The In-Memory Cache (RAM)
  final Map<String, ({String sending, String receiving})> _cachedSharedKeys =
      {};

  Future<({String sending, String receiving})> getSharedSecretKeys({
    required String chatId,
    required String otherIdPubKey,
    required String otherEphPubKey,
    required String otherSPpubKey,
  }) async {
    // 1. Check RAM first
    if (_cachedSharedKeys.containsKey(chatId)) {
      print('⚡ FAST LOAD: Retrieved key from Riverpod cache for $chatId');
      return _cachedSharedKeys[chatId]!;
    }

    KeyPair idKeyPair = await EncryptionService().reconstructKeyPair(
      key: "identity_pri_key",
    );
    KeyPair epKeyPair = await EncryptionService().reconstructKeyPair(
      key: "eph_pri_key",
    );
    KeyPair spKeyPair = await EncryptionService().reconstructKeyPair(
      key: "signed_pre_pri_key",
    );

    final sendingSSK = await EncryptionService().calcMasterKey(
      ownIdPriKey: idKeyPair,
      ownEphPriKey: epKeyPair,
      otherIdPubKey: EncryptionService().base64ToPublicKey(otherIdPubKey),
      otherSPpubKey: EncryptionService().base64ToPublicKey(otherSPpubKey),
    );

    final receivingSSK = await EncryptionService().calcReceivingMasterKey(
      ownIdPriKey: idKeyPair,
      ownSPPriKey: spKeyPair,
      otherIdPubKey: EncryptionService().base64ToPublicKey(otherIdPubKey),
      otherEphPubKey: EncryptionService().base64ToPublicKey(otherEphPubKey),
    );

    // 3. Save to RAM
    _cachedSharedKeys[chatId] = (sending: sendingSSK, receiving: receivingSSK);
    return (sending: sendingSSK, receiving: receivingSSK);
  }

  void clearKeys() {
    _cachedSharedKeys.clear();
    print('🗑️ Riverpod memory cache cleared.');
  }
}
