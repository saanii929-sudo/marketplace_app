import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'order.dart';

class OrdersApi {
  OrdersApi(this._dio);
  final Dio _dio;

  /// First page only — the "My Orders" screen never paginated even with
  /// mock data, so this matches existing UX fidelity rather than adding a
  /// pagination UI element that wasn't there before.
  Future<List<OrderSummary>> list() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('orders/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<OrderDetail> get(String orderNumber) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('orders/$orderNumber/');
    return OrderDetail.fromJson(response.data!);
  });

  Future<OrderTracking> getTracking(String orderNumber) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('orders/$orderNumber/tracking/');
    return OrderTracking.fromJson(response.data!);
  });

  Future<OrderDetail> cancel(String orderNumber) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('orders/$orderNumber/cancel/');
    return OrderDetail.fromJson(response.data!);
  });

  /// The response schema for this endpoint isn't documented beyond a
  /// generic placeholder, so this only reports success/failure — callers
  /// should refresh the cart afterward rather than rely on a parsed body.
  Future<void> buyAgain(String orderNumber) => _guard(() => _dio.post<dynamic>('orders/$orderNumber/buy-again/'));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
