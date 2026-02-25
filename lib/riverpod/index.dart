import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';
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

      return FirestoreService().firestore
          .collection('users')
          .doc(userId)
          .collection('chatRefs')
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });

// Define the Riverpod StreamProvider for the messages
final chatMessagesProvider = StreamProvider.family<List<types.Message>, String>(
  (ref, chatId) {
    return MessageHandlers().listeningChat(chatId: chatId).map((snapshot) {
      // Firebase handles the diffs; we just map the current reality.
      return snapshot.docs
          .map((doc) => MessageUtils().mapDocToMessage2(doc))
          .toList();
    });
  },
);
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(AuthController.new);
