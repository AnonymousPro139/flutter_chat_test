import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/chat.dart';

class ChatElement extends StatelessWidget {
  const ChatElement({
    super.key,
    required this.db,
    required this.chatId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.user,
  });

  final AppUser user;
  final FirebaseFirestore db;
  final String chatId;
  final String lastMessage;
  final dynamic lastMessageAt; // Timestamp? (Firestore)

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
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: null,
        child: chatId.isNotEmpty ? Text(chatId[0].toUpperCase()) : null,
      ),
      title: Text(chatId, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        lastMessage.isEmpty ? 'No messages yet' : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(lastMessageAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(user: user, chatId: chatId),
          ),
        );
      },
    );
  }
}
