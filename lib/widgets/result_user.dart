import 'package:flutter/material.dart';
import 'package:test_firebase/models/user.dart';

class ResultUser extends StatelessWidget {
  const ResultUser({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Unknown user'),
      subtitle: Text("test"),
      trailing: Text("trail"),
    );
  }
}
