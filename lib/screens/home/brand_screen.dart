import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/home/product_tile.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

class BrandScreen extends ConsumerWidget {
  const BrandScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandAsync = ref.watch(brandProfileProvider(slug));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: brandAsync.when(
          loading: () => const _BrandProfileShimmer(),
          error: (error, _) => ErrorState(
            title: 'Something went wrong',
            message: error is ApiException ? error.message : 'Couldn\'t load this brand.',
            onRetry: () => ref.invalidate(brandProfileProvider(slug)),
          ),
          data: (brand) => ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: NetworkImageBox(
                      url: brand.logo,
                      fallbackIcon: Icons.sell_outlined,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(brand.name, style: AppTypography.h2),
                        const SizedBox(height: 4),
                        Text(
                          '${brand.productCount} product${brand.productCount == 1 ? '' : 's'}',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              Text('Products', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              if (brand.products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No products listed yet.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final product in brand.products)
                          ProductTile(product: product.toProduct(), width: tileWidth),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandProfileShimmer extends StatelessWidget {
  const _BrandProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBackButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.lg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 20),
                    const SizedBox(height: AppSpacing.sm),
                    ShimmerBox(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const ProductGridShimmer(),
        ],
      ),
    );
  }
}
