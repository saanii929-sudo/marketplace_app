import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'catalog_api.dart';
import 'category.dart';
import 'product.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(dioProvider)));

final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.read(catalogApiProvider).getCategories());

/// All products across every page — used by the search screen's
/// client-side suggestion filter, since `GET /catalog/products/` has no
/// text-search query param in the given API.
final allProductsProvider = FutureProvider<List<CatalogProductSummary>>(
  (ref) => ref.read(catalogApiProvider).getAllProducts(),
);

/// Products for one category (and optionally one of its subcategories),
/// via the resource-nested `GET /catalog/categories/{slug}/products/` —
/// powers the Categories screen's grid, with real server-side filtering
/// for both the category sidebar and the subcategory chip row.
final categoryProductsProvider = FutureProvider.family<List<CatalogProductSummary>, (String categorySlug, String? subcategorySlug)>(
  (ref, params) => ref.read(catalogApiProvider).getProductsForCategory(params.$1, subcategorySlug: params.$2),
);

final productDetailProvider = FutureProvider.family<CatalogProductDetail, String>(
  (ref, slug) => ref.read(catalogApiProvider).getProduct(slug),
);

final productReviewsProvider = FutureProvider.family<List<ProductReview>, String>(
  (ref, slug) => ref.read(catalogApiProvider).getProductReviews(slug),
);

final sellerProfileProvider = FutureProvider.family<SellerProfile, String>(
  (ref, slug) => ref.read(catalogApiProvider).getSeller(slug),
);
