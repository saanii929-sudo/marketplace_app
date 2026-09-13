import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import '../../network/token_storage.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<void> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
  }) => _guard(
    () => _dio.post<dynamic>(
      'auth/register/',
      data: {'email': email, 'phone': phone, 'full_name': fullName, 'password': password},
    ),
  );

  Future<void> login({required String identifier, required String password}) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/login/',
      data: {'identifier': identifier, 'password': password},
    );
    await _storeTokensIfPresent(response.data);
  });

  Future<void> logout() async {
    final refresh = await TokenStorage.instance.readRefresh();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _dio.post<dynamic>('auth/logout/', data: {'refresh': refresh});
      }
    } on DioException {
      // Best-effort — the tokens are cleared locally regardless below.
    } finally {
      await TokenStorage.instance.clear();
    }
  }

  Future<void> sendOtp({required String destination, required String purpose}) => _guard(
    () => _dio.post<dynamic>('auth/otp/send/', data: {'destination': destination, 'purpose': purpose}),
  );

  Future<void> verifyOtp({required String destination, required String purpose, required String code}) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          'auth/otp/verify/',
          data: {'destination': destination, 'purpose': purpose, 'code': code},
        );
        await _storeTokensIfPresent(response.data);
      });

  Future<void> forgotPassword({required String destination}) =>
      _guard(() => _dio.post<dynamic>('auth/password/forgot/', data: {'destination': destination}));

  Future<void> resetPassword({required String destination, required String code, required String newPassword}) =>
      _guard(
        () => _dio.post<dynamic>(
          'auth/password/reset/',
          data: {'destination': destination, 'code': code, 'new_password': newPassword},
        ),
      );

  /// Exchanges a refresh token for a new access token. Called by
  /// [AuthInterceptor] on a 401 using a plain, non-intercepted [Dio] so this
  /// request itself never recurses back through the 401 handler.
  static Future<void> refreshTokens(Dio plainDio, String refresh) async {
    final response = await plainDio.post<Map<String, dynamic>>('auth/token/refresh/', data: {'refresh': refresh});
    final data = response.data;
    final access = data?['access'] as String?;
    if (access == null || access.isEmpty) {
      throw DioException(requestOptions: response.requestOptions, error: 'No access token in refresh response');
    }
    final newRefresh = data?['refresh'] as String?;
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await TokenStorage.instance.save(access: access, refresh: newRefresh);
    } else {
      await TokenStorage.instance.updateAccess(access);
    }
  }

  Future<void> _storeTokensIfPresent(Map<String, dynamic>? data) async {
    if (data == null) return;
    final access = data['access'] as String? ?? data['token'] as String? ?? data['key'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || access.isEmpty) return;
    if (refresh != null && refresh.isNotEmpty) {
      await TokenStorage.instance.save(access: access, refresh: refresh);
    } else {
      await TokenStorage.instance.updateAccess(access);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
