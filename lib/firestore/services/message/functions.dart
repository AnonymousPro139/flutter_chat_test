import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';

class MessageFunctions extends FirestoreService {
  void writeData(String collection, String docId, Map<String, dynamic> data) {
    firestore
        .collection(collection)
        .doc(docId)
        .collection('messages')
        .add(data);
  }

  void writeData2(String collection, String docId, Map<String, dynamic> data) {
    // _firestore.collection(collection).doc(docId).set(data);
    firestore.collection(collection).add(data);
  }

  void writeMessage(String cId, Map<String, dynamic> data) {
    firestore.collection("channels").doc(cId).collection('messages').add(data);
  }

  void writeMessage2(String cId, Map<String, dynamic> data) {
    // create a new message document with an auto-generated ID
    firestore.collection("channels").doc().collection('messages').add(data);
  }

  void writeMessage3(String cId, Map<String, dynamic> data) {
    // create a new message document with an auto-generated ID
    // firestore.collection("chats").doc().collection("").add(data).collection('messages').add(data);
  }

  void readData(String collection, String docId) async {
    DocumentSnapshot snapshot = await firestore
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

  void getChats(String uId) {
    firestore
        .collection("channels")
        .where('members', arrayContains: uId)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            print("CHAT::: ${doc.data()}");
          }
        });
  }

  Future<String> createOrGetChat(String uid1, String uid2) async {
    final chatId = chatIdForUsers(uid1, uid2);

    final chatRef = firestore.collection('chats').doc(chatId);

    await chatRef.set({
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

    batch.set(msgRef, {'senderId': senderId, 'text': text, 'timestamp': now});

    batch.set(chatRef, {
      'lastMessage': text,
      'lastMessageTime': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userChatsStream(String uid) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
