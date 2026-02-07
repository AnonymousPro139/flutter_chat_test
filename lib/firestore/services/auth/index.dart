import 'package:test_firebase/firestore/services/index.dart';

class Auth extends FirestoreService {
  void signIn(String phone, String password) {
    // Implement sign-in logic here
  }

  Future<Map<String, dynamic>?> login(String phone, String password) async {
    // check phone and password

    // firestore
    //     .collection('users')
    //     .where('phone', isEqualTo: phone)
    //     .where('password', isEqualTo: password)
    //     .get()
    //     .then((querySnapshot) {
    //       if (querySnapshot.docs.isNotEmpty) {
    //         // User found, handle successful login
    //         print('Login successful for phone: $phone');
    //       } else {
    //         // No user found with the provided credentials
    //         print('Login failed: Invalid phone or password');
    //       }
    //     })
    //     .catchError((error) {
    //       // Handle any errors that occur during the query
    //       print('Error during login: $error');
    //     });

    // firestore
    //     .collection('users')
    //     .add({'phone': phone, 'password': password})
    //     .then((docRef) {
    //       print('User added with ID: ${docRef.id}');
    //     })
    //     .catchError((error) {
    //       print('Error adding user: $error');
    //     });

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
}
