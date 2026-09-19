import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart' show Product;

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
double? _numOrNull(dynamic v) => v == null ? null : double.tryParse(v.toString());

/// Best-effort sport icon for a category name, used only as the fallback
/// glyph shown if a product's real photo fails to load (see
/// [NetworkImageBox]) — the real API has no confirmed image field for
/// categories themselves.
IconData iconForCategoryName(String name) {
  final key = name.toLowerCase();
  if (key.contains('football') || key.contains('soccer')) return Icons.sports_soccer;
  if (key.contains('basketball')) return Icons.sports_basketball;
  if (key.contains('run')) return Icons.directions_run;
  if (key.contains('gym') || key.contains('fitness')) return Icons.fitness_center;
  if (key.contains('tennis')) return Icons.sports_tennis;
  if (key.contains('box')) return Icons.sports_mma;
  if (key.contains('cycl') || key.contains('bike')) return Icons.pedal_bike;
  if (key.contains('swim')) return Icons.pool;
  if (key.contains('wear') || key.contains('apparel') || key.contains('cloth')) return Icons.checkroom;
  if (key.contains('accessor') || key.contains('watch')) return Icons.watch_outlined;
  return Icons.sports_outlined;
}

class CatalogSeller {
  const CatalogSeller({
    required this.id,
    required this.businessName,
    required this.slug,
    required this.tagline,
    required this.logo,
    required this.rating,
    required this.isVerified,
    required this.isFeatured,
  });

  final int id;
  final String businessName;
  final String slug;
  final String tagline;
  final String logo;
  final double rating;
  final bool isVerified;
  final bool isFeatured;

  factory CatalogSeller.fromJson(Map<String, dynamic> json) => CatalogSeller(
    id: json['id'] as int? ?? 0,
    businessName: json['business_name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    tagline: json['tagline'] as String? ?? '',
    logo: json['logo'] as String? ?? '',
    rating: _num(json['rating']),
    isVerified: json['is_verified'] as bool? ?? false,
    isFeatured: json['is_featured'] as bool? ?? false,
  );
}

class CatalogBrand {
  const CatalogBrand({required this.id, required this.name, required this.slug, required this.logo});

  final int id;
  final String name;
  final String slug;
  final String logo;

  factory CatalogBrand.fromJson(Map<String, dynamic> json) => CatalogBrand(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    logo: json['logo'] as String? ?? '',
  );
}

class ProductImage {
  const ProductImage({required this.id, required this.url, required this.displayOrder});

  final int id;
  final String url;
  final int displayOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    id: json['id'] as int? ?? 0,
    url: json['url'] as String? ?? '',
    displayOrder: json['display_order'] as int? ?? 0,
  );
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.colorSwatch,
    required this.stockQty,
    required this.inStock,
  });

  final int id;
  final String size;
  final String color;
  final String? colorSwatch;
  final int stockQty;
  final bool inStock;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as int? ?? 0,
    size: json['size'] as String? ?? '',
    color: json['color'] as String? ?? '',
    colorSwatch: json['color_swatch'] as String?,
    stockQty: json['stock_qty'] as int? ?? 0,
    inStock: json['in_stock'] as bool? ?? true,
  );
}

class ProductReview {
  const ProductReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: json['id'] as int? ?? 0,
    userName: json['user_name'] as String? ?? 'Anonymous',
    rating: json['rating'] as int? ?? 0,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

/// Product-list item shape from `GET /catalog/products/`.
class CatalogProductSummary {
  const CatalogProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.originalPrice,
    required this.avgRating,
    required this.reviewCount,
    required this.isFeatured,
    required this.seller,
    required this.categoryId,
    required this.categoryName,
    required this.brandName,
    required this.primaryImage,
  });

  final int id;
  final String name;
  final String slug;
  final double price;
  final double? originalPrice;
  final double avgRating;
  final int reviewCount;
  final bool isFeatured;
  final CatalogSeller? seller;
  final int? categoryId;
  final String categoryName;
  final String brandName;
  final String primaryImage;

  factory CatalogProductSummary.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final brand = json['brand'] as Map<String, dynamic>?;
    final sellerJson = json['seller'] as Map<String, dynamic>?;
    return CatalogProductSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: _num(json['price']),
      originalPrice: _numOrNull(json['original_price']),
      avgRating: _num(json['avg_rating']),
      reviewCount: json['review_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      seller: sellerJson == null ? null : CatalogSeller.fromJson(sellerJson),
      categoryId: category?['id'] as int?,
      categoryName: category?['name'] as String? ?? '',
      brandName: brand?['name'] as String? ?? '',
      primaryImage: json['primary_image'] as String? ?? '',
    );
  }

  /// Bridges into the existing mock [Product] type so `ProductTile`,
  /// `ProductRail`, cart and wishlist widgets need no changes at all — see
  /// the Product-model bridge decision in the Phase 2 plan.
  Product toProduct() => Product(
    id: id.toString(),
    name: name,
    brand: brandName.isEmpty ? 'SportTech' : brandName,
    category: categoryName,
    subcategory: '',
    price: price,
    originalPrice: originalPrice,
    rating: avgRating,
    reviewCount: reviewCount,
    icon: iconForCategoryName(categoryName),
    imageUrl: primaryImage,
    description: '',
    badgeLabel: isFeatured ? 'Featured' : null,
    slug: slug,
  );
}

/// Full product detail from `GET /catalog/products/{slug}/`.
class CatalogProductDetail {
  const CatalogProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.sku,
    required this.stockQty,
    required this.inStock,
    required this.avgRating,
    required this.reviewCount,
    required this.isFeatured,
    required this.seller,
    required this.categoryName,
    required this.subcategoryName,
    required this.brandName,
    required this.images,
    required this.variants,
    required this.relatedProducts,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double? originalPrice;
  final String sku;
  final int stockQty;
  final bool inStock;
  final double avgRating;
  final int reviewCount;
  final bool isFeatured;
  final CatalogSeller? seller;
  final String categoryName;
  final String subcategoryName;
  final String brandName;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<CatalogProductSummary> relatedProducts;

  factory CatalogProductDetail.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final subcategory = json['subcategory'] as Map<String, dynamic>?;
    final brand = json['brand'] as Map<String, dynamic>?;
    final sellerJson = json['seller'] as Map<String, dynamic>?;
    return CatalogProductDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _num(json['price']),
      originalPrice: _numOrNull(json['original_price']),
      sku: json['sku'] as String? ?? '',
      stockQty: json['stock_qty'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? true,
      avgRating: _num(json['avg_rating']),
      reviewCount: json['review_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      seller: sellerJson == null ? null : CatalogSeller.fromJson(sellerJson),
      categoryName: category?['name'] as String? ?? '',
      subcategoryName: subcategory?['name'] as String? ?? '',
      brandName: brand?['name'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedProducts: (json['related_products'] as List<dynamic>? ?? [])
          .map((e) => CatalogProductSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Product toProduct() => Product(
    id: id.toString(),
    name: name,
    brand: brandName.isEmpty ? 'SportTech' : brandName,
    category: categoryName,
    subcategory: subcategoryName,
    price: price,
    originalPrice: originalPrice,
    rating: avgRating,
    reviewCount: reviewCount,
    icon: iconForCategoryName(categoryName),
    imageUrl: images.isNotEmpty ? images.first.url : '',
    description: description,
    badgeLabel: isFeatured ? 'Featured' : null,
    slug: slug,
  );
}

/// A brand's public storefront, from `GET /catalog/brands/{slug}/` —
/// mirrors [SellerProfile] but with a slimmer schema (no tagline/rating/
/// support phone — just identity + its product listing).
class BrandProfile {
  const BrandProfile({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    required this.productCount,
    required this.products,
  });

  final int id;
  final String name;
  final String slug;
  final String logo;
  final int productCount;
  final List<CatalogProductSummary> products;

  factory BrandProfile.fromJson(Map<String, dynamic> json) => BrandProfile(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    logo: json['logo'] as String? ?? '',
    productCount: json['product_count'] as int? ?? 0,
    products: (json['products'] as List<dynamic>? ?? [])
        .map((e) => CatalogProductSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// A seller's public storefront, from `GET /catalog/sellers/{slug}/`.
class SellerProfile {
  const SellerProfile({
    required this.id,
    required this.businessName,
    required this.slug,
    required this.tagline,
    required this.logo,
    required this.rating,
    required this.isVerified,
    required this.isFeatured,
    required this.supportPhone,
    required this.productCount,
    required this.products,
  });

  final int id;
  final String businessName;
  final String slug;
  final String tagline;
  final String logo;
  final double rating;
  final bool isVerified;
  final bool isFeatured;
  final String supportPhone;
  final int productCount;
  final List<CatalogProductSummary> products;

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
    id: json['id'] as int? ?? 0,
    businessName: json['business_name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    tagline: json['tagline'] as String? ?? '',
    logo: json['logo'] as String? ?? '',
    rating: _num(json['rating']),
    isVerified: json['is_verified'] as bool? ?? false,
    isFeatured: json['is_featured'] as bool? ?? false,
    supportPhone: json['support_phone'] as String? ?? '',
    productCount: json['product_count'] as int? ?? 0,
    products: (json['products'] as List<dynamic>? ?? [])
        .map((e) => CatalogProductSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
