import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'catalog_api.dart';
import 'category.dart';
import 'product.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(dioProvider)));

final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.read(catalogApiProvider).getCategories());

/// All products across every page — used to power the Categories screen's
/// client-side category filter, since `GET /catalog/products/` has no
/// filter query params in the given API.
final allProductsProvider = FutureProvider<List<CatalogProductSummary>>(
  (ref) => ref.read(catalogApiProvider).getAllProducts(),
);

final productDetailProvider = FutureProvider.family<CatalogProductDetail, String>(
  (ref, slug) => ref.read(catalogApiProvider).getProduct(slug),
);

final productReviewsProvider = FutureProvider.family<List<ProductReview>, String>(
  (ref, slug) => ref.read(catalogApiProvider).getProductReviews(slug),
);
