import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/firebase/firestore/services/user/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/screens/chat5.dart';

class ChatElement extends StatelessWidget {
  const ChatElement({
    super.key,
    required this.chatId,
    required this.title,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.user,

    required this.idPubKey,
    required this.epPubKey,
    required this.spPubKey,
  });

  final AppUser user;
  final String chatId;
  final String title;
  final String lastMessage;
  final dynamic lastMessageAt;

  final String idPubKey;
  final String epPubKey;
  final String spPubKey;

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

  void _showOptionsModal(
    BuildContext context,
    String chatId,
    String chatTitle,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  chatTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Hide Chat",
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  "This will remove the chat from your list.",
                ),
                onTap: () async {
                  Navigator.pop(context); // Close modal
                  await _confirmAndHideChat(context, chatId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndHideChat(BuildContext context, String chatId) async {
    try {
      // 1. Delete only the local user's reference
      await UserFirestoreService().hideChatForMe(user.id, chatId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat hidden successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error hiding chat: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: null,
        child: title.isNotEmpty ? Text(title.toUpperCase()) : null,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            builder: (_) => ChatScreen5(
              user: user,
              title: title,
              chatId: chatId,
              idPubKey: idPubKey,
              epPubKey: epPubKey,
              spPubKey: spPubKey,
            ),
          ),
        );
      },
      onLongPress: () => _showOptionsModal(context, chatId, title),
    );
  }
}
