import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:test_firebase/firestore/utils.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void writeData(String collection, String docId, Map<String, dynamic> data) {
    _firestore
        .collection(collection)
        .doc(docId)
        .collection('messages')
        .add(data);
  }

  void writeData2(String collection, String docId, Map<String, dynamic> data) {
    // _firestore.collection(collection).doc(docId).set(data);
    _firestore.collection(collection).add(data);
  }

  void writeMessage(String cId, Map<String, dynamic> data) {
    _firestore.collection("channels").doc(cId).collection('messages').add(data);
  }

  void readData(String collection, String docId) async {
    DocumentSnapshot snapshot = await _firestore
        .collection(collection)
        .doc(docId)
        .get();

    print("READ DATA::: ${snapshot.data()}");

    // final messagesRef = FirebaseFirestore.instance
    //     .collection('chats')
    //     .doc(chatId)
    //     .collection('messages')
    //     .withConverter<Message>(
    //       fromFirestore: (snap, _) => Message.fromDoc(snap),
    //       toFirestore: (msg, _) => msg.toMap(),
    //     );
  }

  Stream listenChannels(
    String cId,
    String userId,
    String lastMessageTimestamp,
    InMemoryChatController _chatController,
  ) {
    return FirebaseFirestore.instance
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

          _chatController.setMessages(messages);
        });
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenToCollection({
    required String path,
    required void Function(QuerySnapshot<Map<String, dynamic>> snapshot) onData,
  }) {
    final collectionRef = FirebaseFirestore.instance
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
