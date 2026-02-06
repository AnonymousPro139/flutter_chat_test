import 'package:flutter/material.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    // Implement your login logic here
    final phone = _phoneController.text;
    final password = _passwordController.text;

    // For example, you can call an API to authenticate the user
    print("Logging in with phone: $phone and password: $password");

    Auth().login(phone, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Screen12")),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: "Phone"),
            controller: _phoneController,
          ),
          TextField(
            decoration: InputDecoration(labelText: "Password"),
            controller: _passwordController,
            obscureText: true,
          ),
          ElevatedButton(onPressed: _login, child: Text("Login")),
        ],
      ),
    );
  }
}
