import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/models/user.dart';

class UserFirestoreService extends FirestoreService {
  Future<AppUser?> searchUserByPhone(String phone) async {
    final snapshot = await firestore
        .collection('public_profiles')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data();
      return AppUser(id: snapshot.docs.first.id, phone: user['phone']);
    } else {
      // does NOT exist
      return null;
    }
  }

  Future<void> hideChatForMe(String myid, String chatId) async {
    await firestore
        .collection('users')
        .doc(myid)
        .collection('chatRefs')
        .doc(chatId)
        .delete();
  }

  Future<void> addParticipantsToChat({
    required String chatId,
    required List<String> selectedUserIds,
  }) async {
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      // arrayUnion adds elements to an array only if they are not already present.
      await chatRef.update({
        'participants': FieldValue.arrayUnion(selectedUserIds),
        'updatedAt': FieldValue.serverTimestamp(), // Move chat to to
      });

      print("Added ${selectedUserIds.length} users to chat $chatId");
    } catch (e) {
      print("Failed to add participants: $e");
      rethrow;
    }
  }

  Future<List<String>> getParticipantIds(String chatId) async {
    final doc = await firestore.collection('chats').doc(chatId).get();

    // Cast the dynamic list to a List<String>
    return List<String>.from(doc.data()?['participants'] ?? []);
  }
}
