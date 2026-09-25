import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/orders/order.dart' show OrderStatusEvent, humanizeStatus;
import '../../features/parcels/parcel_models.dart';
import '../../features/parcels/parcels_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// Parcel tracking — `GET /parcels/{id}/tracking/`'s response body isn't
/// documented, so [ParcelTracking] is parsed defensively; if it (or its
/// `status_history`) comes back empty, this just falls back to the
/// parcel's own `status` field from the list/create response instead of
/// showing nothing.
class PackageDetailScreen extends ConsumerStatefulWidget {
  const PackageDetailScreen({super.key, required this.parcelId});

  final int parcelId;

  @override
  ConsumerState<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  // No "already rated" signal exists on the parcel/tracking response, so
  // this only tracks it for the current app session rather than forever.
  bool _rated = false;

  int get parcelId => widget.parcelId;

  Future<void> _rateRider(BuildContext context, int tripId) async {
    var stars = 5;
    final commentController = TextEditingController();
    final submitted = await AppModal.show<bool>(
      context,
      title: 'Rate your rider',
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setModalState(() => stars = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i <= stars ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Comment (optional)', controller: commentController, hint: 'How was your delivery?'),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Submit rating', onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;
    try {
      await ref.read(parcelsApiProvider).rateRider(tripId, stars: stars, comment: commentController.text.trim());
      if (!context.mounted) return;
      setState(() => _rated = true);
      AppToast.show(context, 'Thanks for your feedback!', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t submit your rating. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppModal.confirm(
      context,
      title: 'Cancel this package?',
      message: 'This will cancel the courier request. This can\'t be undone.',
      confirmLabel: 'Cancel package',
    );
    if (confirmed != true) return;
    try {
      await ref.read(parcelsApiProvider).cancel(parcelId);
      ref.invalidate(parcelsProvider);
      ref.invalidate(parcelTrackingProvider(parcelId));
      if (context.mounted) AppToast.show(context, 'Package cancelled', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t cancel this package. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcelsAsync = ref.watch(parcelsProvider);
    final trackingAsync = ref.watch(parcelTrackingProvider(parcelId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: parcelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => Center(
            child: ErrorState(
              title: 'Something went wrong',
              message: error is ApiException ? error.message : 'Couldn\'t load this package.',
              onRetry: () => ref.invalidate(parcelsProvider),
            ),
          ),
          data: (parcels) {
            final matches = parcels.where((p) => p.id == parcelId);
            final parcel = matches.isEmpty ? null : matches.first;
            if (parcel == null) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Package not found', style: AppTypography.h3),
                  ],
                ),
              );
            }

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
                        Text('Package #${parcel.id}', style: AppTypography.h2),
                        Text(_formatDate(parcel.createdAt), style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                      ],
                    ),
                    const Spacer(),
                    AppBadge(
                      label: humanizeStatus(parcel.status),
                      tone: parcel.isCancelled
                          ? AppBadgeTone.error
                          : parcel.isDelivered
                          ? AppBadgeTone.success
                          : AppBadgeTone.accent,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                trackingAsync.when(
                  loading: () => const ShimmerBox(width: double.infinity, height: 120, borderRadius: AppRadius.lg),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (tracking) => tracking == null || tracking.statusHistory.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _ParcelTimeline(history: tracking.statusHistory),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('PACKAGE DETAILS', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Recipient', value: parcel.recipientName),
                      _DetailRow(label: 'From', value: '${parcel.pickupLine1}, ${parcel.pickupCity}'),
                      _DetailRow(label: 'To', value: '${parcel.dropoffLine1}, ${parcel.dropoffCity}'),
                      _DetailRow(label: 'Size', value: _capitalize(parcel.packageSize)),
                      if (parcel.declaredValue != null)
                        _DetailRow(label: 'Declared value', value: formatPrice(parcel.declaredValue!)),
                      _DetailRow(label: 'Price', value: formatPrice(parcel.price)),
                    ],
                  ),
                ),
                if (parcel.isDelivered && !_rated && trackingAsync.value?.tripId != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Rate your rider',
                    icon: Icons.star_border_rounded,
                    onPressed: () => _rateRider(context, trackingAsync.value!.tripId!),
                  ),
                ],
                if (!parcel.isCancelled && !parcel.isDelivered) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Cancel package',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _cancel(context, ref),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ParcelTimeline extends StatelessWidget {
  const _ParcelTimeline({required this.history});
  final List<OrderStatusEvent> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineStep(event: history[i], isActive: i == history.length - 1, isLast: i == history.length - 1),
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
                    Text(_formatDate(event.createdAt), style: AppTypography.caption.copyWith(color: AppColors.neutral400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
