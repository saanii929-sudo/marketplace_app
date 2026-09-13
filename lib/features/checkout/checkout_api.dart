import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import '../cart/cart.dart';

class CheckoutApi {
  CheckoutApi(this._dio);
  final Dio _dio;

  /// Same shape as `GET /cart/` (minus `coupon_code`), reused via [Cart].
  Future<Cart> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('checkout/summary/');
      return Cart.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
