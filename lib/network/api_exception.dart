import 'package:dio/dio.dart';

/// A human-readable error surfaced from a failed API call — parsed
/// defensively from whatever shape the backend's error body happens to be
/// (DRF commonly returns `{"detail": "..."}` or `{"field": ["error", ...]}`).
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return ApiException(detail);

      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return ApiException(value.first as String);
        }
        if (value is String && value.isNotEmpty) {
          return ApiException(value);
        }
      }
    }
    if (data is String && data.isNotEmpty) return ApiException(data);

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException('The connection timed out. Please try again.'),
      DioExceptionType.connectionError => const ApiException('No connection. Check your internet and try again.'),
      _ => ApiException(e.message ?? 'Something went wrong. Please try again.'),
    };
  }

  @override
  String toString() => message;
}
