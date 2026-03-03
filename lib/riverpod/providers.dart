import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:test_firebase/firebase/index.dart';
import 'package:test_firebase/firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/firebase/firestore/services/message/utils.dart';
import 'package:test_firebase/models/user.dart';

final inboxProvider =
    StreamProvider.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      String
    >((ref, userId) {
      // Use your existing handler, but ensure it returns a Stream with .orderBy()
      // Sorting at the database level is much faster than sorting in Dart.

      return FirestoreService().firestore
          .collection('users')
          .doc(userId)
          .collection('chatRefs')
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });

// Define the Riverpod StreamProvider for the messages
final chatMessagesProvider = StreamProvider.family<List<types.Message>, String>(
  (ref, chatId) {
    return MessageHandlers().listeningChat(chatId: chatId).map((snapshot) {
      // Firebase handles the diffs; we just map the current reality.
      return snapshot.docs
          .map((doc) => MessageUtils().mapDocToMessage2(doc))
          .toList();
    });
  },
);

final friendsProvider = StreamProvider.family<List<AppUser>, String>((
  ref,
  userId,
) {
  return FirestoreService().firestore
      .collection('users')
      .doc(userId)
      .collection('contacts')
      .orderBy('lastInteractionAt', descending: true) // Most recent first
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          return AppUser(id: doc.id, phone: data['phone'] ?? 'User');
        }).toList(),
      );
});

final chatParticipantsProvider = StreamProvider.family<List<String>, String>((
  ref,
  chatId,
) {
  return FirestoreService().firestore
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        return List<String>.from(data?['participants'] ?? []);
      });
});

final participantProfilesProvider =
    FutureProvider.family<List<AppUser>, String>((ref, chatId) async {
      // 1. Get the list of IDs from the first provider
      final ids = await ref.watch(chatParticipantsProvider(chatId).future);

      if (ids.isEmpty) return [];

      // 2. Fetch all profiles from 'public_profiles' where ID is in the list
      // Note: Firestore 'whereIn' is limited to 30 IDs
      final query = await FirebaseFirestore.instance
          .collection('public_profiles')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      return query.docs
          .map(
            (doc) => AppUser(id: doc.id, phone: doc.data()['phone'] ?? 'User'),
          )
          .toList();
    });

// resolve user-t ashiglah, odoogoor ashiglaagui!
final chatProfilesProvider =
    FutureProvider.family<Map<String, types.User>, String>((ref, chatId) async {
      final participantIds = await ref.watch(
        chatParticipantsProvider(chatId).future,
      );

      if (participantIds.isEmpty) return {};

      // Fetch all profiles in one go (limited to 30 for whereIn)
      final query = await FirestoreService().firestore
          .collection('public_profiles')
          .where(FieldPath.documentId, whereIn: participantIds)
          .get();

      // Convert your DB data into a Map of Flyer Chat User objects
      final Map<String, types.User> userMap = {};
      for (var doc in query.docs) {
        final data = doc.data();
        userMap[doc.id] = types.User(
          id: doc.id,
          name: data['phone'],

          // firstName: data['displayName'] ?? 'Unknown',
          // imageUrl: data['photoUrl'],
        );
      }
      return userMap;
    });

// This will keep track of which tab is active globally
final bottomNavIndexProvider = StateProvider<int>(
  (ref) => 0,
); // chat leave hiih ued butsaj home-ruu shiljihed aldaa garaad bsn uchir
