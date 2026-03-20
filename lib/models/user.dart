class AppUser {
  final String id;
  final String phone;
  final bool isVerifiedBySyncCode;
  final String idPubKey;
  final String epPubKey;
  final String spPubKey;

  const AppUser({
    required this.id,
    required this.phone,
    required this.idPubKey,
    required this.epPubKey,
    required this.spPubKey,
    required this.isVerifiedBySyncCode,
  });

  static AppUser fromMap(
    Map<String, dynamic> user, {
    bool isVerifiedBySyncCode = false,
  }) {
    return AppUser(
      id: user['id'] ?? '',
      phone: user['phone'] ?? '',
      idPubKey: user['idPubKey'] ?? '',
      epPubKey: user['epPubKey'] ?? '',
      spPubKey: user['spPubKey'] ?? '',
      isVerifiedBySyncCode: isVerifiedBySyncCode,
    );
  }

  void operator [](String other) {}
}
