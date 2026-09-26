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
      // This backend's custom exception handler wraps validation errors as
      // `{"detail": "Validation error", "errors": {"field": ["specific
      // message"]}}` — `detail` is a generic label in that shape, so the
      // real per-field message in `errors` must be checked first.
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty && value.first is String) {
            return ApiException('${entry.key}: ${value.first}');
          }
          if (value is String && value.isNotEmpty) {
            return ApiException('${entry.key}: $value');
          }
        }
      }

      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return ApiException(detail);

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty && value.first is String) {
          return ApiException('${entry.key}: ${value.first}');
        }
        if (value is String && value.isNotEmpty) {
          return ApiException('${entry.key}: $value');
        }
      }
    }
    // A plain-text/JSON error body is safe to surface directly, but a
    // non-DRF failure (e.g. an unhandled server exception) can come back as
    // a full HTML debug page — never show that raw markup to the user.
    if (data is String && data.isNotEmpty && !data.trimLeft().startsWith('<')) {
      return ApiException(data);
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException('The connection timed out. Please try again.'),
      DioExceptionType.connectionError => const ApiException('No connection. Check your internet and try again.'),
      DioExceptionType.badResponse => const ApiException('Something went wrong on our end. Please try again.'),
      _ => ApiException(e.message ?? 'Something went wrong. Please try again.'),
    };
  }

  @override
  String toString() => message;
}
