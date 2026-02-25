import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/otp.dart';
import 'package:test_firebase/screens/register.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController(text: '+97688731627');
    // final passwordController = TextEditingController(text: "123");

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: "Phone"),
            controller: phoneController,
          ),
          // TextField(
          //   decoration: InputDecoration(labelText: "Password"),
          //   controller: passwordController,
          //   obscureText: true,
          // ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            },
            child: Text("Go to Register"),
          ),

          ElevatedButton(
            onPressed: () async {
              String returnedId = await Auth().sendOtp(phoneController.text);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpScreen(
                    phoneNumber: phoneController.text,
                    verificationId: returnedId,
                  ),
                ),
              );
            },
            child: Text("send OTP"),
          ),
        ],
      ),
    );
  }
}
