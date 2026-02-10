import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/models/user.dart';

class UserFirestoreService extends FirestoreService {
  Future<AppUser?> searchUserByPhone(String phone) async {
    final query = await firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      print("RES: ${query.docs.first.id} ");
      final user = query.docs.first.data();
      return AppUser(id: query.docs.first.id, phone: user['phone']);
    } else {
      // does NOT exist
      return null;
    }
  }
}
