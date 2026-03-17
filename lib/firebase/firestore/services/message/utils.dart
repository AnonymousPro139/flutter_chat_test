import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_firebase/crypto/chacha.dart';
import 'package:test_firebase/crypto/utils.dart';
import 'package:test_firebase/firebase/storage/index.dart';
import 'package:test_firebase/localstorage/index.dart';

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

  // Message mapDocToMessage2(
  //   DocumentSnapshot<Map<String, dynamic>> doc,
  //   String receivingKey,
  // ) {
  //   try {
  //     final data = doc.data();

  //     final createdAt = data?['createdAt'] is Timestamp
  //         ? (data?['createdAt'] as Timestamp).toDate()
  //         : (data?['createdAt'] is String
  //               ? DateTime.parse(data?['createdAt']).toUtc()
  //               : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

  //     // var decrypted = '';

  //     // ChaCha20().decrypt(data?['text'], receivingKey).then((res) {
  //     //   decrypted = res;
  //     // });

  //     var decrypted =  await ChaCha20().decrypt(data?['text'], receivingKey);

  //     if (data?['type'] == 'text') {
  //       return TextMessage(
  //         id: doc.id,
  //         authorId: data?['senderId'],
  //         createdAt: createdAt,
  //         // text: data?['text'],
  //         text: decrypted,
  //         replyToMessageId: data?['replyToMessageId'],
  //         status: MessageStatus.sent,
  //       );
  //     } else {
  //       if (data?['type'] == 'image') {
  //         return ImageMessage(
  //           id: doc.id,
  //           authorId: data?['senderId'],
  //           createdAt: createdAt,
  //           source: data?['uri'] ?? '',
  //           status: MessageStatus.sent,
  //         );
  //       } else {
  //         if (data?['type'] == 'file') {
  //           return FileMessage(
  //             id: doc.id,
  //             authorId: data?['senderId'],
  //             createdAt: createdAt,
  //             name: data?['uri'],
  //             size: data?['size'] ?? 0,
  //             source: data?['uri'] ?? '',
  //             status: MessageStatus.sent,
  //           );
  //         } else {
  //           if (data?['type'] == 'system') {
  //             return SystemMessage(
  //               id: doc.id,
  //               authorId: data?['senderId'],
  //               createdAt: createdAt,
  //               text: data?['text'] ?? '',
  //               status: MessageStatus.sent,
  //             );
  //           } else {
  //             return TextMessage(
  //               id: doc.id,
  //               authorId: data?['senderId'],
  //               createdAt: createdAt,
  //               text: decrypted, // data?['text'],
  //               replyToMessageId: data?['replyToMessageId'],
  //               status: MessageStatus.sent,
  //             );
  //           }
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('++ Error in mapDocToMessage2: ${e}');

  //     return TextMessage(
  //       id: doc.id,
  //       authorId: "123",
  //       createdAt: null,
  //       text: 'Erorr shuu',
  //       status: MessageStatus.sent,
  //     );
  //   }
  // }

  Message mapDocToMessage2(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String receivingKey,
  ) {
    try {
      final data = doc.data();

      final createdAt = data?['createdAt'] is Timestamp
          ? (data?['createdAt'] as Timestamp).toDate()
          : (data?['createdAt'] is String
                ? DateTime.parse(data?['createdAt']).toUtc()
                : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

      var decrypted = ChaCha20().decrypt(
        data?['text'],
        receivingKey,
      ); // await is not works in this function

      if (data?['type'] == 'text') {
        return TextMessage(
          id: doc.id,
          authorId: data?['senderId'],
          createdAt: createdAt,
          text: data?['text'],
          replyToMessageId: data?['replyToMessageId'],
          status: MessageStatus.sent,
        );
      } else {
        if (data?['type'] == 'image') {
          return ImageMessage(
            id: doc.id,
            authorId: data?['senderId'],
            createdAt: createdAt,
            source: data?['uri'] ?? '',
            status: MessageStatus.sent,
          );
        } else {
          if (data?['type'] == 'file') {
            return FileMessage(
              id: doc.id,
              authorId: data?['senderId'],
              createdAt: createdAt,
              name: data?['uri'],
              size: data?['size'] ?? 0,
              source: data?['uri'] ?? '',
              status: MessageStatus.sent,
            );
          } else {
            if (data?['type'] == 'system') {
              return SystemMessage(
                id: doc.id,
                authorId: data?['senderId'],
                createdAt: createdAt,
                text: data?['text'] ?? '',
                status: MessageStatus.sent,
              );
            } else {
              return TextMessage(
                id: doc.id,
                authorId: data?['senderId'],
                createdAt: createdAt,
                text: data?['text'],
                replyToMessageId: data?['replyToMessageId'],
                status: MessageStatus.sent,
              );
            }
          }
        }
      }
    } catch (e) {
      print('++ Error in mapDocToMessage2: ${e}');

      return TextMessage(
        id: doc.id,
        authorId: "123",
        createdAt: null,
        text: 'Erorr shuu',
        status: MessageStatus.sent,
      );
    }
  }

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

      switch (type) {
        case 'image':
          final fpath = await fetchFileDecryptAndCreateTempFile(
            chatId: chatId,
            fileUrl: data["name"],
            ssk: ssk,
            uniqueId: doc.id,
          );

          return ImageMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            text: "Hii brooo",
            // source: data['uri'] ?? '',
            source: fpath,
            // pinned: true,
            status: MessageStatus.sent,
          );

        case 'file':
          return FileMessage(
            id: doc.id,
            authorId: data['senderId'],
            createdAt: createdAt,
            name: data['uri'] ?? 'file',
            size: data['size'] ?? 0,
            source: data['uri'] ?? '',
            status: MessageStatus.sent,
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
          // 2. Safely Decrypt ONLY if text exists
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

  Message mapDocToMessage3(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final String id = doc.id;
    final String authorId = data['senderId']?.toString() ?? '';
    final String type = data['type']?.toString() ?? 'text';

    // 1. Clean Timestamp Parsing
    DateTime createdAt;
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      createdAt = rawDate.toDate();
    } else if (rawDate is String) {
      createdAt = DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.now();
    } else {
      createdAt =
          DateTime.now(); // Fallback to now instead of epoch 0 for better UX
    }

    // 2. Clear Type Switching
    switch (type) {
      case 'image':
        return ImageMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          size: (data['size'] as num?)?.toInt() ?? 0,
          source: data['uri']?.toString() ?? '',
          status: MessageStatus.sent,
        );

      case 'file':
        return FileMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          name: data['name']?.toString() ?? 'File',
          size: (data['size'] as num?)?.toInt() ?? 0,
          // Using 'uri' or 'source' based on your Firestore key
          source: (data['uri'] ?? data['source'] ?? '').toString(),
          status: MessageStatus.sent,
        );

      case 'system':
        return SystemMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          text: data['text']?.toString() ?? '',
          status: MessageStatus.sent,
        );

      case 'text':
      default:
        return TextMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          text: data['text']?.toString() ?? '',
          replyToMessageId: data['replyToMessageId'],
          status: MessageStatus.sent,
        );
    }
  }

  Message mapDocToMessage4(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // 1. Extract common fields safely
    final String id = doc.id;
    final String authorId = (data['senderId'] ?? '').toString();
    final String type = (data['type'] ?? 'text').toString();
    final MessageStatus status = MessageStatus.sent;

    // 2. Robust Timestamp Handling
    DateTime createdAt;
    try {
      final rawDate = data['createdAt'];
      if (rawDate is Timestamp) {
        createdAt = rawDate.toDate();
      } else if (rawDate is String) {
        createdAt = DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }
    } catch (_) {
      createdAt = DateTime.now();
    }

    print('CREATEDAT: ${createdAt}');

    // 3. Extension-based override (Ensures images vs files are correct)
    final String fileName = (data['name'] ?? data['text'] ?? '').toString();
    final String finalType = _determineFinalType(type, fileName);

    // 4. Clean Switch Statement
    switch (finalType) {
      case 'image':
        return ImageMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          source: (data['uri'] ?? data['text'] ?? '').toString(),
          status: status,
        );

      case 'file':
        return FileMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          name: fileName.isEmpty ? 'Untitled File' : fileName,
          size: (data['size'] as num?)?.toInt() ?? 0,
          source: (data['uri'] ?? '').toString(),
          status: status,
        );

      case 'system':
        return SystemMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          text: (data['text'] ?? '').toString(),
          status: status,
        );

      case 'text':
      default:
        return TextMessage(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          text: (data['text'] ?? '').toString(),
          replyToMessageId: data['replyToMessageId']?.toString(),
          status: status,
        );
    }
  }

  /// Helper to ensure extensions like .jpg are treated as images
  /// even if the database label is generic.
  String _determineFinalType(String dbType, String fileName) {
    if (dbType == 'text' || dbType == 'system') return dbType;

    const imgExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    final ext = fileName.split('.').last.toLowerCase();

    if (imgExts.contains(ext)) return 'image';
    return 'file';
  }
}
