import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/crypto/utils.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/MediaViewerScreen.dart';

class ChatGalleryScreen2 extends StatelessWidget {
  final AppUser me;
  final String chatId;

  final ({String sending, String receiving}) sessionKeys;

  const ChatGalleryScreen2({
    super.key,
    required this.me,
    required this.chatId,
    required this.sessionKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Media files")),
      body: StreamBuilder<QuerySnapshot>(
        // Query only messages that have an 'image' or 'file' type
        stream: FirestoreService().firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('type', whereIn: ['image', 'file'])
            .orderBy('createdAt', descending: false)
            .limit(15)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs; // beofre

          if (docs.isEmpty) return const Center(child: Text("No media found"));

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final isImage = data['type'] == 'image';

              Future<String>? decryptionFuture = null;

              if (data['text'] != 'Deleted') {
                decryptionFuture = fetchFileDecryptAndCreateTempFile2(
                  chatId: chatId,
                  senderId: data["senderId"],
                  fileUrl: data["name"],
                  ssk: data["senderId"] == me.id
                      ? sessionKeys.sending
                      : sessionKeys.receiving,
                  uniqueId: docs[index].id,
                );
              }

              return FutureBuilder<String>(
                future: decryptionFuture,
                builder: (context, fileSnapshot) {
                  // State A: Still decrypting/downloading
                  if (fileSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  // State B: Something went wrong during decryption
                  if (fileSnapshot.hasError) {
                    return Container(
                      color: Colors.red[100],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.red),
                      ),
                    );
                  }

                  // State C: Success! We have the decrypted file path.
                  final decryptedFilePath = fileSnapshot.data!;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaViewerScreen(
                          // NOTE: You probably want to pass the decryptedFilePath here
                          // instead of the original encrypted data['uri']!
                          uri: decryptedFilePath,
                          isImage: isImage,
                          fileName: data['name'] ?? 'Untitled',
                          isCache: true,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isImage
                          ? Image.file(File(decryptedFilePath))
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.description,
                                color: Colors.blue,
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
