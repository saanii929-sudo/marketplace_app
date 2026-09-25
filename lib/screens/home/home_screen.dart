import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/category.dart';
import '../../features/discovery/discovery.dart';
import '../../features/discovery/discovery_controllers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/home/brand_strip.dart';
import '../../widgets/home/category_rail.dart';
import '../../widgets/home/countdown_timer.dart';
import '../../widgets/home/flash_deal_card.dart';
import '../../widgets/home/hero_carousel.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/product_rail.dart';
import '../../widgets/home/search_bar_field.dart';
import '../../widgets/home/seller_promo_row.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/states/shimmer_box.dart';
import 'send_package_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onCategoryTap});

  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(discoveryHomeProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedProvider);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFFF6F4EE),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const HomeHeader(),
            const SizedBox(height: AppSpacing.md),
            const SearchBarField(),
            const SizedBox(height: AppSpacing.lg),
            ResponsiveCenter(
              maxWidth: 720,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  homeAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: ShimmerBox(width: double.infinity, height: 190, borderRadius: AppRadius.xl),
                    ),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (home) => HeroCarousel(banners: home.banners),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _SendPackageBanner(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const _SectionTitle('Categories'),
                  const SizedBox(height: AppSpacing.md),
                  homeAsync.when(
                    loading: () => const _CategoryRailShimmer(),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (home) => CategoryRail(categories: home.categories, onCategoryTap: onCategoryTap),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Flash deals'),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (home) =>
                        home.flashDeals.isEmpty ? const SizedBox.shrink() : _FlashDealsSection(deals: home.flashDeals),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Trending Now'),
                    error: (error, _) => const ProductRail(title: 'Trending Now', products: []),
                    data: (home) =>
                        ProductRail(title: 'Trending Now', products: home.trending.map((p) => p.toProduct()).toList()),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Best Sellers'),
                    error: (error, _) => const ProductRail(title: 'Best Sellers', products: []),
                    data: (home) =>
                        ProductRail(title: 'Best Sellers', products: home.popular.map((p) => p.toProduct()).toList()),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'New Arrivals'),
                    error: (error, _) => const ProductRail(title: 'New Arrivals', products: []),
                    data: (home) =>
                        ProductRail(title: 'New Arrivals', products: home.featured.map((p) => p.toProduct()).toList()),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Recommended For You'),
                    error: (error, _) => const ProductRail(title: 'Recommended For You', products: []),
                    data: (home) => ProductRail(
                      title: 'Recommended',
                      products: home.recommended.map((p) => p.toProduct()).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Shop by Brand'),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (home) => home.brands.isEmpty ? const SizedBox.shrink() : BrandStrip(brands: home.brands),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  recentlyViewedAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Recently Viewed'),
                    error: (error, _) => const ProductRail(title: 'Recently Viewed', products: []),
                    data: (entries) => ProductRail(
                      title: 'Recently Viewed',
                      products: entries.map((e) => e.product.toProduct()).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  homeAsync.when(
                    loading: () => const ProductRailShimmer(title: 'Seller Spotlight'),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (home) =>
                        home.featuredSellers.isEmpty ? const SizedBox.shrink() : SellerPromoRow(sellers: home.featuredSellers),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendPackageBanner extends StatelessWidget {
  const _SendPackageBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SendPackageScreen())),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.neutral700, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send a package',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Same-day courier for parcels & documents',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(title, style: AppTypography.h1),
        ],
      ),
    );
  }
}

class _CategoryRailShimmer extends StatelessWidget {
  const _CategoryRailShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            const ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.lg),
          ],
        ],
      ),
    );
  }
}

class _FlashDealsSection extends StatelessWidget {
  const _FlashDealsSection({required this.deals});
  final List<DiscoveryFlashDeal> deals;

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
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Flash deals', style: AppTypography.h3),
                ],
              ),
              if (deals.isNotEmpty) CountdownPill(duration: deals.first.endsIn),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < deals.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                FlashDealCard(deal: deals[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
