import 'package:flutter/material.dart';
import 'package:test_firebase/models/user.dart';

class AddMembersDialog extends StatefulWidget {
  final List<AppUser> allFriends; // All possible friends to add
  final List<String> currentParticipants; // To hide people already in the group

  const AddMembersDialog({
    super.key,
    required this.allFriends,
    required this.currentParticipants,
  });

  @override
  State<AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  final List<String> _selectedUserIds = [];

  @override
  Widget build(BuildContext context) {
    // Filter out friends who are already in this specific group
    final availableFriends = widget.allFriends
        .where((f) => !widget.currentParticipants.contains(f.id))
        .toList();

    return AlertDialog(
      title: const Text("Add Members"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: availableFriends.isEmpty
            ? const Center(child: Text("All friends are already added."))
            : ListView.builder(
                itemCount: availableFriends.length,
                itemBuilder: (context, index) {
                  final friend = availableFriends[index];
                  final isSelected = _selectedUserIds.contains(friend.id);

                  return CheckboxListTile(
                    title: Text(friend.phone),
                    secondary: CircleAvatar(child: Text(friend.phone[0])),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(friend.id);
                        } else {
                          _selectedUserIds.remove(friend.id);
                        }
                      });
                    },
                  );
                },
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
              : () => Navigator.pop(context, _selectedUserIds),
          child: Text("Add (${_selectedUserIds.length})"),
        ),
      ],
    );
  }
}
