import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/wishlist/wishlist_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/home/product_detail_screen.dart';
import '../badges/app_badge.dart';
import '../cards/app_card.dart';
import '../overlays/app_toast.dart';
import 'network_image_box.dart';

class ProductTile extends ConsumerWidget {
  const ProductTile({super.key, required this.product, this.width = 168});

  final Product product;
  final double width;

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final productId = int.tryParse(product.id);
    if (productId == null) return;
    try {
      await ref.read(cartControllerProvider.notifier).addItem(productId: productId, qty: 1);
      if (!context.mounted) return;
      AppToast.show(context, 'Added to cart', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t add that to your cart.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _toggleWishlist(BuildContext context, WidgetRef ref) async {
    final productId = int.tryParse(product.id);
    if (productId == null) return;
    try {
      await ref.read(wishlistControllerProvider.notifier).toggle(productId);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your wishlist.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = int.tryParse(product.id);
    final wishlisted = ref.watch(wishlistControllerProvider).value?.has(productId ?? -1) ?? false;
    final inCart = ref.watch(cartControllerProvider).value?.hasProduct(productId ?? -1) ?? false;
    final discount = product.discountPercent;

    return SizedBox(
      width: width,
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
                  if (discount != null || product.badgeLabel != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: discount != null
                          ? AppBadge(
                              label: '-$discount%',
                              tone: AppBadgeTone.error,
                            )
                          : AppBadge(
                              label: product.badgeLabel!,
                              tone: AppBadgeTone.accent,
                            ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          wishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: wishlisted
                              ? AppColors.primary
                              : AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              product.brand,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
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
                const SizedBox(width: 2),
                Text('(${product.reviewCount})', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatPrice(product.price),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (product.originalPrice != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatPrice(product.originalPrice!),
                    style: AppTypography.caption.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: inCart ? null : () => _addToCart(context, ref),
                icon: Icon(
                  inCart ? Icons.check : Icons.add_shopping_cart_outlined,
                  size: 16,
                ),
                label: Text(
                  inCart ? 'In cart' : 'Add to cart',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: inCart ? AppColors.success : AppColors.ink,
                  side: BorderSide(
                    color: inCart ? AppColors.success : AppColors.border,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
