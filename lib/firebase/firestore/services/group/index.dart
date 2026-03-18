import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/crypto/utils.dart';
import 'package:test_firebase/firebase/index.dart';

Future<String> createGroupChat(String title, createdUserId) async {
  try {
    // .doc() with no path generates a unique ID automatically
    final docRef = FirestoreService().firestore.collection('chats').doc();

    final idKey = await createSha256Hash("groupchat");
    final spreKey = await createSha256Hash("test");
    final ephKey = await createSha256Hash("test123");

    await docRef.set({
      'id': docRef.id, // This is your automatic ID
      'title': title,
      'idPubKey': idKey,
      'spPubKey': spreKey,
      'epPubKey': ephKey,
      'participants': [createdUserId],
      'admins': [createdUserId],
      'type': 'group',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  } catch (err) {
    print("error creating group: ${err}");
    return '';
  }
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

Future<void> leaveGroup(String chatId, String userId) async {
  final db = FirestoreService().firestore;
  final batch = db.batch();

  // 1. Remove user from the main chat participants list
  final chatRef = db.collection('chats').doc(chatId);
  batch.update(chatRef, {
    'participants': FieldValue.arrayRemove([userId]),
  });

  // 2. Delete the chat reference from the user's personal inbox
  final userChatRef = db
      .collection('users')
      .doc(userId)
      .collection('chatRefs')
      .doc(chatId);

  batch.delete(userChatRef);

  // 3. Execute both at once
  await batch.commit();
}
