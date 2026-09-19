import 'package:flutter/material.dart';

import '../../features/catalog/product.dart';
import '../../screens/home/brand_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Horizontal "Shop by Brand" strip — backed by `brands` from
/// `GET discovery/home/`.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key, required this.brands});

  final List<CatalogBrand> brands;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Shop by Brand', style: AppTypography.h3),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < brands.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _BrandChip(brand: brands[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});
  final CatalogBrand brand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BrandScreen(slug: brand.slug)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(brand.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
