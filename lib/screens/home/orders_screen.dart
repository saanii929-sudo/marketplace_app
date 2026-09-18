import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/cart/cart_controller.dart';
import '../../features/orders/order.dart';
import '../../features/orders/orders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'order_detail_screen.dart';

/// "My Orders", backed by `GET /orders/`. That list endpoint only returns
/// `order_number`/`status`/`total`/`placed_at` (no line items), so unlike
/// the old mock cards, these don't show a product-thumbnail strip.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  Future<void> _buyAgain(BuildContext context, WidgetRef ref, OrderSummary order) async {
    try {
      await ref.read(ordersApiProvider).buyAgain(order.orderNumber);
      ref.invalidate(cartControllerProvider);
      if (!context.mounted) return;
      AppToast.show(context, 'Added items back to your cart', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t add those items to your cart.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My orders', style: AppTypography.h2),
                      Text(
                        ordersAsync.value != null
                            ? '${ordersAsync.value!.length} order${ordersAsync.value!.length == 1 ? '' : 's'} placed'
                            : ' ',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      const ShimmerBox(width: double.infinity, height: 120, borderRadius: AppRadius.lg),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
                error: (error, _) => ErrorState(
                  title: 'Something went wrong',
                  message: error is ApiException ? error.message : 'Couldn\'t load your orders.',
                  onRetry: () => ref.invalidate(ordersProvider),
                ),
                data: (orders) => orders.isEmpty
                    ? Center(
                        child: Text(
                          'No orders yet — your purchases will show up here.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) =>
                            _OrderCard(order: orders[i], onBuyAgain: () => _buyAgain(context, ref, orders[i])),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onBuyAgain});
  final OrderSummary order;
  final VoidCallback onBuyAgain;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: order.orderNumber)));
  }

  @override
  Widget build(BuildContext context) {
    final tone = order.isDelivered
        ? AppBadgeTone.success
        : order.isCancelled
        ? AppBadgeTone.error
        : AppBadgeTone.neutral;

    return AppCard(
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber, style: AppTypography.h3),
                  if (order.placedAt != null)
                    Text(
                      _formatDate(order.placedAt!),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    ),
                ],
              ),
              AppBadge(label: humanizeStatus(order.status), tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatPrice(order.total), style: AppTypography.h3),
              _OrderActions(order: order, onOpenDetail: () => _openDetail(context), onBuyAgain: onBuyAgain),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order, required this.onOpenDetail, required this.onBuyAgain});
  final OrderSummary order;
  final VoidCallback onOpenDetail;
  final VoidCallback onBuyAgain;

  @override
  Widget build(BuildContext context) {
    if (order.isDelivered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniButton(label: 'Buy again', filled: false, onPressed: onBuyAgain),
          const SizedBox(width: AppSpacing.sm),
          // Reviews are per order item (see POST /reviews/'s
          // order_item_id), so this opens the order detail screen to pick
          // which item to review rather than reviewing the whole order.
          _MiniButton(label: 'Leave a review', filled: true, onPressed: onOpenDetail),
        ],
      );
    }
    if (order.isCancelled) {
      return _MiniButton(label: 'View details', filled: false, onPressed: onOpenDetail);
    }
    return _MiniButton(label: 'Track order', filled: false, onPressed: onOpenDetail);
  }
}

/// Compact pill button for inline order-card actions — smaller than
/// [AppButton], which is sized for full-width/standalone CTAs.
class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.filled, required this.onPressed});
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: filled ? AppColors.ink : AppColors.surface,
        foregroundColor: filled ? AppColors.white : AppColors.ink,
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: filled ? AppColors.white : AppColors.ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
