import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/message/functions.dart';
import 'package:test_firebase/firestore/services/user/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/chat.dart';
import 'package:test_firebase/screens/chat2.dart';

class PhoneSearchBottomSheet extends ConsumerStatefulWidget {
  const PhoneSearchBottomSheet({super.key});

  @override
  ConsumerState<PhoneSearchBottomSheet> createState() =>
      _PhoneSearchBottomSheetState();
}

class _PhoneSearchBottomSheetState
    extends ConsumerState<PhoneSearchBottomSheet> {
  AppUser? resultUser;
  final phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void search() async {
    final result = await UserFirestoreService().searchUserByPhone(
      phoneController.text,
    );

    print("RESULT ${result}");

    setState(() {
      resultUser = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    var createdChatId = "";
    final authState = ref.watch(authControllerProvider);
    final loggedUser = authState.value; // AppUser? (logged-in user)

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                "Search by Phone Number",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+976 99012345",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),

              if (resultUser == null && phoneController.text.isNotEmpty)
                Text(
                  "Not found",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),

              if (resultUser != null) const SizedBox(height: 30),
              if (resultUser != null)
                Text("Search Result:", style: TextStyle(fontSize: 18)),
              if (resultUser != null)
                ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage: null,
                    child: Text('?'),
                  ),
                  title: Text("Phone: ${resultUser!.phone}"),
                  subtitle: Text("User ID: ${resultUser!.id}"),
                  onTap: () async => {
                    createdChatId = await MessageFunctions().createOrGetChat(
                      loggedUser!.id,
                      resultUser!.id,
                    ),

                    print("Created chat ID: $createdChatId"),

                    // navigate to chat screen with this chat ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen2(
                          chatId: createdChatId,
                          user: loggedUser,
                        ),
                      ),
                    ),
                  },
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: search,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Search", style: TextStyle(fontSize: 16)),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Back", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
