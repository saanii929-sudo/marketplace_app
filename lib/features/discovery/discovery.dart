import '../catalog/category.dart';
import '../catalog/product.dart';

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

class DiscoveryBanner {
  const DiscoveryBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.ctaLabel,
    required this.ctaLink,
  });

  final int id;
  final String title;
  final String subtitle;
  final String image;
  final String ctaLabel;
  final String ctaLink;

  factory DiscoveryBanner.fromJson(Map<String, dynamic> json) => DiscoveryBanner(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    image: json['image'] as String? ?? '',
    ctaLabel: json['cta_label'] as String? ?? '',
    ctaLink: json['cta_link'] as String? ?? '',
  );
}

class DiscoveryFlashDeal {
  const DiscoveryFlashDeal({
    required this.id,
    required this.product,
    required this.dealPrice,
    required this.stockQty,
    required this.stockSold,
    required this.startsAt,
    required this.endsAt,
  });

  final int id;
  final CatalogProductSummary product;
  final double dealPrice;

  /// Remaining stock in the deal (see the field-meaning derivation in the
  /// Phase 4 plan — confirmed by cross-checking against `percent_stock_sold`
  /// in a real response).
  final int stockQty;
  final int stockSold;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Fraction of deal stock still remaining, for the progress bar — kept
  /// as a 0..1 remaining-fraction to match the original mock widget's
  /// exact visual meaning.
  double get remainingFraction {
    final total = stockQty + stockSold;
    return total <= 0 ? 0 : stockQty / total;
  }

  Duration get endsIn {
    if (endsAt == null) return Duration.zero;
    final diff = endsAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory DiscoveryFlashDeal.fromJson(Map<String, dynamic> json) => DiscoveryFlashDeal(
    id: json['id'] as int? ?? 0,
    product: CatalogProductSummary.fromJson(json['product'] as Map<String, dynamic>),
    dealPrice: _num(json['deal_price']),
    stockQty: json['stock_qty'] as int? ?? 0,
    stockSold: json['stock_sold'] as int? ?? 0,
    startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
    endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
  );
}

/// Parses `GET discovery/home/`'s full response.
class DiscoveryHome {
  const DiscoveryHome({
    required this.categories,
    required this.banners,
    required this.flashDeals,
    required this.brands,
    required this.featuredSellers,
    required this.trending,
    required this.popular,
    required this.featured,
    required this.recommended,
  });

  final List<Category> categories;
  final List<DiscoveryBanner> banners;
  final List<DiscoveryFlashDeal> flashDeals;
  final List<CatalogBrand> brands;
  final List<CatalogSeller> featuredSellers;
  final List<CatalogProductSummary> trending;
  final List<CatalogProductSummary> popular;
  final List<CatalogProductSummary> featured;
  final List<CatalogProductSummary> recommended;

  static List<CatalogProductSummary> _products(dynamic value) => (value as List<dynamic>? ?? [])
      .map((e) => CatalogProductSummary.fromJson(e as Map<String, dynamic>))
      .toList();

  factory DiscoveryHome.fromJson(Map<String, dynamic> json) => DiscoveryHome(
    categories: (json['categories'] as List<dynamic>? ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList(),
    banners: (json['banners'] as List<dynamic>? ?? [])
        .map((e) => DiscoveryBanner.fromJson(e as Map<String, dynamic>))
        .toList(),
    flashDeals: (json['flash_deals'] as List<dynamic>? ?? [])
        .map((e) => DiscoveryFlashDeal.fromJson(e as Map<String, dynamic>))
        .toList(),
    brands: (json['brands'] as List<dynamic>? ?? []).map((e) => CatalogBrand.fromJson(e as Map<String, dynamic>)).toList(),
    featuredSellers: (json['featured_sellers'] as List<dynamic>? ?? [])
        .map((e) => CatalogSeller.fromJson(e as Map<String, dynamic>))
        .toList(),
    trending: _products(json['trending_products']),
    popular: _products(json['popular_products']),
    featured: _products(json['featured_products']),
    recommended: _products(json['recommended_products']),
  );
}

class RecentlyViewedEntry {
  const RecentlyViewedEntry({required this.product, required this.viewedAt});

  final CatalogProductSummary product;
  final DateTime? viewedAt;

  factory RecentlyViewedEntry.fromJson(Map<String, dynamic> json) => RecentlyViewedEntry(
    product: CatalogProductSummary.fromJson(json['product'] as Map<String, dynamic>),
    viewedAt: DateTime.tryParse(json['viewed_at'] as String? ?? ''),
  );
}

class RecentSearch {
  const RecentSearch({required this.id, required this.queryText, required this.createdAt});

  final int id;
  final String queryText;
  final DateTime? createdAt;

  factory RecentSearch.fromJson(Map<String, dynamic> json) => RecentSearch(
    id: json['id'] as int? ?? 0,
    queryText: json['query_text'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}
