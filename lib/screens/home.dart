import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/widgets/chat_tile.dart';
import 'package:test_firebase/firestore/services/index.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Chats (${widget.user.phone}) - (${widget.user.id})"),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            null, //  MessageListeners().listeningInbox(myid: widget.user.id),

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

              print("chat data: $chat");

              final participants = List<String>.from(
                chat['participants'] ?? [],
              );
              final otherUid = participants.firstWhere(
                (id) => id != widget.user.id,
                orElse: () => '',
              );

              final lastMessageAt = chat['lastMessageAt'];

              return ChatTile(
                db: FirestoreService().firestore,
                chatId: chatDoc.id,
                otherUid: otherUid,
                lastMessage: chat['lastMessage']?['text'] ?? '',
                lastMessageAt: lastMessageAt,
                user: widget.user,
              );
            },
          );
        },
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PhoneSearchBottomSheet(),
          ),
          child: Icon(Icons.search),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
