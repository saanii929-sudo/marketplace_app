import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/cart/cart.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/catalog/catalog_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, required this.onStartShopping});

  final VoidCallback onStartShopping;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    try {
      await ref.read(cartControllerProvider.notifier).applyCoupon(code);
      if (!mounted) return;
      final cart = ref.read(cartControllerProvider).value;
      if (cart?.couponError != null && cart!.couponError!.isNotEmpty) {
        AppToast.show(context, cart.couponError!, tone: AppToastTone.error);
      } else {
        AppToast.show(context, 'Promo code applied', tone: AppToastTone.success);
        _promoController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t apply that code.', tone: AppToastTone.error);
    }
  }

  Future<void> _removePromo() async {
    try {
      await ref.read(cartControllerProvider.notifier).removeCoupon();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t remove that code.', tone: AppToastTone.error);
    }
  }

  Future<void> _updateQty(CartItem item, int qty) async {
    try {
      if (qty <= 0) {
        await ref.read(cartControllerProvider.notifier).removeItem(item.id);
      } else {
        await ref.read(cartControllerProvider.notifier).updateQty(item.id, qty);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t update your cart.', tone: AppToastTone.error);
    }
  }

  void _checkout() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartControllerProvider);

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
                  Text('Your Cart', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text(
                    cartAsync.value != null
                        ? '${cartAsync.value!.itemCount} item${cartAsync.value!.itemCount == 1 ? '' : 's'}'
                        : ' ',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cartAsync.when(
                loading: () => const Padding(padding: EdgeInsets.only(top: AppSpacing.md), child: CartLinesShimmer()),
                error: (error, _) => ErrorState(
                  title: 'Something went wrong',
                  message: error is ApiException ? error.message : 'Couldn\'t load your cart.',
                  onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
                ),
                data: (cart) => cart.items.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Your cart is empty',
                        message: 'Gear you add will show up here — start browsing to find your next kit.',
                        actionLabel: 'Start shopping',
                        onAction: widget.onStartShopping,
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        children: [
                          for (final item in cart.items) ...[
                            _CartLineTile(item: item, onQtyChanged: _updateQty),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  style: AppTypography.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Promo code',
                                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral400),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: _applyPromo,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  side: const BorderSide(color: AppColors.border, width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            child: Column(
                              children: [
                                _SummaryRow(label: 'Subtotal', value: formatPrice(cart.subtotal)),
                                if (cart.couponCode != null && cart.couponCode!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Promo (${cart.couponCode})',
                                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          GestureDetector(
                                            onTap: _removePromo,
                                            child: Text(
                                              'Remove',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '-${formatPrice(cart.discountAmount)}',
                                        style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                _SummaryRow(
                                  label: 'Delivery',
                                  value: cart.deliveryFee == 0 ? 'Free' : formatPrice(cart.deliveryFee),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Divider(),
                                const SizedBox(height: AppSpacing.md),
                                _SummaryRow(label: 'Total', value: formatPrice(cart.total), bold: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(label: 'Checkout · ${formatPrice(cart.total)}', onPressed: _checkout),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.item, required this.onQtyChanged});
  final CartItem item;
  final void Function(CartItem item, int qty) onQtyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = item.productSlug.isNotEmpty ? ref.watch(productDetailProvider(item.productSlug)) : null;
    final imageUrl = detailAsync?.value?.images.isNotEmpty == true ? detailAsync!.value!.images.first.url : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: detailAsync != null && detailAsync.isLoading
                ? const ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.md)
                : NetworkImageBox(
                    url: imageUrl,
                    fallbackIcon: Icons.shopping_bag_outlined,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (item.variantLabel != null && item.variantLabel!.isNotEmpty)
                            Text(item.variantLabel!, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onQtyChanged(item, 0),
                      child: const Icon(Icons.close, size: 18, color: AppColors.neutral400),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _QtyButton(icon: Icons.remove, onTap: () => onQtyChanged(item, item.qty - 1)),
                    SizedBox(
                      width: 32,
                      child: Text('${item.qty}', textAlign: TextAlign.center, style: AppTypography.bodyMedium),
                    ),
                    _QtyButton(icon: Icons.add, onTap: () => onQtyChanged(item, item.qty + 1)),
                    const Spacer(),
                    Text(
                      formatPrice(item.lineTotal),
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.h3 : AppTypography.bodyMedium.copyWith(color: AppColors.neutral600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold ? AppTypography.h3 : AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
        Text(value, style: style),
      ],
    );
  }
}
