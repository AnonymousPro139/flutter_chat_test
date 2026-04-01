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
}
