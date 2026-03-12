import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/crypto/chacha.dart';
import 'package:test_firebase/crypto/index.dart';
import 'package:test_firebase/firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/otp.dart';
import 'package:test_firebase/screens/register.dart';

class LoginScreen2 extends ConsumerStatefulWidget {
  const LoginScreen2({super.key});

  @override
  ConsumerState<LoginScreen2> createState() => _LoginScreen2State();
}

class _LoginScreen2State extends ConsumerState<LoginScreen2> {
  // Define the controller here so it persists across rebuilds
  late TextEditingController phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: '+97688731627');
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    setState(() => _isLoading = true);
    try {
      // Calling your Auth service
      String returnedId = await Auth().sendOtp(phoneController.text);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phoneNumber: phoneController.text,
            verificationId: returnedId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Login"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.chat, size: 70, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              "Urtuu",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your phone number to continue",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send OTP", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),

            TextButton(
              onPressed: () async {
                KeyPair mykeypair = await EncryptionService()
                    .reconstructKeyPair(key: "identity_pri_key");
                KeyPair myEphKeypair = await EncryptionService()
                    .reconstructKeyPair(key: "eph_pri_key");
                KeyPair mySpreKeypair = await EncryptionService()
                    .reconstructKeyPair(key: "signed_pre_pri_key");

                SecretKey ssk = await EncryptionService().createSharedSecretKey(
                  myKeyPair: mykeypair,
                  otherPublicKey: EncryptionService().base64ToPublicKey(
                    "i5CsUGJ9NwIahfl+7ZFO8eHtOdHh7TvTef+/vFzV4Eg=",
                  ),
                );

                final test = await EncryptionService().calcMasterKey(
                  ownIdPriKey: mykeypair,
                  ownEphPriKey: myEphKeypair,

                  otherIdPubKey: EncryptionService().base64ToPublicKey(
                    "nOoI1uGLqABC+KvOeg8+P2GC4g5P98zVU+zpSBGB73M=",
                  ),
                  otherSPpubKey: EncryptionService().base64ToPublicKey(
                    "kdS3LAj1UWwApow7QySGRgSi/Kxq47w278usWt5LBGc=",
                  ),
                );

                final receivingTest = await EncryptionService()
                    .calcReceivingMasterKey(
                      ownIdPriKey: mykeypair,
                      ownSPPriKey: mySpreKeypair,
                      otherIdPubKey: EncryptionService().base64ToPublicKey(
                        "nOoI1uGLqABC+KvOeg8+P2GC4g5P98zVU+zpSBGB73M=",
                      ),
                      otherEphPubKey: EncryptionService().base64ToPublicKey(
                        "8g7oJysU5EtsiEaHDFLswYyV5v2LDx1ViACWz7nzHCU=",
                      ),
                    );

                print("mykeypair:: ${await mykeypair.extractPublicKey()}");

                print("SSK:: ${await ssk.extractBytes()}");
                print(
                  "SSK HEX:: ${await EncryptionService().secretKeyToHex(ssk)}",
                );

                print("CALCULATED SSK:: ${test}");
                print("RECEVING SSK:: ${receivingTest}");

                final decrypted = await ChaCha20().decrypt(
                  '{"cipher":"ZQE=","iv":"ZpDNfIJY7dadb/Z0","mac":"UJ0ncmxZOumlv5amjFnpmw=="}',
                  'c092d5ff8d6e4a82793a429b47f22e1c225324ff6414321b9348d1b73f6cd87d51e462ce785ea049f2676dd03f8678ac4dc046a297553a8546943a4b222d5705bf9ddba843375fb42e0f7c92b482b7b921aacf3f464f5748f82580cb5bc10d11',
                );

                print("decrypted: ${decrypted}");
                // ChaCha20().secretBoxFromJson("{"cipher":"8A==","iv":"OMBNrkTDdhfpAOOs","mac":"cY3idtaqWuc5l8MFVdhfPg=="}");

                // SecretKeyData hkdf = await EncryptionService().derivedKey(ssk);
                // print("derivedKey:: ${await hkdf.extractBytes()}");

                // ChaCha20().encrypt("Hello world!", mykeypair);
              },
              child: const Text("Encrypt test"),
            ),
          ],
        ),
      ),
    );
  }
}
