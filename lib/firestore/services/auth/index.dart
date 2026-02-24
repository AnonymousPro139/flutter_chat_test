import 'dart:async'; // Required for Completer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/firestore/services/index.dart';

class Auth extends FirestoreService {
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    final query = await firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // exists
      return {'id': query.docs.first.id, 'phone': phone};
    } else {
      // does NOT exist
      return {'id': null, 'phone': null};
    }
  }

  Future<bool> register(String phone, String name, String password) async {
    final query = await firestore.collection('users').add({
      'phone': phone,
      'name': name,
      'password': password,
    });

    if (query.id.isNotEmpty) {
      // exists
      print("Registered user with id: ${query.id}");
      return true;
    } else {
      // does NOT exist
      return false;
    }
  }

  String _verificationId = "";

  String get getVerificationId {
    return _verificationId;
  }

  Future<void> sendOtp1(String phoneNumber) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      // Use international format: +976XXXXXXXX
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print("verificationCompleted ");
        // ANDROID ONLY: Auto-retrieval of SMS code
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification Failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        print("codeSent: ${verificationId}");

        // Navigate user to the OTP input screen
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("codeAutoRetrievalTimeout: ${verificationId}");
        _verificationId = verificationId;
      },
    );
  }

  Future<String> sendOtp(String phoneNumber) async {
    // 1. Create a Completer that expects a String
    Completer<String> completer = Completer<String>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print("verificationCompleted");
        // ANDROID ONLY: Auto-retrieval of SMS code
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification Failed: ${e.message}");
        // 2. If it fails, throw an error so your UI doesn't hang forever
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        print("codeSent: $verificationId");
        // 3. When the code is successfully sent, complete the Future with the ID!
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("codeAutoRetrievalTimeout: $verificationId");
        // Fallback in case timeout happens before codeSent (rare, but safe)
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    // 4. Return the Future. The code calling sendOtp() will wait here
    // until completer.complete() is called above.
    return completer.future;
  }

  Future<void> verifyCode(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: smsCode,
    );

    // Sign the user in
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    // Now you have their UID for your Firestore rules!
    print("Logged in user UID: ${userCredential.user?.uid}");
  }

  Future<Map<String, dynamic>?> userChecker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'id': null, 'phone': null};

    final doc = await firestore.collection('users').doc(user.uid).get();

    print("mydoccc: ${doc} ${doc.exists}");

    if (doc.exists) {
      // User already has a profile, go to Home
      return {'id': user.uid, 'phone': user.phoneNumber};
    } else {
      // New user, go to "Complete Profile" screen to get their name

      await createUserProfile("Laachkaa");

      return {'id': user.uid, 'phone': user.phoneNumber};
    }
  }

  Future<void> createUserProfile(String name) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 1. Reference the 'users' collection and specifically the document named with the UID
      final userRef = firestore.collection('users').doc(user.uid);

      // 2. Use .set() to create or update the document
      await userRef.set(
        {
          'uid': user.uid,
          'phone': user.phoneNumber, // Automatically comes from Auth
          'displayName': name,
          'createdAt':
              FieldValue.serverTimestamp(), // Better than using phone time
          'role': 'user',
        },
        SetOptions(merge: true),
      ); // Use merge: true to avoid overwriting existing data if they log in again

      print("User document created/updated for UID: ${user.uid}");
    }
  }
}
