class Subcategory {
  const Subcategory({required this.id, required this.name, required this.slug, required this.displayOrder});

  final int id;
  final String name;
  final String slug;
  final int displayOrder;

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    displayOrder: json['display_order'] as int? ?? 0,
  );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.displayOrder,
    required this.subcategories,
  });

  final int id;
  final String name;
  final String slug;
  final bool isActive;
  final int displayOrder;
  final List<Subcategory> subcategories;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    displayOrder: json['display_order'] as int? ?? 0,
    subcategories: (json['subcategories'] as List<dynamic>? ?? [])
        .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
