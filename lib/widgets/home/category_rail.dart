import 'package:flutter/material.dart';

import '../../features/catalog/category.dart';
import '../../features/catalog/product.dart' show iconForCategoryName;
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'network_image_box.dart';

/// Horizontally scrollable category cards — backed by the real categories
/// from `GET discovery/home/`. There's no image field on a real category,
/// so each card falls back to a sport-appropriate icon (see
/// [iconForCategoryName]) instead of a photo.
class CategoryRail extends StatelessWidget {
  const CategoryRail({super.key, required this.categories, required this.onCategoryTap});

  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            _CategoryCard(category: categories[i], onTap: () => onCategoryTap(categories[i])),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: NetworkImageBox(
                url: '',
                fallbackIcon: iconForCategoryName(category.name),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.name,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
