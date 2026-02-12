import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';

class MessageFunctions extends FirestoreService {
  Future<String> createOrGetChat(
    String uid1,
    String uid2, {
    String type = "dm",
    String title = '',
  }) async {
    final chatId = chatIdForUsers(uid1, uid2);

    final chatRef = firestore.collection('chats').doc(chatId);

    await chatRef.set({
      'type': type,
      'title': title,
      'participants': [uid1, uid2],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  String chatIdForUsers(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final chatRef = firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc(); // auto id

    final now = FieldValue.serverTimestamp();

    final batch = firestore.batch();

    batch.set(msgRef, {'senderId': senderId, 'text': text, 'createdAt': now});

    // Eniig cloud function-r oorchluulj bga
    // End uurchluh, cloud function-r oorchluuleh 2n dawuu sul tal ?

    // batch.set(chatRef, {
    //   'lastMessage': text,
    //   'lastMessageTime': now,
    // }, SetOptions(merge: true));

    await batch.commit();
  }

  void sendMessage2({
    required String chatId,
    required String senderId,
    required String text,
    type = 'text',
  }) async {
    firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
    });
  }
}
