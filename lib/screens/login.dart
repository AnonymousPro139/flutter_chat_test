import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/register.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController(text: '99889988');
    final passwordController = TextEditingController(text: "123");

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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            },
            child: Text("Go to Register"),
          ),
        ],
      ),
    );
  }
}
