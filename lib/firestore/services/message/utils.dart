import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

class MessageUtils {
  // types.Message firestoreToTextMessage2(
  //   DocumentSnapshot<Map<String, dynamic>> doc,
  // ) {
  //   final data = doc.data();

  //   final createdAt = data?['createdAt'] is String
  //       ? DateTime.parse(data?['createdAt'])
  //       : (data?['createdAt'] as Timestamp).toDate();

  //   return types.TextMessage(
  //     id: doc.id,
  //     authorId: data?['senderId'] ?? "",
  //     text: data?['message'],
  //     createdAt: createdAt,
  //     replyToMessageId: data?['replyToMessageId'],
  //     status: types.MessageStatus.sent,
  //   );
  // }

  Message mapDocToMessage(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : (data['createdAt'] is String
              ? DateTime.parse(data['createdAt']).toUtc()
              : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

    if (data['type'] == 'file') {
      return ImageMessage(
        id: doc.id,
        authorId: (data['senderId'] ?? '').toString(),
        createdAt: createdAt,
        source: (data['text'] ?? '').toString(),
        status: MessageStatus.sent,
      );
    } else {
      return TextMessage(
        id: doc.id,
        authorId: (data['senderId'] ?? '').toString(),
        createdAt: createdAt,
        text: (data['text'] ?? '').toString(),
        replyToMessageId: data['replyToMessageId'],
        status: MessageStatus.sent,
      );
    }
  }

  Message mapDocToMessage2(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final createdAt = data?['createdAt'] is Timestamp
        ? (data?['createdAt'] as Timestamp).toDate()
        : (data?['createdAt'] is String
              ? DateTime.parse(data?['createdAt']).toUtc()
              : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

    if (data?['type'] == 'file') {
      return ImageMessage(
        id: doc.id,
        authorId: (data?['senderId'] ?? '').toString(),
        createdAt: createdAt,
        source: (data?['text'] ?? '').toString(),
        status: MessageStatus.sent,
      );
    } else {
      return TextMessage(
        id: doc.id,
        authorId: (data?['senderId'] ?? '').toString(),
        createdAt: createdAt,
        text: (data?['text'] ?? '').toString(),
        replyToMessageId: data?['replyToMessageId'],
        status: MessageStatus.sent,
      );
    }
  }
}
