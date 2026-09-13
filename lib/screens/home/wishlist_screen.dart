import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/cart/cart_controller.dart';
import '../../features/wishlist/wishlist.dart';
import '../../features/wishlist/wishlist_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// Wishlist tab — backed by `GET /wishlist/`; add/remove both go through
/// the same `POST /wishlist/toggle/` endpoint.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key, required this.onStartShopping});

  final VoidCallback onStartShopping;

  Future<void> _remove(BuildContext context, WidgetRef ref, WishlistEntry entry) async {
    try {
      await ref.read(wishlistControllerProvider.notifier).toggle(entry.product.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your wishlist.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _moveToCart(BuildContext context, WidgetRef ref, WishlistEntry entry) async {
    try {
      await ref.read(cartControllerProvider.notifier).addItem(productId: entry.product.id, qty: 1);
      await ref.read(wishlistControllerProvider.notifier).toggle(entry.product.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Moved to cart', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t move that to your cart.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wishlist', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text(
                    wishlistAsync.value != null
                        ? '${wishlistAsync.value!.length} item${wishlistAsync.value!.length == 1 ? '' : 's'}'
                        : ' ',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: wishlistAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ProductGridShimmer(),
                ),
                error: (error, _) => ErrorState(
                  title: 'Something went wrong',
                  message: error is ApiException ? error.message : 'Couldn\'t load your wishlist.',
                  onRetry: () => ref.read(wishlistControllerProvider.notifier).refresh(),
                ),
                data: (entries) => entries.isEmpty
                    ? EmptyState(
                        icon: Icons.favorite_border,
                        title: 'Your wishlist is empty',
                        message: 'Tap the heart on any product to save it here for later.',
                        actionLabel: 'Start shopping',
                        onAction: onStartShopping,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
                            return Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: [
                                for (final entry in entries)
                                  _WishlistTile(
                                    entry: entry,
                                    width: tileWidth,
                                    onRemove: () => _remove(context, ref, entry),
                                    onMoveToCart: () => _moveToCart(context, ref, entry),
                                  ),
                              ],
                            );
                          },
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

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.entry, required this.width, required this.onRemove, required this.onMoveToCart});
  final WishlistEntry entry;
  final double width;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    final discount = product.originalPrice != null && product.originalPrice! > product.price
        ? (((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()
        : null;

    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.40,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkImageBox(
                      url: product.primaryImage,
                      fallbackIcon: Icons.shopping_bag_outlined,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: AppBadge(label: '-$discount%', tone: AppBadgeTone.error),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 16, color: AppColors.neutral600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(product.brandName, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              product.name,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatPrice(product.price),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
                if (product.originalPrice != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatPrice(product.originalPrice!),
                    style: AppTypography.caption.copyWith(decoration: TextDecoration.lineThrough),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMoveToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                child: Text(
                  'Move to cart',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
