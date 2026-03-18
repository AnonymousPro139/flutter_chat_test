import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/widgets/Dialog.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    final passwordController = TextEditingController();

    void _registerHandler() {
      final phone = phoneController.text;
      final name = nameController.text;
      final password = passwordController.text;

      Auth().register(phone, name, password).then((success) {
        if (success) {
          context.showCustomSnackBar("Registration successful! Please log in");
          Navigator.pop(context); // Go back to login screen
        } else {
          context.showCustomSnackBar(
            "Registration failed. Please try again.",
            isError: true,
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: "Name"),
            controller: nameController,
          ),
          TextField(
            decoration: InputDecoration(labelText: "Phone"),
            controller: phoneController,
          ),
          TextField(
            decoration: InputDecoration(labelText: "Password"),
            controller: passwordController,
            obscureText: true,
          ),
          ElevatedButton(onPressed: _registerHandler, child: Text("Register")),
        ],
      ),
    );
  }
}
