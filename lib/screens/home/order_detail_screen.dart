import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart';
import '../../features/orders/order.dart';
import '../../features/orders/orders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// A just-placed order snapshot for the checkout confirmation flow — there
/// is no real order behind it yet (see the missing-delivery-methods gap in
/// the Phase 3 plan, which blocks real order placement), so this renders
/// directly instead of fetching from the API.
class LocalOrderPreview {
  const LocalOrderPreview({required this.items, required this.total});
  final List<Product> items;
  final double total;
}

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderNumber, this.localPreview});

  final String orderNumber;
  final LocalOrderPreview? localPreview;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(ordersApiProvider).cancel(orderNumber);
      ref.invalidate(orderDetailProvider(orderNumber));
      ref.invalidate(orderTrackingProvider(orderNumber));
      ref.invalidate(ordersProvider);
      if (!context.mounted) return;
      AppToast.show(context, 'Order cancelled', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t cancel this order.', tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: localPreview != null
            ? _LocalPreviewBody(orderNumber: orderNumber, preview: localPreview!)
            : ref
                  .watch(orderDetailProvider(orderNumber))
                  .when(
                    loading: () => const _DetailShimmer(),
                    error: (error, _) => ErrorState(
                      title: 'Something went wrong',
                      message: error is ApiException ? error.message : 'Couldn\'t load this order.',
                      onRetry: () => ref.invalidate(orderDetailProvider(orderNumber)),
                    ),
                    data: (order) => _RealOrderBody(order: order, onCancel: () => _cancel(context, ref)),
                  ),
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: AppSpacing.md),
              ShimmerBox(width: 120, height: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(width: double.infinity, height: 100, borderRadius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(width: double.infinity, height: 180, borderRadius: AppRadius.lg),
        ],
      ),
    );
  }
}

class _RealOrderBody extends StatelessWidget {
  const _RealOrderBody({required this.order, required this.onCancel});
  final OrderDetail order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.isCancelled;
    final isDelivered = order.isDelivered;
    final tone = isDelivered
        ? AppBadgeTone.success
        : isCancelled
        ? AppBadgeTone.error
        : AppBadgeTone.neutral;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: [
        Row(
          children: [
            AppBackButton(onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber, style: AppTypography.h2),
                if (order.placedAt != null)
                  Text(
                    _formatDate(order.placedAt!),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isCancelled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: const Color(0x1AE5342B), borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Text(
              'This order was cancelled. Any payment made has been refunded to your original payment method.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBadge(label: humanizeStatus(order.status), tone: tone),
                if (order.deliveryMethod != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Estimated delivery: ${order.deliveryMethod!.etaDaysMin}–${order.deliveryMethod!.etaDaysMax} business days',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Consumer(
            builder: (context, ref, _) => ref
                .watch(orderTrackingProvider(order.orderNumber))
                .when(
                  loading: () => const ShimmerBox(width: double.infinity, height: 120, borderRadius: AppRadius.lg),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (tracking) => tracking.statusHistory.isEmpty
                      ? const SizedBox.shrink()
                      : AppCard(child: _OrderTimeline(history: tracking.statusHistory)),
                ),
          ),
          if (!isDelivered) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Cancel order', variant: AppButtonVariant.secondary, onPressed: onCancel),
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Items in this order', style: AppTypography.label.copyWith(color: AppColors.neutral500)),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in order.items) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.neutral400),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Qty ${item.qty}', style: AppTypography.caption),
                          ],
                        ),
                      ),
                      Text(formatPrice(item.lineTotal), style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ],
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(formatPrice(order.total), style: AppTypography.h3),
            ],
          ),
        ),
        if (!isCancelled) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Delivering to', style: AppTypography.label.copyWith(color: AppColors.neutral500)),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.deliveryRecipientName.isEmpty ? 'Saved address' : order.deliveryRecipientName,
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  order.deliveryAddress.isEmpty ? 'See your saved addresses for full delivery details.' : order.deliveryAddress,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Need help with this order?',
            variant: AppButtonVariant.secondary,
            onPressed: () => AppToast.show(context, 'Support chat coming soon'),
          ),
        ],
      ],
    );
  }
}

class _LocalPreviewBody extends StatelessWidget {
  const _LocalPreviewBody({required this.orderNumber, required this.preview});
  final String orderNumber;
  final LocalOrderPreview preview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: [
        Row(
          children: [
            AppBackButton(onTap: () => Navigator.of(context).pop()),
            const SizedBox(width: AppSpacing.md),
            Text(orderNumber, style: AppTypography.h2),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBadge(label: 'Processing', tone: AppBadgeTone.neutral),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Estimated delivery: 2–4 business days',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: const [
              _LocalTimelineStep(title: 'Order placed', subtitle: "We've received your order", completed: true, isLast: false),
              _LocalTimelineStep(title: 'Processing', subtitle: 'Seller is preparing your items', completed: false, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Items in this order', style: AppTypography.label.copyWith(color: AppColors.neutral500)),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final item in preview.items) ...[
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: NetworkImageBox(
                        url: item.imageUrl,
                        fallbackIcon: item.icon,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(formatPrice(preview.total), style: AppTypography.h3),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Delivering to', style: AppTypography.label.copyWith(color: AppColors.neutral500)),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved address', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                'See your saved addresses for full delivery details.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalTimelineStep extends StatelessWidget {
  const _LocalTimelineStep({required this.title, required this.subtitle, required this.completed, required this.isLast});
  final String title;
  final String subtitle;
  final bool completed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final circleColor = completed ? AppColors.success : AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: completed
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : const Text('2', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.success)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the real `status_history` from `GET
/// /orders/{order_number}/tracking/` — unlike the old fixed 5-step mock
/// timeline, this only shows transitions that have actually happened (no
/// guessed "upcoming" steps), with the most recent one highlighted.
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.history});
  final List<OrderStatusEvent> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineStep(
            event: history[i],
            isActive: i == history.length - 1,
            isLast: i == history.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.event, required this.isActive, required this.isLast});
  final OrderStatusEvent event;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final circleColor = isActive ? AppColors.primary : AppColors.success;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: isActive
                    ? const Icon(Icons.radio_button_checked, size: 14, color: AppColors.white)
                    : const Icon(Icons.check, size: 16, color: AppColors.white),
              ),
              if (!isLast) const Expanded(child: SizedBox(width: 2)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(humanizeStatus(event.status), style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  if (event.note.isNotEmpty)
                    Text(event.note, style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500)),
                  if (event.createdAt != null)
                    Text(_formatDate(event.createdAt!), style: AppTypography.caption.copyWith(color: AppColors.neutral400)),
                ],
              ),
            ),
          ),
        ],
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
