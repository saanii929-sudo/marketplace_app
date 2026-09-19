import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import '../cart/cart.dart';
import 'delivery_method.dart';
import 'hubtel_status.dart';

class CheckoutApi {
  CheckoutApi(this._dio);
  final Dio _dio;

  /// Same shape as `GET /cart/` (minus `coupon_code`), reused via [Cart].
  Future<Cart> getSummary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('checkout/summary/');
    return Cart.fromJson(response.data!);
  });

  Future<List<DeliveryMethod>> getDeliveryMethods() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('delivery-methods/');
    return (response.data ?? []).map((e) => DeliveryMethod.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Despite the given spec listing no parameters, the live server 400s
  /// with `"reference is required."` without one — [reference] is the
  /// value `POST /orders/` returns for the checkout it just started.
  Future<HubtelCheckoutStatus> getHubtelStatus(String reference) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'checkout/hubtel/status/',
      queryParameters: {'reference': reference},
    );
    return HubtelCheckoutStatus.fromJson(response.data!);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
