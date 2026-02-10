import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';

class MessageListeners extends FirestoreService {
  Stream<QuerySnapshot<Map<String, dynamic>>> listeningInbox({
    required String myid,
  }) {
    return firestore
        .collection("/users/$myid/chatRefs")
        .orderBy('updatedAt', descending: false)
        .snapshots();

    // .startAfter([DateTime.now()]);

    // final subscription = collectionRef.snapshots().listen(
    //   onData,
    //   onError: (e) {
    //     print('Firestore listener error: $e');
    //   },
    // );

    // return subscription;
  }
}
