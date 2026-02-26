import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';
import 'package:test_firebase/firestore/services/index.dart';
import 'package:test_firebase/firestore/services/message/handlers.dart';
import 'package:test_firebase/firestore/services/message/utils.dart';
import 'package:test_firebase/models/user.dart';

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    // initial state: not logged in
    return const AsyncValue.data(null);
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await Auth().login(phone, password);

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      }
    });
  }

  Future<void> checkLogin() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await Auth().userChecker();

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      }
    });
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(AuthController.new);
