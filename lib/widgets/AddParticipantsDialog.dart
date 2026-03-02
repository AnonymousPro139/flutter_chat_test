import 'package:flutter/material.dart';
import 'package:test_firebase/firestore/services/user/index.dart';
import 'package:test_firebase/models/user.dart';

class AddParticipantsDialog extends StatefulWidget {
  final String chatId;
  final List<AppUser> allFriends;

  final List<AppUser> currentParticipants;

  const AddParticipantsDialog({
    super.key,
    required this.chatId,
    required this.allFriends,
    required this.currentParticipants,
  });

  @override
  State<AddParticipantsDialog> createState() => _AddParticipantsDialogState();
}

class _AddParticipantsDialogState extends State<AddParticipantsDialog> {
  final List<String> _selectedUserIds = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isSearchingGlobal = false;
  List<AppUser> _globalResults = [];

  // This function looks for users in the entire 'public_profiles' collection
  Future<void> _searchGlobalUser(String phone) async {
    if (phone.isEmpty || phone.length < 5) return;

    setState(() => _isSearchingGlobal = true);

    try {
      // final query = await FirebaseFirestore.instance
      //     .collection('public_profiles')
      //     .where('phone', isEqualTo: phone)
      //     .get();

      // final foundUsers = query.docs.map((doc) {
      //   final data = doc.data();
      //   return AppUser(
      //     id: doc.id,
      //     phone: data['phone'] ?? '',
      //     // displayName: data['displayName'] ?? 'User',
      //     // photoUrl: data['photoUrl'] ?? '',
      //   );
      // }).toList();

      final foundUsers = [
        await UserFirestoreService().searchUserByPhone(phone),
      ].whereType<AppUser>().toList();

      setState(() {
        _globalResults = foundUsers;
        _isSearchingGlobal = false;
      });
    } catch (e) {
      setState(() => _isSearchingGlobal = false);
      debugPrint("Global search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter local friends based on search text
    final searchTerm = _searchController.text.toLowerCase();
    final localFiltered = widget.allFriends.where((f) {
      final isNotMember = !widget.currentParticipants.any((p) => p.id == f.id);
      final matchesSearch =
          f.phone.contains(searchTerm) ||
          (f.phone.toLowerCase().contains(searchTerm));
      return isNotMember && matchesSearch;
    }).toList();

    // 2. Combine with global results (avoiding duplicates)
    final combinedResults = {...localFiltered, ..._globalResults}.toList();

    return AlertDialog(
      title: const Text("Add participants"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Increased height for search bar
        child: Column(
          children: [
            // SEARCH BAR
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search phone number...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.language), // Global search button
                  onPressed: () => _searchGlobalUser(_searchController.text),
                  tooltip: "Search Globally",
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() {}), // Refresh local filter
            ),
            const SizedBox(height: 10),

            if (_isSearchingGlobal) const LinearProgressIndicator(),

            // USER LIST
            Expanded(
              child: combinedResults.isEmpty
                  ? const Center(child: Text("No users found."))
                  : ListView.builder(
                      itemCount: combinedResults.length,
                      itemBuilder: (context, index) {
                        final user = combinedResults[index];
                        final isAlreadyMember = widget.currentParticipants
                            .contains(user.id);
                        final isSelected = _selectedUserIds.contains(user.id);

                        return CheckboxListTile(
                          title: Text(user.phone),
                          subtitle: Text(
                            user.id,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          secondary: CircleAvatar(
                            backgroundImage: null,
                            child: Icon(Icons.person),
                          ),
                          value: isSelected,
                          onChanged: isAlreadyMember
                              ? null // Disable if already in group
                              : (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedUserIds.add(user.id);
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _selectedUserIds.isEmpty
              ? null
              : () async {
                  await UserFirestoreService().addParticipantsToChat(
                    chatId: widget.chatId,
                    selectedUserIds: _selectedUserIds,
                  );
                  Navigator.pop(context, _selectedUserIds);
                },
          child: Text("Add (${_selectedUserIds.length})"),
        ),
      ],
    );
  }
}
