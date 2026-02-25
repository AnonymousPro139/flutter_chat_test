import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/models/user.dart';

class UserFirestoreService extends FirestoreService {
  Future<AppUser?> searchUserByPhone(String phone) async {
    final snapshot = await firestore
        .collection('public_profiles')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data();
      return AppUser(id: snapshot.docs.first.id, phone: user['phone']);
    } else {
      // does NOT exist
      return null;
    }
  }
}
