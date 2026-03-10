import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/const.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:path/path.dart' as p;

class MessageFunctions extends FirestoreService {
  Future<String> createOrGetChat(
    String myId,
    String uid2, {
    String type = "dm",
    String title = '',
  }) async {
    final chatId = genereteChatIdForUsers(myId, uid2);

    final chatRef = firestore.collection('chats').doc(chatId);

    final docSnapshot = await chatRef.get();

    if (!docSnapshot.exists) {
      // Document doesn't exist, so we CREATE it with the timestamp
      await chatRef.set({
        'type': type,
        'title': title,
        'participants': [myId, uid2],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  String genereteChatIdForUsers(String uid1, String uid2) {
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

  void sendFileMessage({
    required String chatId,
    required AppUser sender,
    required String uri,
    required String filename,
    required int size,
    type = 'file',
  }) async {
    firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': sender.id,
      'senderPhone': sender.phone,
      'senderDisplayName': 'TestdisplayName',
      'uri': uri,
      'name': filename,
      'size': size,
      'createdAt': FieldValue.serverTimestamp(),
      'type':
          imageExtensions.contains(p.extension(filename).replaceFirst('.', ''))
          ? 'image'
          : "file",
    });
  }
}
