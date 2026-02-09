import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/Chat.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.db,
    required this.chatId,
    required this.otherUid,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.user,
  });

  final AppUser user;
  final FirebaseFirestore db;
  final String chatId;
  final String otherUid;
  final String lastMessage;
  final dynamic lastMessageTime; // Timestamp? (Firestore)

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (otherUid.isEmpty) {
      // fallback (group chat or broken data)
      return ListTile(
        title: const Text('Unknown user'),
        subtitle: Text(lastMessage),
        trailing: Text(_formatTime(lastMessageTime)),
      );
    }

    final userRef = db.collection('users').doc(otherUid);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: userRef.get(),
      builder: (context, snapshot) {
        final user = snapshot.data?.data();
        final name = (user?['name'] ?? 'User') as String;
        final photoUrl = (user?['photoUrl'] ?? '') as String;

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(name.isNotEmpty ? name[0] : '?')
                : null,
          ),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            lastMessage.isEmpty ? 'No messages yet' : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _formatTime(lastMessageTime),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) =>
            //         ChatRoomScreen(chatId: chatId, otherUid: otherUid),

            //   ),
            // );

            if (user != null) {
              final appUser = AppUser.fromMap(user);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chatId,
                    otherUid: otherUid,
                    user: appUser,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

extension on AsyncValue<AppUser?> {
  get user => null;
}

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUid,
  });

  final String chatId;
  final String otherUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(child: Text('Chat ID: $chatId\nOther UID: $otherUid')),
    );
  }
}
