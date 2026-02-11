import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration successful! Please log in.")),
          );
          Navigator.pop(context); // Go back to login screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration failed. Please try again.")),
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
