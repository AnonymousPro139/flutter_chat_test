import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/models/user.dart';

class MessageFunctions extends FirestoreService {
  Future<String> createOrGetChat(
    String myId,
    String uid2, {
    String type = "dm",
    String title = '',
  }) async {
    final chatId = genereateChatIdForUsers(myId, uid2);

    final chatRef = firestore.collection('chats').doc(chatId);

    await chatRef.set({
      'type': type,
      'title': title,
      'participants': [myId, uid2],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  String genereateChatIdForUsers(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void sendMessage({
    required String chatId,
    required AppUser sender,
    required String text,
    type = 'text',
  }) async {
    firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': sender.id,
      'senderPhone': sender.phone,
      'senderDisplayName': 'TestdisplayName',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
    });
  }
}
