import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class HomeScreen4 extends ConsumerWidget {
  final AppUser user;
  const HomeScreen4({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider. Riverpod handles loading/error states for you.
    final inboxAsync = ref.watch(inboxProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Home 4 Chats (${user.phone} ${user.id})"),
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
      floatingActionButton: _buildSearchButton(context),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PhoneSearchBottomSheet(),
      ),
      child: const Icon(Icons.search),
    );
  }
}
