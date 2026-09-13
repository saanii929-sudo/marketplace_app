import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../overlays/app_toast.dart';
import 'product_tile.dart';

/// A titled horizontal row of product tiles with a "See all" action.
/// Reused for Trending Now, Best Sellers, New Arrivals, Recommended For You
/// and Recently Viewed.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.h3),
              GestureDetector(
                onTap: () => AppToast.show(context, 'More $title coming soon'),
                child: Text(
                  'See all',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < products.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                ProductTile(product: products[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
