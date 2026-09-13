import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'cart.dart';

class CartApi {
  CartApi(this._dio);
  final Dio _dio;

  Future<Cart> getCart() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('cart/');
    return Cart.fromJson(response.data!);
  });

  Future<Cart> clear() => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('cart/clear/');
    return Cart.fromJson(response.data!);
  });

  Future<void> addItem({required int productId, int? variantId, int qty = 1}) => _guard(
    () => _dio.post<dynamic>(
      'cart/items/',
      data: {'product_id': productId, 'variant_id': ?variantId, 'qty': qty},
    ),
  );

  Future<void> updateQty(int itemId, int qty) =>
      _guard(() => _dio.patch<dynamic>('cart/items/$itemId/', data: {'qty': qty}));

  Future<void> removeItem(int itemId) => _guard(() => _dio.delete<dynamic>('cart/items/$itemId/'));

  Future<void> applyCoupon(String code) => _guard(() => _dio.post<dynamic>('cart/coupon/', data: {'code': code}));

  Future<void> removeCoupon() => _guard(() => _dio.delete<dynamic>('cart/coupon/'));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
