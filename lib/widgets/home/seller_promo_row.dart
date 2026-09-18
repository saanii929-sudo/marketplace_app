import 'package:flutter/material.dart';

import '../../features/catalog/product.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/home/seller_profile_screen.dart';
import '../badges/app_badge.dart';
import '../buttons/app_button.dart';
import '../cards/app_card.dart';

/// Horizontal row spotlighting verified sellers — backed by
/// `featured_sellers` from `GET discovery/home/`.
class SellerPromoRow extends StatelessWidget {
  const SellerPromoRow({super.key, required this.sellers});

  final List<CatalogSeller> sellers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Seller Spotlight', style: AppTypography.h3),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sellers.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                _SellerCard(seller: sellers[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});
  final CatalogSeller seller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                  child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.ink),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (seller.isVerified) const AppBadge(label: 'Verified', tone: AppBadgeTone.success),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(seller.businessName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(seller.tagline, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Visit store',
              variant: AppButtonVariant.ghost,
              expand: false,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SellerProfileScreen(slug: seller.slug)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
