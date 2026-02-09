import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firestore/services/message/listeners.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/widgets/chat_tile.dart';
import 'package:test_firebase/firestore/services/index.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _chatController = InMemoryChatController();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  void startListening() {
    _subscription = MessageListeners().listenToCollection(
      path: 'chats',
      myid: widget.user.id,
      onData: (snapshot) {
        final messages = snapshot.docs.map(firestoreToTextMessage).toList();

        print('msgs: $messages');

        _chatController.setMessages(messages);

        // Process only changes (incremental updates)
        for (var change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              print('New message: ${change.doc.data()}');
              break;
            case DocumentChangeType.modified:
              print('Modified message: ${change.doc.data()}');
              break;
            case DocumentChangeType.removed:
              print('Removed message: ${change.doc.id}');
              break;
          }
        }
      },
    );
  }

  void _logout() {
    ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Chats (${widget.user.phone}) - (${widget.user.id})"),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: MessageFunctions().userChatsStream(widget.user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chatDoc = docs[index];
              final chat = chatDoc.data();

              final participants = List<String>.from(
                chat['participants'] ?? [],
              );
              final otherUid = participants.firstWhere(
                (id) => id != widget.user.id,
                orElse: () => '',
              );

              final lastMessage = (chat['lastMessage'] ?? '') as String;
              final lastMessageTime = chat['lastMessageTime'];

              return ChatTile(
                db: FirestoreService().firestore,
                chatId: chatDoc.id,
                otherUid: otherUid,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                user: widget.user,
              );
            },
          );
        },
      ),
    );
  }
}
