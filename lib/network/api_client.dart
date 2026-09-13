import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';

export 'api_config.dart' show apiBaseUrl;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, connectTimeout: apiConnectTimeout, receiveTimeout: apiReceiveTimeout),
  );
  dio.interceptors.add(AuthInterceptor(dio));
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});
