import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/riverpod/index.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    void _login() {
      final phone = phoneController.text;
      final password = passwordController.text;

      ref
          .read(authControllerProvider.notifier)
          .login(phone: phone, password: password);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: "Phone"),
            controller: phoneController,
          ),
          TextField(
            decoration: InputDecoration(labelText: "Password"),
            controller: passwordController,
            obscureText: true,
          ),
          ElevatedButton(onPressed: _login, child: Text("Login")),
        ],
      ),
    );
  }
}
