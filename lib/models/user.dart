class AppUser {
  final String id;
  final String phone;
  final bool isVerifiedBySyncCode;

  const AppUser({
    required this.id,
    required this.phone,
    required this.isVerifiedBySyncCode,
  });

  static AppUser fromMap(
    Map<String, dynamic> user, {
    bool isVerifiedBySyncCode = false,
  }) {
    return AppUser(
      id: user['id'] ?? '',
      phone: user['phone'] ?? '',
      isVerifiedBySyncCode: isVerifiedBySyncCode,
    );
  }

  void operator [](String other) {}
}
