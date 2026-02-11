import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/widgets/ChatElement.dart';
import 'package:test_firebase/firestore/services/index.dart';

class HomeScreen2 extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen2({super.key, required this.user});

  @override
  ConsumerState<HomeScreen2> createState() => _HomeScreenState2();
}

class _HomeScreenState2 extends ConsumerState<HomeScreen2> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _inboxStream;

  Query<Map<String, dynamic>> _inboxQueryMust(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatRefs')
        .orderBy('lastMessageAt', descending: true)
        .limit(50);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchInitialInbox(String uid) {
    Future<QuerySnapshot<Map<String, dynamic>>> data = _inboxQueryMust(
      uid,
    ).get();

    return data;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listeningInbox({
    required String myId,
  }) {
    return _inboxQueryMust(myId).snapshots();
  }

  // avoid to recreate stream on every build, create it once in initState and use the variable in StreamBuilder
  @override
  void initState() {
    super.initState();
    _inboxStream = listeningInbox(myId: widget.user.id);
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
            // stream: listeningInbox(myId: widget.user.id),
            stream: _inboxStream,
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

                  // final participants = List<String>.from(
                  //   chat['participants'] ?? [],
                  // );
                  // final otherUid = participants.firstWhere(
                  //   (id) => id != widget.user.id,
                  //   orElse: () => '',
                  // );

                  // final lastMessage = (chat['lastMessage'] ?? '') as String;

                  final lastMessageAt = chat['lastMessageAt'];

                  // return ChatTile(
                  //   db: FirestoreService().firestore,
                  //   chatId: chatDoc.id,
                  //   otherUid: '', // shaardlagatai eseh
                  //   lastMessage: chat['lastMessageText'] ?? 'no last msg bby',
                  //   lastMessageAt: lastMessageAt,
                  //   user: widget.user,
                  // );

                  return ChatElement(
                    db: FirestoreService().firestore,
                    chatId: chatDoc.id,
                    lastMessage: chat['lastMessageText'] ?? 'no last msg bby',
                    lastMessageAt: lastMessageAt,
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
