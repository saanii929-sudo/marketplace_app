import 'package:dio/dio.dart';

import '../features/auth/auth_api.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Attaches the bearer access token to every request. On a 401 that hasn't
/// already been retried, exchanges the stored refresh token for a new
/// access token (via a plain, non-intercepted [Dio] so the refresh call
/// itself can't recurse back into this handler) and retries the original
/// request once. If there's no refresh token, or the refresh call itself
/// fails, the stored tokens are cleared and the 401 propagates so the
/// caller can surface it (the user re-logs in via the existing login
/// screen).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);
  final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final access = await TokenStorage.instance.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra['_retriedAfterRefresh'] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refresh = await TokenStorage.instance.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await TokenStorage.instance.clear();
      handler.next(err);
      return;
    }

    try {
      final plainDio = Dio(
        BaseOptions(baseUrl: apiBaseUrl, connectTimeout: apiConnectTimeout, receiveTimeout: apiReceiveTimeout),
      );
      await AuthApi.refreshTokens(plainDio, refresh);
      final newAccess = await TokenStorage.instance.readAccess();

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      retryOptions.extra['_retriedAfterRefresh'] = true;
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException {
      await TokenStorage.instance.clear();
      handler.next(err);
    }
  }
}
