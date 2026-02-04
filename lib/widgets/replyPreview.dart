import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

import 'package:test_firebase/widgets/replyContent.dart';

class ReplyPreview extends StatelessWidget {
  final types.TextMessage message;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.authorId == '123'; // replace logic
    final color = isMe ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor,
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Row(
        children: [
          Expanded(child: ReplyContent(message: message)),
          IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }
}
