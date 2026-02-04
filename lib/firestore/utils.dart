import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

types.Message firestoreToTextMessage(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();

  final createdAt = data['createdAt'] is String
      ? DateTime.parse(data['createdAt'])
      : (data['createdAt'] as Timestamp).toDate();

  return types.TextMessage(
    id: doc.id,
    authorId: data['senderId'],
    text: data['message'],
    createdAt: createdAt,
    replyToMessageId: data['replyToMessageId'],
    status: types.MessageStatus.sent,
  );
}

types.Message firestoreToTextMessage2(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();

  final createdAt = data?['createdAt'] is String
      ? DateTime.parse(data?['createdAt'])
      : (data?['createdAt'] as Timestamp).toDate();

  return types.TextMessage(
    id: doc.id,
    authorId: data?['senderId'] ?? "",
    text: data?['message'],
    createdAt: createdAt,
    replyToMessageId: data?['replyToMessageId'],
    status: types.MessageStatus.sent,
  );
}
