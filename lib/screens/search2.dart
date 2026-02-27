import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firestore/services/user/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/chat3.dart';
import 'package:test_firebase/widgets/ChatElement.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  AppUser? resultUser;
  List<Contact> _allContacts = []; // Original list from phone
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    // 1. Request Permission
    final status = await Permission.contacts.request();

    if (status.isGranted) {
      // 2. Fetch contacts with high-res thumbnails and phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      // Handle denied permission (e.g., show a dialog)
    }
  }

  void _searchContacts(String query) {
    final results = _allContacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredContacts = results;
    });
  }

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

  void search() async {
    setState(() => _isSearching = true);

    final result = await UserFirestoreService().searchUserByPhone(
      _searchController.text,
    );

    setState(() {
      resultUser = result;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loggedUser = authState.value;

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
              //onChanged: _searchContacts,
              // onChanged: _performSearch,
              onTap: search,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      // _searchContacts('');
                      // _performSearch('');
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
                : resultUser?.phone == null
                ? _buildEmptyState()
                : _buildResultUser(context, loggedUser, resultUser),
          ),
          // Expanded(
          //   child: _isLoading
          //       ? const Center(child: CircularProgressIndicator())
          //       : _filteredContacts.isEmpty
          //       ? const Center(child: Text("No contacts found"))
          //       : ListView.builder(
          //           itemCount: _filteredContacts.length,
          //           itemBuilder: (context, index) {
          //             final contact = _filteredContacts[index];
          //             // Safely get the first phone number
          //             String phone = contact.phones.isNotEmpty
          //                 ? contact.phones.first.number
          //                 : "No number";

          //             return ListTile(
          //               leading: (contact.photo != null)
          //                   ? CircleAvatar(
          //                       backgroundImage: MemoryImage(contact.photo!),
          //                     )
          //                   : CircleAvatar(child: Text(contact.displayName[0])),
          //               title: Text(contact.displayName),
          //               subtitle: Text(phone),
          //               trailing: IconButton(
          //                 icon: const Icon(
          //                   Icons.person_add_alt_1,
          //                   color: Colors.deepPurple,
          //                 ),
          //                 onPressed: () {
          //                   // Logic to invite or add to chat
          //                 },
          //               ),
          //             );
          //           },
          //         ),
          // ),
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

  Widget _buildResultUser(context, loggedUser, resultUser) {
    var createdChatId = "";

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: null,
        child: Text(resultUser.phone.toUpperCase()),
      ),
      title: Text(
        resultUser.phone,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'id: ${resultUser.id}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      trailing: FilledButton(
        onPressed: () async {
          // Navigate to Chat

          createdChatId = await MessageFunctions().createOrGetChat(
            loggedUser!.id,
            resultUser!.id,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatScreen3(chatId: createdChatId, user: loggedUser),
            ),
          );
        },
        child: const Text("Message"),
      ),
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
