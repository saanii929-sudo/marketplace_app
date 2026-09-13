import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'payment_method.dart';

/// Creating a payment method isn't wired here: the given endpoint expects
/// a `token` field, which real payment gateways only produce via their own
/// client-side SDK (e.g. Paystack's tokenization flow). No such SDK/keys
/// were provided, and collecting raw card details in this app's own form
/// to send as a fake "token" would be unsafe — so "+ Add payment method"
/// stays a stub until that integration exists.
class PaymentsApi {
  PaymentsApi(this._dio);
  final Dio _dio;

  Future<List<PaymentMethod>> list() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('payments/methods/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  });

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
