import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart'; // Recommended for 6-digit OTP UI
import 'package:test_firebase/crypto/index.dart';
import 'package:test_firebase/firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/firebase/firestore/services/user/index.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/widgets/Dialog.dart';

class SyncCodeScreen extends ConsumerStatefulWidget {
  final AppUser loggedUser;

  const SyncCodeScreen({super.key, required this.loggedUser});

  @override
  ConsumerState<SyncCodeScreen> createState() => _SyncCodeScreenState();
}

class _SyncCodeScreenState extends ConsumerState<SyncCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;

  var initUserData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  void _init() async {
    final data = await UserFirestoreService().getMyPublicKeys(
      myId: widget.loggedUser.id,
    );

    print('dataaa: ${data}');

    setState(() {
      initUserData = data;
    });
  }

  void _verifyCode(String pin) async {
    // final inputHash = await createSha256Hash(pin);

    if (initUserData?['idPubKey'] == null ||
        initUserData?['spPubKey'] == null ||
        initUserData?['epPubKey'] == null) {
      setState(() => _isError = false);
      _createCode(pin);

      context.showCustomSnackBar(
        "Created sync code is successful. Don't forget it!",
      );
    } else {
      final idPubKey = await EncryptionService().createIdentityKeyPair(
        uid: widget.loggedUser.id,
        syncCode: pin,
      );

      final spPubKey = await EncryptionService().createSignedPreKeyPair(
        uid: widget.loggedUser.id,
        phone: widget.loggedUser.phone,
      );

      final epPubKey = await EncryptionService().createEphemeralKeyPair(
        phone: widget.loggedUser.phone,
      );

      if (initUserData?['idPubKey'] == idPubKey &&
          initUserData?['spPubKey'] == spPubKey &&
          initUserData?['epPubKey'] == epPubKey) {
        setState(() => _isError = false);
        ref
            .read(authControllerProvider.notifier)
            .successSyncCode(widget.loggedUser);
      } else {
        setState(() => _isError = true);
        _pinController.clear();

        context.showCustomSnackBar(
          "Invalid Sync Code. Please try again.",
          isError: true,
        );
      }
    }
  }

  void _createCode(String pin) async {
    try {
      final idPubKey = await EncryptionService().createIdentityKeyPair(
        uid: widget.loggedUser.id,
        syncCode: pin,
      );

      final spPubKey = await EncryptionService().createSignedPreKeyPair(
        uid: widget.loggedUser.id,
        phone: widget.loggedUser.phone,
      );

      final epPubKey = await EncryptionService().createEphemeralKeyPair(
        phone: widget.loggedUser.phone,
      );

      await Auth().createNewUserKeys(
        widget.loggedUser.id,
        idPubKey,
        spPubKey,
        epPubKey,
      );

      ref
          .read(authControllerProvider.notifier)
          .successSyncCode(widget.loggedUser);
    } catch (error) {
      print('error in _createCode: ${error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "Sync Code Verification",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter your 6-digit Sync Code to restore your encrypted chat history.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Pinput widget for a professional 6-digit field
            Pinput(
              length: 6,
              controller: _pinController,
              obscureText: true,
              onCompleted: _verifyCode,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 60,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.blue.shade200,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                // Logic for "I forgot my code" (Warning: This usually means data loss in E2EE)
              },
              child: const Text("Forgot Sync Code?"),
            ),
          ],
        ),
      ),
    );
  }
}
