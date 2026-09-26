import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/navigation/segmented_tabs.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'rider_active_delivery_screen.dart';

class RiderDeliveriesScreen extends ConsumerStatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  ConsumerState<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends ConsumerState<RiderDeliveriesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Text('Deliveries', style: AppTypography.h2),
            Text('Your trip history and active delivery', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: AppSpacing.lg),
            SegmentedTabs(labels: const ['Active', 'History'], selectedIndex: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: AppSpacing.lg),
            if (_tab == 0) _buildActive(context) else _buildHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActive(BuildContext context) {
    final activeAsync = ref.watch(riderActiveDeliveryProvider);
    return activeAsync.when(
      loading: () => const ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.lg),
      error: (error, _) => ErrorState(
        title: 'Something went wrong',
        message: error is ApiException ? error.message : 'Couldn\'t load your active delivery.',
        onRetry: () => ref.invalidate(riderActiveDeliveryProvider),
      ),
      data: (delivery) => delivery == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No active delivery. Go online from Home to pick one up.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => RiderActiveDeliveryScreen(delivery: delivery))),
              child: _DeliveryCard(delivery: delivery),
            ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final deliveriesAsync = ref.watch(riderDeliveriesProvider);
    return deliveriesAsync.when(
      loading: () => Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const ShimmerBox(width: double.infinity, height: 128, borderRadius: AppRadius.lg),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
      error: (error, _) => ErrorState(
        title: 'Something went wrong',
        message: error is ApiException ? error.message : 'Couldn\'t load your deliveries.',
        onRetry: () => ref.invalidate(riderDeliveriesProvider),
      ),
      data: (deliveries) => deliveries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text('No deliveries yet.', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
              ),
            )
          : Column(
              children: [
                for (final delivery in deliveries) ...[
                  _DeliveryCard(delivery: delivery),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});
  final RiderDelivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                delivery.reference.isEmpty ? '#${delivery.id}' : delivery.reference,
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                formatPrice(delivery.amount),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: delivery.isCancelled ? AppColors.neutral400 : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(_formatDate(delivery.completedAt), style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(
            '${delivery.pickupLabel} → ${delivery.dropoffAddress}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                label: delivery.isCancelled ? 'Cancelled' : (delivery.isDelivered ? 'Delivered' : 'In progress'),
                tone: delivery.isCancelled
                    ? AppBadgeTone.error
                    : (delivery.isDelivered ? AppBadgeTone.success : AppBadgeTone.accent),
              ),
              if (delivery.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(delivery.rating!.toStringAsFixed(1), style: AppTypography.bodyMedium),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  if (isToday) return 'Today, $time';
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  if (isYesterday) return 'Yesterday, $time';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, $time';
}
