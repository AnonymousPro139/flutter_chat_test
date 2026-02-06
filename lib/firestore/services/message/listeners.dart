import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';

class MessageListeners extends FirestoreService {
  Stream listenChannels(
    String cId,
    String userId,
    String lastMessageTimestamp,
    InMemoryChatController chatController,
  ) {
    return firestore
        .collection('channels')
        .doc("123")
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .startAfter([DateTime.now()])
        .snapshots()
        .map((snapshot) {
          // for (final change in snapshot.docChanges) {
          // final doc = change.doc;
          // Map Firestore doc -> types.Message (adjust to your mapper)
          // final msg = firestoreToTextMessage2(doc);

          // switch (change.type) {
          //   case DocumentChangeType.added:
          //     // _handleAdded(change.newIndex, msg);
          //     break;
          //   case DocumentChangeType.modified:
          //     // _handleModified(change.oldIndex, change.newIndex, msg);
          //     break;
          //   case DocumentChangeType.removed:
          //     // _handleRemoved(change.oldIndex, id);
          //     break;
          // }
          // }

          final messages = snapshot.docs.map(firestoreToTextMessage).toList();

          print('msgs: $messages');

          chatController.setMessages(messages);
        });
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenToCollection({
    required String path,
    required void Function(QuerySnapshot<Map<String, dynamic>> snapshot) onData,
  }) {
    final collectionRef = firestore
        .collection(path)
        .orderBy('createdAt', descending: false)
        .startAfter([DateTime.now()]);

    final subscription = collectionRef.snapshots().listen(
      onData,
      onError: (e) {
        print('Firestore listener error: $e');
      },
    );

    return subscription;
  }
}
