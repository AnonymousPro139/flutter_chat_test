import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/models/user.dart';

// Your existing provider definition
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    // 1. Start listening to Firebase Auth the moment this controller is created
    final subscription = FirebaseAuth.instance.authStateChanges().listen((
      User? firebaseUser,
    ) {
      if (firebaseUser == null) {
        print('heyyy firebaseUser bol null bnshuu!!!!!!!');
        // If Firebase says we are logged out, instantly update the state to null.
        // Your AuthGate will automatically redirect to LoginScreen2!
        state = const AsyncData(null);
      } else {
        // If Firebase says we ARE logged in, fetch your custom AppUser data!
        checkLogin();
      }
    });

    // 2. Prevent memory leaks!
    // If this provider is ever destroyed, cancel the Firebase listener.
    ref.onDispose(() {
      subscription.cancel();
    });

    // 3. Return a loading state immediately while we wait for Firebase's first response
    return const AsyncLoading();
  }

  // Your existing checkLogin function (slightly tweaked to ensure it returns null if user isn't found)
  Future<void> checkLogin() async {
    // Optional: Only set to loading if we aren't already loading
    if (!state.isLoading) {
      state = const AsyncLoading();
    }

    state = await AsyncValue.guard(() async {
      final user = await Auth()
          .userChecker(); // Assuming this fetches your backend data

      if (user != null && user['id'] != null) {
        return AppUser(
          id: user['id'],
          phone: user['phone'],
          isVerifiedBySyncCode: false,
          epPubKey: '',
          idPubKey: '',
          spPubKey: '',
        );
      }

      return null; // Explicitly return null if the user object is invalid
    });
  }

  // Example of how easy logout becomes now:
  Future<void> logout() async {
    // Calling this will trigger the authStateChanges() listener above,
    // which automatically updates the state and boots the user to the login screen!
    await FirebaseAuth.instance.signOut();
  }

  Future<void> successSyncCode(AppUser loggedUser) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return AppUser(
        id: loggedUser.id,
        phone: loggedUser.phone,
        isVerifiedBySyncCode: true,
        epPubKey: '',
        idPubKey: '',
        spPubKey: '',
      );
    });
  }
}
