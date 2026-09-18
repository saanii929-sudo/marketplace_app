import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

String _imageUrl(String slug, {int width = 400, int height = 400}) =>
    'https://picsum.photos/seed/$slug/$width/$height';

String formatPrice(double value) => 'GH₵${value.toStringAsFixed(0)}';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subcategory,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.icon,
    required this.imageUrl,
    required this.description,
    this.badgeLabel,
    this.slug,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String subcategory;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final IconData icon;
  final String imageUrl;
  final String description;
  final String? badgeLabel;

  /// Set only for products sourced from the real catalog API (via
  /// `CatalogProductSummary`/`CatalogProductDetail.toProduct()`). Null for
  /// legacy mock products (e.g. past-order line items) — `null` here is
  /// what tells [ProductDetailScreen] there's no real detail to fetch.
  final String? slug;

  String get sku => 'SPT-${id.toUpperCase()}';

  int? get discountPercent => originalPrice == null
      ? null
      : (((originalPrice! - price) / originalPrice!) * 100).round();
}

class Collection {
  const Collection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class Seller {
  const Seller({
    required this.name,
    required this.tagline,
    required this.rating,
    required this.description,
    this.verified = true,
  });

  final String name;
  final String tagline;
  final double rating;
  final String description;
  final bool verified;
}

class Review {
  const Review({required this.name, required this.rating, required this.text});
  final String name;
  final int rating;
  final String text;
}

final List<Product> mockProducts = [
  // Football
  Product(
    id: 'p1',
    name: 'Pro Match Football Boots',
    brand: 'Vantage',
    category: 'Football',
    subcategory: 'Boots',
    price: 329,
    originalPrice: 449,
    rating: 4.6,
    reviewCount: 212,
    icon: Icons.sports_soccer,
    imageUrl: _imageUrl('sporttech-football-boots'),
    description:
        'Engineered for grip and control on grass or turf, built to hold up through a full season of match play without losing shape.',
    badgeLabel: 'Trending',
  ),
  Product(
    id: 'p2',
    name: 'Club Jersey 2026 Home Kit',
    brand: 'Fieldworks',
    category: 'Football',
    subcategory: 'Jerseys',
    price: 210,
    originalPrice: 259,
    rating: 4.7,
    reviewCount: 98,
    icon: Icons.checkroom,
    imageUrl: _imageUrl('sporttech-football-jersey'),
    description:
        'Lightweight, breathable matchday jersey with moisture-wicking fabric so you stay cool and focused for the full 90.',
  ),
  Product(
    id: 'p3',
    name: 'Goalkeeper Gloves Pro',
    brand: 'Fieldworks',
    category: 'Football',
    subcategory: 'Gloves',
    price: 150,
    originalPrice: 190,
    rating: 4.6,
    reviewCount: 88,
    icon: Icons.sports_soccer,
    imageUrl: _imageUrl('sporttech-football-gloves'),
    description:
        'Latex palm grip and reinforced finger spines give you the confidence to commit to every save.',
  ),
  Product(
    id: 'p4',
    name: 'Season 26 Match Football',
    brand: 'Vantage',
    category: 'Football',
    subcategory: 'Balls',
    price: 380,
    rating: 4.3,
    reviewCount: 64,
    icon: Icons.sports_soccer,
    imageUrl: _imageUrl('sporttech-football-ball'),
    description:
        'FIFA-quality construction with a textured surface for consistent flight and true touch in any weather.',
  ),

  // Basketball
  Product(
    id: 'p5',
    name: 'Pro Court Basketball',
    brand: 'Spalding',
    category: 'Basketball',
    subcategory: 'Balls',
    price: 220,
    originalPrice: 280,
    rating: 4.6,
    reviewCount: 198,
    icon: Icons.sports_basketball,
    imageUrl: _imageUrl('sporttech-basketball-ball'),
    description:
        'Composite leather cover with deep channels for a secure grip on indoor and outdoor courts alike.',
  ),
  Product(
    id: 'p6',
    name: 'Baseline Hi-Top Sneakers',
    brand: 'Baseline',
    category: 'Basketball',
    subcategory: 'Shoes',
    price: 410,
    rating: 4.5,
    reviewCount: 143,
    icon: Icons.sports_basketball,
    imageUrl: _imageUrl('sporttech-basketball-shoes'),
    description:
        'Ankle-support hi-tops with responsive cushioning built for quick cuts and hard landings.',
    badgeLabel: 'New',
  ),

  // Running
  Product(
    id: 'p7',
    name: 'Trailhead Running Shoes',
    brand: 'Ridgeline',
    category: 'Running',
    subcategory: 'Shoes',
    price: 412,
    rating: 4.8,
    reviewCount: 540,
    icon: Icons.directions_run,
    imageUrl: _imageUrl('sporttech-running-shoes'),
    description:
        'A breathable knit upper and responsive foam midsole built to carry you from easy miles to race day.',
    badgeLabel: 'Best Seller',
  ),
  Product(
    id: 'p8',
    name: 'Lightweight Running Shorts',
    brand: 'Ridgeline',
    category: 'Running',
    subcategory: 'Apparel',
    price: 130,
    originalPrice: 165,
    rating: 4.4,
    reviewCount: 76,
    icon: Icons.directions_run,
    imageUrl: _imageUrl('sporttech-running-shorts'),
    description:
        'Four-way stretch fabric with a built-in liner, made to move with you on your longest runs.',
  ),

  // Gym & Fitness
  Product(
    id: 'p9',
    name: 'Adjustable Dumbbell Set 20kg',
    brand: 'Solstice',
    category: 'Gym & Fitness',
    subcategory: 'Equipment',
    price: 640,
    rating: 4.5,
    reviewCount: 267,
    icon: Icons.fitness_center,
    imageUrl: _imageUrl('sporttech-gym-dumbbell'),
    description:
        'Swap plates in seconds with a quick-lock dial — a full rack of weights in one compact set.',
    badgeLabel: 'New',
  ),
  Product(
    id: 'p10',
    name: 'Resistance Bands Set',
    brand: 'Solstice',
    category: 'Gym & Fitness',
    subcategory: 'Accessories',
    price: 95,
    originalPrice: 120,
    rating: 4.3,
    reviewCount: 121,
    icon: Icons.fitness_center,
    imageUrl: _imageUrl('sporttech-gym-bands'),
    description:
        'Five resistance levels in one set, perfect for warm-ups, mobility work, or a full at-home circuit.',
  ),

  // Tennis
  Product(
    id: 'p11',
    name: 'Carbon Tennis Racket',
    brand: 'Baseline',
    category: 'Tennis',
    subcategory: 'Rackets',
    price: 540,
    originalPrice: 650,
    rating: 4.9,
    reviewCount: 87,
    icon: Icons.sports_tennis,
    imageUrl: _imageUrl('sporttech-tennis-racket'),
    description:
        'A carbon-fiber frame tuned for power and control, favoured by players who like to dictate the point.',
  ),
  Product(
    id: 'p12',
    name: 'Court Polo Shirt',
    brand: 'Baseline',
    category: 'Tennis',
    subcategory: 'Apparel',
    price: 145,
    rating: 4.4,
    reviewCount: 52,
    icon: Icons.sports_tennis,
    imageUrl: _imageUrl('sporttech-tennis-polo'),
    description:
        'Classic-fit polo in quick-dry fabric, tailored for the court and comfortable enough to wear off it.',
  ),

  // Boxing
  Product(
    id: 'p13',
    name: 'Pro Boxing Gloves 14oz',
    brand: 'Ironclad',
    category: 'Boxing',
    subcategory: 'Gloves',
    price: 210,
    rating: 4.4,
    reviewCount: 152,
    icon: Icons.sports_mma,
    imageUrl: _imageUrl('sporttech-boxing-gloves'),
    description:
        'Layered foam padding and a secure wrist strap for hours of pad work and sparring.',
  ),
  Product(
    id: 'p14',
    name: 'Freestanding Punch Bag',
    brand: 'Ironclad',
    category: 'Boxing',
    subcategory: 'Equipment',
    price: 590,
    originalPrice: 720,
    rating: 4.6,
    reviewCount: 61,
    icon: Icons.sports_mma,
    imageUrl: _imageUrl('sporttech-boxing-bag'),
    description:
        'A weighted base and adjustable height make this the centerpiece of any home boxing setup.',
  ),

  // Cycling
  Product(
    id: 'p15',
    name: 'Carbon Road Bike Helmet',
    brand: 'Giro',
    category: 'Cycling',
    subcategory: 'Helmets',
    price: 260,
    originalPrice: 340,
    rating: 4.7,
    reviewCount: 121,
    icon: Icons.pedal_bike,
    imageUrl: _imageUrl('sporttech-cycling-helmet'),
    description:
        'Aerodynamic shell with deep ventilation channels, engineered to keep you cool and protected on long rides.',
    badgeLabel: 'New',
  ),
  Product(
    id: 'p16',
    name: 'Padded Cycling Gloves',
    brand: 'Giro',
    category: 'Cycling',
    subcategory: 'Accessories',
    price: 90,
    rating: 4.2,
    reviewCount: 40,
    icon: Icons.pedal_bike,
    imageUrl: _imageUrl('sporttech-cycling-gloves'),
    description:
        'Gel-padded palms absorb road vibration so your hands stay comfortable mile after mile.',
  ),

  // Swimming
  Product(
    id: 'p17',
    name: 'Racing Swim Goggles',
    brand: 'Speedo',
    category: 'Swimming',
    subcategory: 'Goggles',
    price: 80,
    rating: 4.3,
    reviewCount: 96,
    icon: Icons.pool,
    imageUrl: _imageUrl('sporttech-swimming-goggles'),
    description:
        'Anti-fog, UV-protected lenses with a low-profile fit built for speed in the pool.',
  ),
  Product(
    id: 'p18',
    name: 'Performance Swimsuit',
    brand: 'Speedo',
    category: 'Swimming',
    subcategory: 'Apparel',
    price: 175,
    originalPrice: 210,
    rating: 4.5,
    reviewCount: 58,
    icon: Icons.pool,
    imageUrl: _imageUrl('sporttech-swimming-suit'),
    description:
        'Chlorine-resistant fabric with a compressive fit designed to reduce drag through every lap.',
  ),

  // Sportswear
  Product(
    id: 'p19',
    name: 'Training Jersey Set',
    brand: 'Kinetic',
    category: 'Sportswear',
    subcategory: 'Jerseys',
    price: 160,
    originalPrice: 220,
    rating: 4.5,
    reviewCount: 210,
    icon: Icons.checkroom,
    imageUrl: _imageUrl('sporttech-sportswear-jersey'),
    description:
        'A breathable jersey and shorts set built for high-intensity training sessions, wash after wash.',
    badgeLabel: 'Trending',
  ),
  Product(
    id: 'p20',
    name: 'Flex Training Hoodie',
    brand: 'Kinetic',
    category: 'Sportswear',
    subcategory: 'Hoodies',
    price: 189,
    rating: 4.4,
    reviewCount: 132,
    icon: Icons.checkroom,
    imageUrl: _imageUrl('sporttech-sportswear-hoodie'),
    description:
        'Stretch fleece with a relaxed fit, made for warm-ups, cool-downs, and everything in between.',
  ),

  // Accessories
  Product(
    id: 'p21',
    name: 'GPS Sports Watch',
    brand: 'Garmin',
    category: 'Accessories',
    subcategory: 'Watches',
    price: 780,
    rating: 4.8,
    reviewCount: 302,
    icon: Icons.watch_outlined,
    imageUrl: _imageUrl('sporttech-accessories-watch'),
    description:
        'Built-in GPS, heart-rate tracking, and multi-sport modes to keep every session logged and on record.',
    badgeLabel: 'Best Seller',
  ),
  Product(
    id: 'p22',
    name: 'Gym Duffel Bag',
    brand: 'Kinetic',
    category: 'Accessories',
    subcategory: 'Bags',
    price: 165,
    originalPrice: 205,
    rating: 4.5,
    reviewCount: 74,
    icon: Icons.watch_outlined,
    imageUrl: _imageUrl('sporttech-accessories-bag'),
    description:
        'A dedicated shoe compartment and water-resistant base keep your gym kit organized and dry.',
  ),
];

final List<Collection> mockCollections = [
  Collection(
    title: 'Football Collection',
    subtitle: 'Boots, jerseys & match balls',
    icon: Icons.sports_soccer,
    color: AppColors.navy,
  ),
  Collection(
    title: 'Gym Collection',
    subtitle: 'Everything for your next PR',
    icon: Icons.fitness_center,
    color: AppColors.ink,
  ),
  Collection(
    title: 'Running Collection',
    subtitle: 'Shoes built for pace',
    icon: Icons.directions_run,
    color: Color(0xFF1F2A44),
  ),
  Collection(
    title: 'Basketball Collection',
    subtitle: 'Court-ready essentials',
    icon: Icons.sports_basketball,
    color: Color(0xFF29261F),
  ),
];

const List<Seller> mockSellers = [
  Seller(
    name: 'Northmark Sports Store',
    tagline: '4.8 rating · 9.6k+ orders',
    rating: 4.8,
    description:
        'Official basketball & training gear, free returns on all orders.',
  ),
  Seller(
    name: 'Elite Sports Hub',
    tagline: '4.9 rating · 12k+ orders',
    rating: 4.9,
    description:
        'Multi-brand sports retailer with same-week dispatch on every order.',
  ),
  Seller(
    name: 'ProGear Africa',
    tagline: '4.8 rating · 8.3k+ orders',
    rating: 4.8,
    description:
        'Specialists in performance footwear and apparel, sourced direct from the brand.',
  ),
  Seller(
    name: 'CourtSide Store',
    tagline: '4.7 rating · 5.1k+ orders',
    rating: 4.7,
    description:
        'Your local stop for racket sports, running gear, and everyday training kit.',
  ),
];

/// Deterministically assigns a seller to a product for the detail page's
/// "Sold by" card — a stand-in for real seller/listing data.
Seller sellerForProduct(Product product) =>
    mockSellers[product.id.hashCode.abs() % mockSellers.length];

/// Star-rating distribution (5★ → 1★, as percentages) shown on the
/// product detail page's ratings breakdown.
const List<int> ratingBreakdown = [62, 24, 8, 4, 2];

const List<Review> mockReviews = [
  Review(
    name: 'Kwame A.',
    rating: 5,
    text:
        'Great quality and arrived faster than expected — exactly as described.',
  ),
  Review(
    name: 'Ama S.',
    rating: 4,
    text:
        'Good value for the price. Sizing runs slightly small, so consider ordering one size up.',
  ),
  Review(
    name: 'Kofi B.',
    rating: 5,
    text:
        'Been using it for a month now and it still looks brand new. Worth it.',
  ),
  Review(
    name: 'Efua N.',
    rating: 4,
    text: 'Delivery was quick and the seller kept me updated the whole way.',
  ),
];

const List<String> productSizes = ['S', 'M', 'L', 'XL'];

const List<String> mockRecentSearches = [
  'Football boots',
  'Running shoes',
  'Gym gloves',
];
const List<String> mockPopularSearches = [
  'Jerseys',
  'Basketball',
  'Yoga mat',
  'Dumbbells',
  'Tennis racket',
];
