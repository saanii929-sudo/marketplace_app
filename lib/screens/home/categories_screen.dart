import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_controllers.dart';
import '../../features/catalog/product.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/home/product_tile.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// Categories tab: a sidebar of all sports and, on the right, a chip filter
/// plus a grid of the products in the selected category — backed by
/// `GET /catalog/categories/` and `GET /catalog/products/`.
///
/// The given products endpoint has no category filter query param, so the
/// grid filters the full product list client-side by category id. It also
/// has no subcategory field on list items, so the subcategory chip row
/// (built from the selected category's real subcategories) is shown for
/// reference but doesn't filter the grid — only "All" does, until a
/// subcategory-scoped endpoint exists.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key, this.initialCategoryId});

  /// Set when navigated here from Home's category rail, to deep-link
  /// straight to the tapped category.
  final int? initialCategoryId;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int? _selectedCategoryId;
  String _chip = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void didUpdateWidget(covariant CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != null && widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _selectedCategoryId = widget.initialCategoryId;
        _chip = 'All';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text(
                    'Browse all sports',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ProductGridShimmer(),
                ),
                error: (error, _) => ErrorState(
                  title: 'Something went wrong',
                  message: error is ApiException ? error.message : 'Couldn\'t load categories.',
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories yet — check back soon.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                    );
                  }
                  final selected = categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => categories.first,
                  );
                  final chips = ['All', ...selected.subcategories.map((s) => s.name)];

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: categories.length,
                          itemBuilder: (context, i) {
                            final category = categories[i];
                            final isSelected = category.id == selected.id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategoryId = category.id;
                                _chip = 'All';
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  color: isSelected ? AppColors.neutral50 : Colors.transparent,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: NetworkImageBox(
                                        url: '',
                                        fallbackIcon: iconForCategoryName(category.name),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: isSelected ? AppColors.ink : AppColors.neutral500,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 44,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                itemCount: chips.length,
                                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, i) {
                                  final chip = chips[i];
                                  final chipSelected = chip == _chip;
                                  return GestureDetector(
                                    onTap: () => setState(() => _chip = chip),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: chipSelected ? AppColors.ink : AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(color: chipSelected ? AppColors.ink : AppColors.border),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        chip,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: chipSelected ? AppColors.white : AppColors.neutral700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(
                              child: productsAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.lg, AppSpacing.xl),
                                  child: ProductGridShimmer(),
                                ),
                                error: (error, _) => Center(
                                  child: Text(
                                    'Couldn\'t load products.',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                                  ),
                                ),
                                data: (allProducts) {
                                  final filtered = allProducts.where((p) => p.categoryId == selected.id).toList();
                                  if (filtered.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No products in this category yet',
                                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                                      ),
                                    );
                                  }
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      0,
                                      AppSpacing.lg,
                                      AppSpacing.xl,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
                                        return Wrap(
                                          spacing: AppSpacing.md,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            for (final product in filtered)
                                              ProductTile(product: product.toProduct(), width: tileWidth),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
