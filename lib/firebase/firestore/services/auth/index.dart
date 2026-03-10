import 'dart:async'; // Required for Completer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_firebase/firebase/index.dart';

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

    if (doc.exists) {
      // User already has a profile, go to Home
      return {'id': user.uid, 'phone': user.phoneNumber};
    } else {
      // New user, go to "Complete Profile" screen to get their name

      await createNewUser(user);

      return {'id': user.uid, 'phone': user.phoneNumber};
    }
  }

  Future<void> createNewUser(User firebaseUser) async {
    final batch = firestore.batch();

    // 1. Private Doc
    final privateRef = firestore.collection('users').doc(firebaseUser.uid);

    batch.set(privateRef, {
      'uid': firebaseUser.uid,
      'phone': firebaseUser.phoneNumber, // Automatically comes from Auth
      'displayName': firebaseUser.displayName,
      'createdAt': FieldValue.serverTimestamp(), // Better than using phone time
      'role': 'user',
      'photoUrl': firebaseUser.photoURL,
    });

    // 2. Public Doc
    final publicRef = firestore
        .collection('public_profiles')
        .doc(firebaseUser.uid);

    batch.set(publicRef, {
      'uid': firebaseUser.uid,
      'displayName': firebaseUser.displayName,
      'phone': firebaseUser.phoneNumber,
      'photoUrl': firebaseUser.photoURL,
    });

    await batch.commit();
  }

  Future<void> createNewUserKeys(
    String uid,
    String idPubKey,
    String spPubKey,
    String epPubKey,
  ) async {
    final batch = firestore.batch();

    final privateRef = firestore.collection('users').doc(uid);

    batch.set(privateRef, {
      'idPubKey': idPubKey,
      'spPubKey': spPubKey,
      'epPubKey': epPubKey,
      'keysCreatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final publicRef = firestore.collection('public_profiles').doc(uid);

    batch.set(publicRef, {
      'idPubKey': idPubKey,
      'spPubKey': spPubKey,
      'epPubKey': epPubKey,
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
