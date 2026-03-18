import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:test_firebase/crypto/chacha.dart';
import 'package:test_firebase/crypto/utils.dart';
import 'package:test_firebase/localstorage/index.dart';

class MessageUtils {
  Future<Message> mapDocToMessage5(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String ssk,
    String chatId,
  ) async {
    try {
      final data =
          doc.data() ?? {}; // Default to empty map to avoid null errors

      final createdAt = data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String
                ? DateTime.parse(data['createdAt']).toUtc()
                : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

      // 3. Clean routing using a Switch statement instead of nested if/else
      final type = data['type'] ?? 'text';

      Map<String, List<String>>? parsedReactions = reactionHandler(
        data['reactions'],
      );

      switch (type) {
        case 'image':
          final fpath = await fetchFileDecryptAndCreateTempFile2(
            chatId: chatId,
            senderId: data['senderId'],
            fileUrl: data["name"],
            ssk: ssk,
            uniqueId: doc.id,
          );

          return ImageMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            source: fpath,
            status: MessageStatus.sent,
            reactions: parsedReactions,
          );

        case 'file':
          return FileMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            name: LocalStorageService().cutSubStringLast(data['name']),
            size: data['size'] ?? 0,
            source: data['uri'] ?? '',
            status: MessageStatus.sent,
            reactions: parsedReactions,
          );
        case 'system':
          return SystemMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            text: data['text'] ?? '',
            status: MessageStatus.sent,
          );
        case 'text':
          String decryptedText = '';
          if (data['text'] != null && data['text'].toString().isNotEmpty) {
            // Now await works perfectly!
            decryptedText = await ChaCha20().decrypt(data['text'], ssk);
          }

          return TextMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            text: decryptedText, // Use the awaited decrypted text here!
            replyToMessageId: data['replyToMessageId'],
            status: MessageStatus.sent,
            reactions: parsedReactions,
          );
        default:
          return TextMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            text: "Unknown! shuu", // Use the awaited decrypted text here!
            replyToMessageId: data['replyToMessageId'],
            status: MessageStatus.sent,
          );
      }
    } catch (e) {
      print('++ Error in mapDocToMessage2: $e');

      return TextMessage(
        id: doc.id,
        authorId: "error_user",
        createdAt: null,
        text: 'Error decrypting message',
        status: MessageStatus.error,
      );
    }
  }

  Map<String, List<String>> reactionHandler(dynamic rawReactions) {
    if (rawReactions == null) {
      return {};
    }

    Map<String, List<String>>? parsedReactions = {};

    if (rawReactions is Map) {
      // Scenario A: It's the NEW, correct Map format! Let's parse it safely.
      // parsedReactions = {};
      rawReactions.forEach((key, value) {
        if (value is List) {
          // Force every item in the list to be a String
          parsedReactions![key.toString()] = List<String>.from(
            value.map((e) => e.toString()),
          );
        }
      });

      return parsedReactions;
    } else if (rawReactions is List) {
      // Scenario B: It's the OLD data from our previous attempts.
      // We just return an empty map so the app doesn't crash on old messages.
      return parsedReactions;
    } else {
      return {};
    }
  }
}
