import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/discovery/discovery.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/home/product_detail_screen.dart';
import '../badges/app_badge.dart';
import '../cards/app_card.dart';
import 'countdown_timer.dart';
import 'network_image_box.dart';

class FlashDealCard extends StatelessWidget {
  const FlashDealCard({super.key, required this.deal});

  final DiscoveryFlashDeal deal;

  @override
  Widget build(BuildContext context) {
    final product = deal.product.toProduct();
    // The flash-sale price can differ from the product's own listed price,
    // so the discount badge is computed against the deal price rather than
    // the product's own precomputed discount_percent.
    final originalForBadge = deal.product.originalPrice ?? deal.product.price;
    final discount = originalForBadge > 0
        ? (((originalForBadge - deal.dealPrice) / originalForBadge) * 100).round()
        : null;

    return SizedBox(
      width: 180,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.40,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkImageBox(
                      url: product.imageUrl,
                      fallbackIcon: product.icon,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  if (discount != null && discount > 0)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: AppBadge(
                        label: '-$discount%',
                        tone: AppBadgeTone.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formatPrice(deal.dealPrice),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (deal.product.originalPrice != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatPrice(deal.product.originalPrice!),
                    style: AppTypography.caption.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: deal.remainingFraction,
                minHeight: 5,
                backgroundColor: AppColors.neutral100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Only ${deal.stockQty} left',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 6),
            CountdownTimer(duration: deal.endsIn),
          ],
        ),
      ),
    );
  }
}
