import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/firestore/services/auth/index.dart';
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
      // await Future.delayed(const Duration(milliseconds: 600));

      final user = await Auth().login(phone, password);

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      } else {
        // failure
      }
    });
  }

  Future<void> checkLogin() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await Auth().userChecker();

      final test = user?['id'];
      print('USERRR: ${user} ${test}');

      if (user != null && user['id'] != null) {
        return AppUser(id: user['id'], phone: user['phone']);
      } else {
        return AppUser(id: "1234", phone: "MOCKUSER");
      }
    });
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AppUser?>>(AuthController.new);
