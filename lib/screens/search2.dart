import 'package:flutter/material.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearching = false;

  // Mock function to simulate a database/Firebase search
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Dummy data for demonstration
    final mockUsers = [
      AppUser(id: '101', phone: '+123456'),
      AppUser(id: '102', phone: '+987654'),
      AppUser(id: '103', phone: '+555444'),
    ];

    setState(() {
      _searchResults = mockUsers
          .where((u) => u.phone.contains(query.toLowerCase()))
          .toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Find People",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Modern Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: "Search by phone",
              onChanged: _performSearch,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  ),
              ],
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),
          ),

          // 2. Results Area
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                user.phone,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.phone,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.phone),
                const SizedBox(height: 4),
                // Reusing your custom ID badge style
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "ID: ${user.id}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: FilledButton(
              onPressed: () {
                // Navigate to Chat

                //  createdChatId = await MessageFunctions().createOrGetChat(
                //       loggedUser!.id,
                //       resultUser!.id,
                //     ),

                //     // navigate to chat screen with this chat ID
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => ChatScreen2(
                //           chatId: createdChatId,
                //           user: loggedUser,
                //         ),
                //       ),
                //     ),
              },
              child: const Text("Message"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "Search for users globally"
                : "No user found!",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
