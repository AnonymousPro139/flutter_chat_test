import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/crypto/utils.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/MediaViewerScreen.dart';

class ChatGalleryScreen extends StatelessWidget {
  final AppUser me;
  final String chatId;

  final ({String sending, String receiving}) sessionKeys;

  const ChatGalleryScreen({
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
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

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

              // end decrypt file hiine!
              // if (data["senderId"] == me.id) {
              //   // decrypt

              //   final fpath = await fetchFileDecryptAndCreateTempFile(
              //     chatId: chatId,
              //     fileUrl: data["name"],
              //     ssk: sessionKeys.sending,
              //     uniqueId: docs[index].id,
              //   );
              // } else {
              //   // decrypt

              //     final fpath = await fetchFileDecryptAndCreateTempFile(
              //     chatId: chatId,
              //     fileUrl: data["name"],
              //     ssk: sessionKeys.receiving,
              //     uniqueId: docs[index].id,
              //   );
              // }

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaViewerScreen(
                      uri: data['uri'],
                      isImage: isImage,
                      fileName: data['name'] ?? 'Untitled',
                      isCache: true,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isImage
                      ? Image.network(data['uri'], fit: BoxFit.cover)
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
      ),
    );
  }
}
