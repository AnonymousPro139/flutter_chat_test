import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/models/user.dart';

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    // initial state: not logged in
    return const AsyncValue.data(null);
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // await Future.delayed(const Duration(milliseconds: 600));

      final user = await Auth().login(phone, password);

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      } else {
        // failure
      }
    });
  }

  Future<void> checkLogin() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await Auth().userChecker();

      final test = user?['id'];
      print('USERRR: ${user} ${test}');

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      } else {
        return AppUser(id: "1234", phone: "MOCKUSER");
      }
    });
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final inboxProvider =
    StreamProvider.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      String
    >((ref, userId) {
      // Use your existing handler, but ensure it returns a Stream with .orderBy()
      // Sorting at the database level is much faster than sorting in Dart.
      // return FirestoreService().firestore
      //     .collection('chats') // or whatever your collection is
      //     .where('participants', arrayContains: userId)
      //     .orderBy(
      //       'lastMessageAt',
      //       descending: true,
      //     ) // Database handles sorting
      //     .snapshots()
      //     .map((snapshot) => snapshot.docs);

      // return MessageHandlers()
      //     .listeningInbox(myId: userId)
      //     .map((snapshot) => snapshot.docs);

      return FirestoreService().firestore
          .collection('users')
          .doc(userId)
          .collection('chatRefs')
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(AuthController.new);
