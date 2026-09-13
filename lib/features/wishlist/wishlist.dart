import '../catalog/product.dart';

class WishlistEntry {
  const WishlistEntry({required this.id, required this.product, required this.createdAt});

  final int id;
  final CatalogProductSummary product;
  final DateTime? createdAt;

  factory WishlistEntry.fromJson(Map<String, dynamic> json) => WishlistEntry(
    id: json['id'] as int? ?? 0,
    product: CatalogProductSummary.fromJson(json['product'] as Map<String, dynamic>),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}
