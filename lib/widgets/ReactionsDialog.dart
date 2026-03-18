import 'package:flutter/material.dart';

Future<String?> showReactionsDialog(
  BuildContext context, {
  List<String> availableEmojis = const ['❤️', '👍', '😂', '😢', '🙏'],
}) {
  return showModalBottomSheet<String>(
    context: context,
    // useSafeArea ensures the sheet isn't blocked by system navigation bars
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext bottomSheetContext) {
      // Delegating to a standalone widget improves performance
      return _ReactionsBottomSheet(emojis: availableEmojis);
    },
  );
}

class _ReactionsBottomSheet extends StatelessWidget {
  final List<String> emojis;

  const _ReactionsBottomSheet({required this.emojis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add a reaction',
            // It's best practice to use the app's theme rather than hardcoding styles
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing:
                8, // Reduced slightly to account for the new InkWell padding
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: emojis.map((emoji) {
              return Tooltip(
                message: 'React with $emoji',
                child: InkWell(
                  // Pass the emoji back and close the sheet
                  onTap: () => Navigator.pop(context, emoji),
                  // Creates a nice circular ripple effect
                  borderRadius: BorderRadius.circular(100),
                  child: Padding(
                    // Expands the touch target to meet Material guidelines (>= 48px)
                    padding: const EdgeInsets.all(12.0),
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
