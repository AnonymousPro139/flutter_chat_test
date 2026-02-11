import 'package:test_firebase/firestore/services/index.dart';

class Auth extends FirestoreService {
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    final query = await firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // exists
      return {'id': query.docs.first.id, 'phone': phone};
    } else {
      // does NOT exist
      return {'id': null, 'phone': null};
    }
  }

  Future<bool> register(String phone, String name, String password) async {
    final query = await firestore.collection('users').add({
      'phone': phone,
      'name': name,
      'password': password,
    });

    if (query.id.isNotEmpty) {
      // exists
      print("Registered user with id: ${query.id}");
      return true;
    } else {
      // does NOT exist
      return false;
    }
  }
}
