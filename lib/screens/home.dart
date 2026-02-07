import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/chat.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _addDataToFirestore() {
    MessageFunctions().writeMessage("123", {
      "message": "Hello from home.dart",
      "createdAt": DateTime.now().toIso8601String(),
      "senderId": "user_123",
    });
  }

  void _getDataFromFirestore() {
    MessageFunctions().readData("channels", "1");
  }

  void _navigateToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(user: widget.user)),
    );
  }

  void _logout() {
    ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Home (${widget.user.phone}) - (${widget.user.id})"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You have pushed the button this many times:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: _navigateToChatScreen,
              child: const Text("Chat Screen"),
            ),
            TextButton(
              onPressed: _addDataToFirestore,
              child: const Text("Add Data"),
            ),
            TextButton(
              onPressed: _getDataFromFirestore,
              child: const Text("Get Data"),
            ),
            TextButton(onPressed: _logout, child: const Text("Logout")),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('channels')
                    .doc("123")
                    .collection('messages')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data();
                      final senderId = msg['senderId'] ?? 'Unknown';
                      final message = msg['message'] ?? '';

                      return ListTile(
                        title: Text(senderId.toString()),
                        subtitle: Text(message.toString()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
