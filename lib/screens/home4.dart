import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/providers.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class HomeScreen4 extends ConsumerWidget {
  final AppUser user;
  const HomeScreen4({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        // centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ), // Your Padding
              decoration: BoxDecoration(
                // color: Theme.of(
                //   context,
                // ).colorScheme.inversePrimary, // Your Background Color
                // borderRadius: BorderRadius.circular(12), // Your Rounded Corners
              ),
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(
                    "Urtuu",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "${user.phone}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0.2),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return ChatElement(
                chatId: doc.id,
                user: user,
                lastMessage: data['lastMessageText'] ?? '',
                lastMessageAt: data['lastMessageAt'],
              );
            },
          );
        },
      ),
    );
  }
}
