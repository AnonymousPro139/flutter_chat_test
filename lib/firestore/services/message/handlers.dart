import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';

class MessageHandlers extends FirestoreService {
  Query<Map<String, dynamic>> inboxQuery({required String myid}) {
    return firestore
        .collection('users')
        .doc(myid)
        .collection('chatRefs')
        .orderBy('lastMessageAt', descending: true)
        .limit(20);
  }

  Query<Map<String, dynamic>> fetchMessagesChatQuery({required String chatId}) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limitToLast(20);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchMessagesChat({
    required String chatId,
  }) {
    return fetchMessagesChatQuery(chatId: chatId).get();
  }

// unused
  Future<QuerySnapshot<Map<String, dynamic>>> fetchInitialInbox({
    required String myid,
  }) {
    return inboxQuery(myid: myid).get();
  }

// unused
  Stream<QuerySnapshot<Map<String, dynamic>>> listeningInbox({
    required String myId,
  }) {
    return inboxQuery(myid: myId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listeningChat({
    required String chatId,
  }) {
    return fetchMessagesChatQuery(chatId: chatId).snapshots();
  }
}
