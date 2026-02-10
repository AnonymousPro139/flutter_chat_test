class AppUser {
  final String id;
  final String phone;

  const AppUser({required this.id, required this.phone});

  static AppUser fromMap(Map<String, dynamic> user) {
    return AppUser(id: user['id'] ?? '', phone: user['phone'] ?? '');
  }
}
