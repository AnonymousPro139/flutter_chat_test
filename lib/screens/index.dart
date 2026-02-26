import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/bottom.dart';
import 'package:test_firebase/screens/home3.dart';
import 'package:test_firebase/screens/home4.dart';
import 'package:test_firebase/screens/login.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Heyyyy! Error: $e"))),
      data: (user) {
        if (user == null) return const LoginScreen();

        // return HomeScreen4(user: user);
        return BottomScreen();
      },
    );
  }
}
