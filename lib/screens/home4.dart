import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/group/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/providers.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class HomeScreen4 extends ConsumerWidget {
  final AppUser user;

  HomeScreen4({super.key, required this.user});
  final groupNameController = TextEditingController();
  // --- Modal Function ---
  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the modal to resize when keyboard appears
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom, // Lifts modal above keyboard
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create group chat",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  labelText: "Group Name",
                  prefixIcon: const Icon(Icons.group_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    var createdId = await createGroupChat(
                      groupNameController.text,
                      user.id,
                    );

                    print("New created group id: ${createdId}");

                    Navigator.pop(context);
                  },
                  child: const Text("Create Group"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    user.phone,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: () => _showCreateGroupModal(context),
                    constraints:
                        const BoxConstraints(), // Removes default padding
                    padding: EdgeInsets.zero,
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
                title: data["title"],
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
