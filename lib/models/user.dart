class AppUser {
  final String id;
  final String phone;

  const AppUser({required this.id, required this.phone});

  static fromMap(Map<String, dynamic> user) {
    return AppUser(
      id: user['id'] ?? '' as String,
      phone: user['phone'] ?? '' as String,
    );
  }
}
