import 'package:flutter/material.dart';
import 'package:test_firebase/models/user.dart';

class ShowParticipantsDialog extends StatefulWidget {
  final String chatId;
  final List<AppUser> currentParticipants;

  const ShowParticipantsDialog({
    super.key,
    required this.chatId,
    required this.currentParticipants,
  });

  @override
  State<ShowParticipantsDialog> createState() => _ShowParticipantsDialogState();
}

class _ShowParticipantsDialogState extends State<ShowParticipantsDialog> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filter participants based on search query (name or phone)
    final filteredList = widget.currentParticipants.where((user) {
      final name = user.phone.toLowerCase();
      final phone = user.phone.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Text("Participants"),
          const Spacer(),
          Text(
            "${widget.currentParticipants.length}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            // SEARCH BAR
            TextField(
              decoration: InputDecoration(
                hintText: "Search participants...",
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 12),

            // USER LIST
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text("No members found matching that search."),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final user = filteredList[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: null,
                            child: null,
                          ),
                          title: Text(
                            user.phone,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            user.phone,
                            style: const TextStyle(fontSize: 12),
                          ),
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
          child: const Text("Close"),
        ),
      ],
    );
  }
}
