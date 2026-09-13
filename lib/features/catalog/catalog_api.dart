import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'category.dart';
import 'product.dart';

class CatalogApi {
  CatalogApi(this._dio);
  final Dio _dio;

  Future<List<Category>> getCategories() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('catalog/categories/');
    return (response.data ?? []).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Fetches every page of `GET /catalog/products/` — the given endpoint
  /// has no category/search filter query params, so category browsing
  /// filters this full list client-side (see catalog_controllers.dart).
  Future<List<CatalogProductSummary>> getAllProducts() => _guard(() async {
    final products = <CatalogProductSummary>[];
    String? nextUrl = 'catalog/products/';
    while (nextUrl != null) {
      final response = await _dio.get<Map<String, dynamic>>(nextUrl);
      final data = response.data!;
      products.addAll(
        (data['results'] as List<dynamic>).map((e) => CatalogProductSummary.fromJson(e as Map<String, dynamic>)),
      );
      nextUrl = data['next'] as String?;
    }
    return products;
  });

  Future<CatalogProductDetail> getProduct(String slug) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('catalog/products/$slug/');
    return CatalogProductDetail.fromJson(response.data!);
  });

  Future<List<ProductReview>> getProductReviews(String slug) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('catalog/products/$slug/reviews/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => ProductReview.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Fire-and-forget view-count ping — failures are ignored since this is
  /// purely analytics and shouldn't affect the viewing experience.
  Future<void> postProductView(String slug) async {
    try {
      await _dio.post<dynamic>('catalog/products/$slug/view/');
    } on DioException {
      // Ignored — see doc comment above.
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
