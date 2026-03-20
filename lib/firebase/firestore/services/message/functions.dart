import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/localstorage/index.dart';
import 'package:test_firebase/models/user.dart';

class MessageFunctions extends FirestoreService {
  // Future<String> createOrGetChat(
  //   String myId,
  //   String uid2, {
  //   String type = "dm",
  //   String title = '',
  // }) async {
  //   final chatId = genereteChatIdForUsers(myId, uid2);

  //   final chatRef = firestore.collection('chats').doc(chatId);

  //   final docSnapshot = await chatRef.get();

  //   if (!docSnapshot.exists) {
  //     // Document doesn't exist, so we CREATE it with the timestamp
  //     await chatRef.set({
  //       'type': type,
  //       'isDM': true,
  //       'title': title,
  //       'participants': [myId, uid2],
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });
  //   }

  //   return chatId;
  // }

  Future<String> createOrGetChat(
    String myId,
    String uid2, {
    String type = "dm",
    String title = '',
  }) async {
    final chatId = genereteChatIdForUsers(myId, uid2);
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      // 1. Try to read the chat.
      // If it already exists AND you are in it, this succeeds silently.
      await chatRef.get();
    } on FirebaseException catch (e) {
      // 2. If it throws a permission denied error, it means the document
      // either doesn't exist, OR you aren't allowed in it.
      if (e.code == 'permission-denied') {
        try {
          // 3. Attempt to CREATE the document.
          // Your rule: `allow create: if request.auth.uid in request.resource.data.participants`
          // allows this to succeed perfectly if the document is truly missing!
          await chatRef.set({
            'type': type,
            'isDM': true,
            'title': title,
            'participants': [myId, uid2],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e2) {
          // 4. If this STILL fails, it means the chat already exists,
          // but you are maliciously trying to overwrite someone else's private chat.
          // Your `update` rule will block it securely.
          print('Security block: Cannot overwrite existing private chat.');
        }
      } else {
        // Re-throw if it's a completely different error (like no internet connection)
        rethrow;
      }
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
          LocalStorageService().isImage(
            LocalStorageService().getExtension(filename),
          )
          ? 'image'
          : "file",
    });
  }
}
