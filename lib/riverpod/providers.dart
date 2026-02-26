import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';

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
