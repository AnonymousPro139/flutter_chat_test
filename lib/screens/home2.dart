import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/widgets/chat_tile.dart';
import 'package:test_firebase/firestore/services/index.dart';

class HomeScreen2 extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen2({super.key, required this.user});

  @override
  ConsumerState<HomeScreen2> createState() => _HomeScreenState2();
}

class _HomeScreenState2 extends ConsumerState<HomeScreen2> {
  final _chatController = InMemoryChatController();
  late final QuerySnapshot<Map<String, dynamic>> initialInboxFuture;

  Query<Map<String, dynamic>> _inboxQuery(String uid) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .limit(50);
  }

  Query<Map<String, dynamic>> _inboxQueryMust(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatRefs')
        .orderBy('createdAt', descending: true)
        .limit(50);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchInitialInbox(String uid) {
    Future<QuerySnapshot<Map<String, dynamic>>> data = _inboxQuery(uid).get();

    print(" fetchInitialInbox called for uid: $uid, future: $data");

    return data;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listeningInbox({
    required String myId,
  }) {
    return _inboxQuery(myId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("HOME 2 (${widget.user.phone}) - (${widget.user.id})"),
      ),

      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: fetchInitialInbox(widget.user.id),
        builder: (context, initialSnap) {
          if (initialSnap.hasError) {
            return Center(child: Text('Error: ${initialSnap.error}'));
          }
          if (initialSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            initialData: initialSnap.data,
            stream: listeningInbox(myId: widget.user.id),
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

                  // final lastMessage = (chat['lastMessage'] ?? '') as String;

                  final lastMessageTime = chat['lastMessageTime'];

                  return ChatTile(
                    db: FirestoreService().firestore,
                    chatId: chatDoc.id,
                    otherUid: otherUid,
                    lastMessage: chat['lastMessage']?['text'] ?? '',
                    lastMessageTime: lastMessageTime,
                    user: widget.user,
                  );
                },
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
