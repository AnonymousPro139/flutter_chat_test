import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';

Future<String> createGroupChat(String title, createdUserId) async {
  // .doc() with no path generates a unique ID automatically
  final docRef = FirestoreService().firestore.collection('chats').doc();

  await docRef.set({
    'id': docRef.id, // This is your automatic ID
    'title': title,
    'participants': [createdUserId],
    'admins': [createdUserId],
    'type': 'group',
    'createdAt': FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

/// Adds one or more users to an existing group chat
Future<void> addUsersToGroup({
  required String chatId,
  required List<String> newUserIds,
}) async {
  final chatRef = FirestoreService().firestore.collection('chats').doc(chatId);

  try {
    // arrayUnion takes a list of elements to add.
    // If an ID is already in the array, Firestore ignores it (no duplicates).
    await chatRef.update({
      'participants': FieldValue.arrayUnion(newUserIds),
      // Optional: Update the 'updatedAt' timestamp so the group moves to the top
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print("Successfully added users to the group!");
  } catch (e) {
    print("Error adding users to group: $e");
    // Handle the error (e.g., show a SnackBar to the user)
    rethrow;
  }
}
