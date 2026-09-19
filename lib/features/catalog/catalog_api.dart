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

  /// Fetches every page of `GET /catalog/categories/{slug}/products/` — the
  /// dedicated resource-nested alternative to filtering `/catalog/products/`
  /// client-side, and the only way to filter by subcategory (the flat
  /// product list has no subcategory field per item).
  Future<List<CatalogProductSummary>> getProductsForCategory(String categorySlug, {String? subcategorySlug}) =>
      _guard(() async {
        final products = <CatalogProductSummary>[];
        String? nextUrl = 'catalog/categories/$categorySlug/products/';
        Map<String, dynamic>? query = {'subcategory': ?subcategorySlug};
        while (nextUrl != null) {
          final response = await _dio.get<Map<String, dynamic>>(nextUrl, queryParameters: query);
          // Only the first request needs the subcategory filter applied —
          // `next` already carries it forward as part of the full URL.
          query = null;
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

  Future<SellerProfile> getSeller(String slug) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('catalog/sellers/$slug/');
    return SellerProfile.fromJson(response.data!);
  });

  Future<BrandProfile> getBrand(String slug) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('catalog/brands/$slug/');
    return BrandProfile.fromJson(response.data!);
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
