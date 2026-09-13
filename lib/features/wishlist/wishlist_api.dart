import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'wishlist.dart';

class WishlistApi {
  WishlistApi(this._dio);
  final Dio _dio;

  Future<List<WishlistEntry>> list() => _guard(() async {
    final entries = <WishlistEntry>[];
    String? nextUrl = 'wishlist/';
    while (nextUrl != null) {
      final response = await _dio.get<Map<String, dynamic>>(nextUrl);
      final data = response.data!;
      entries.addAll((data['results'] as List<dynamic>).map((e) => WishlistEntry.fromJson(e as Map<String, dynamic>)));
      nextUrl = data['next'] as String?;
    }
    return entries;
  });

  /// Adds or removes the product — the endpoint is a toggle, not a
  /// separate add/remove pair.
  Future<void> toggle(int productId) =>
      _guard(() => _dio.post<dynamic>('wishlist/toggle/', data: {'product_id': productId}));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
