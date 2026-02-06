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
}
