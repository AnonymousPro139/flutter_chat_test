import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/SyncCode.dart';
import 'package:test_firebase/screens/bottom.dart';
import 'package:test_firebase/screens/login2.dart';

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
        if (user == null || user?.id == null) {
          return const LoginScreen2();
        } else {
          if (user.id != null && user.isVerifiedBySyncCode == false) {
            // return SyncCodeScreen(storedHash: "test", onVerified: onVerified)
            return SyncCodeScreen(loggedUser: user);
          } else {
            return BottomScreen();
          }
        }
      },
    );
  }
}

// class AuthGate extends ConsumerWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         // 1. While waiting for the initial connection to Firebase Auth
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         // 2. If the user is logged in (snapshot has user data)
//         if (snapshot.hasData) {
//           print('---------------- Nevtersen hereglegch bna');
//           return const BottomScreen();
//         }

//         // 3. If the user is NOT logged in
//         return const LoginScreen();
//       },
//     );
//   }
// }
