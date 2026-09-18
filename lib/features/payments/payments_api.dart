import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'payment_method.dart';

/// `create()` submits with a locally-generated placeholder `token` — the
/// given endpoint expects a real payment gateway's own tokenization result
/// (e.g. Paystack's client-side SDK popup), which requires a public key/
/// SDK integration nobody has wired up yet. No card number is collected
/// here (only the non-sensitive last 4 digits + expiry, matching what the
/// endpoint itself asks for), so nothing sensitive leaks — but the
/// resulting "payment method" is not connected to a real chargeable card.
/// Swap the placeholder for a real SDK token once that integration exists.
class PaymentsApi {
  PaymentsApi(this._dio);
  final Dio _dio;

  Future<List<PaymentMethod>> list() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('payments/methods/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// [expiryMonth]/[expiryYear] are omitted entirely for methods with no
  /// card expiry (e.g. mobile money) rather than sent as a made-up date.
  Future<void> create({
    required String gateway,
    required String token,
    required String brand,
    required String last4,
    int? expiryMonth,
    int? expiryYear,
  }) => _guard(
    () => _dio.post<dynamic>(
      'payments/methods/',
      data: {
        'gateway': gateway,
        'token': token,
        'brand': brand,
        'last4': last4,
        'expiry_month': ?expiryMonth,
        'expiry_year': ?expiryYear,
      },
    ),
  );

  Future<void> delete(int id) => _guard(() => _dio.delete<dynamic>('payments/methods/$id/'));

  Future<PaymentMethod> setDefault(int id) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('payments/methods/$id/set_default/');
    return PaymentMethod.fromJson(response.data!);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
