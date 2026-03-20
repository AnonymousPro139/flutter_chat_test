import 'package:flutter/material.dart';

Future<String?> showReactionsAndActionsDialog(
  BuildContext context, {
  bool isShowUnsend = true,
  List<String> availableEmojis = const ['❤️', '👍', '😂', '😢', '🙏'],
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext bottomSheetContext) {
      return _ReactionsBottomSheet(
        emojis: availableEmojis,
        isShowUnsend: isShowUnsend,
      );
    },
  );
}

class _ReactionsBottomSheet extends StatelessWidget {
  final List<String> emojis;
  final bool isShowUnsend;

  const _ReactionsBottomSheet({
    required this.emojis,
    required this.isShowUnsend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding around the entire bottom sheet content
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add a reaction',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // EMOJI WRAP
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: emojis.map((emoji) {
              return Tooltip(
                message: 'React with $emoji',
                child: InkWell(
                  onTap: () => Navigator.pop(context, emoji),
                  borderRadius: BorderRadius.circular(100),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            children: [
              // 1. Reply Button (Standard Outline)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'action_reply'),
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text(
                    'Reply',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              if (isShowUnsend) const SizedBox(width: 16),

              if (isShowUnsend)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, 'action_delete'),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Unsend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      // Adds a very subtle red tint to the background
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
