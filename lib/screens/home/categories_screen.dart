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

const _sidebarWidth = 104.0;

/// Categories tab: a subcategory chip filter plus a grid of the matching
/// products at full screen width, with the category picker as a
/// hamburger-triggered overlay (not an inline column, which was cramping
/// the grid down to barely-usable tiles) — backed by
/// `GET /catalog/categories/` and the resource-nested
/// `GET /catalog/categories/{slug}/products/`, which real-filters by both
/// category and subcategory server-side.
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

  /// `null` means the "All" chip — the subcategory filter is otherwise
  /// keyed by slug (needed for the query param, not just display).
  String? _selectedSubcategorySlug;

  bool _sidebarOpen = false;

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
        _selectedSubcategorySlug = null;
      });
    }
  }

  void _selectCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategorySlug = null;
      // Close the overlay right away once a choice is made, so the grid
      // is immediately visible again.
      _sidebarOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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
                  final productsAsync = ref.watch(
                    categoryProductsProvider((selected.slug, _selectedSubcategorySlug)),
                  );

                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: GestureDetector(
                              onTap: () => setState(() => _sidebarOpen = true),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(Icons.menu, size: 18, color: AppColors.ink),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    selected.name,
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: selected.subcategories.length + 1,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final label = i == 0 ? 'All' : selected.subcategories[i - 1].name;
                                final slug = i == 0 ? null : selected.subcategories[i - 1].slug;
                                final chipSelected = slug == _selectedSubcategorySlug;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSubcategorySlug = slug),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: chipSelected ? AppColors.ink : AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: chipSelected ? AppColors.ink : AppColors.border),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      label,
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
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: ProductGridShimmer(),
                              ),
                              error: (error, _) => Center(
                                child: Text(
                                  'Couldn\'t load products.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                                ),
                              ),
                              data: (products) {
                                if (products.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No products in this category yet',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                                    ),
                                  );
                                }
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
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
                                          for (final product in products)
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
                      IgnorePointer(
                        ignoring: !_sidebarOpen,
                        child: AnimatedOpacity(
                          opacity: _sidebarOpen ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: GestureDetector(
                            onTap: () => setState(() => _sidebarOpen = false),
                            child: Container(color: Colors.black.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: _sidebarOpen ? 0 : -_sidebarWidth,
                        top: 0,
                        bottom: 0,
                        width: _sidebarWidth,
                        child: Material(
                          elevation: 8,
                          color: AppColors.surface,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            itemCount: categories.length,
                            itemBuilder: (context, i) {
                              final category = categories[i];
                              final isSelected = category.id == selected.id;
                              return GestureDetector(
                                onTap: () => _selectCategory(category.id),
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
