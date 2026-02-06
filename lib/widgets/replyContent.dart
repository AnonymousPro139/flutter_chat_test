import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

class ReplyContent extends StatelessWidget {
  final types.TextMessage message;

  const ReplyContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final author = message.authorId == '123' ? 'You' : 'Other'; // replace logic

    String previewText = '';

    previewText = message.text;

    // if (message is types.TextMessage) {
    //   previewText = message.text;
    // } else if (message is types.ImageMessage) {
    //   previewText = '📷 Photo';
    // } else if (message is types.FileMessage) {
    //   previewText = '📎 ${message.name}';
    // } else {
    //   previewText = 'Message';
    // }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          author,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          previewText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
