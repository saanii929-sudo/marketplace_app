import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthApi get _api => ref.read(authApiProvider);

  Future<void> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
  }) => _run(() => _api.register(email: email, phone: phone, fullName: fullName, password: password));

  Future<void> login({required String identifier, required String password}) =>
      _run(() => _api.login(identifier: identifier, password: password));

  Future<void> logout() => _run(_api.logout);

  Future<void> sendOtp({required String destination, required String purpose}) =>
      _run(() => _api.sendOtp(destination: destination, purpose: purpose));

  Future<void> verifyOtp({required String destination, required String purpose, required String code}) =>
      _run(() => _api.verifyOtp(destination: destination, purpose: purpose, code: code));

  Future<void> forgotPassword({required String destination}) => _run(() => _api.forgotPassword(destination: destination));

  Future<void> resetPassword({required String destination, required String code, required String newPassword}) =>
      _run(() => _api.resetPassword(destination: destination, code: code, newPassword: newPassword));

  Future<void> _run(Future<void> Function() call) async {
    state = const AsyncLoading();
    try {
      await call();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);
