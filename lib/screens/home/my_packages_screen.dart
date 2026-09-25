import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/orders/order.dart' show humanizeStatus;
import '../../features/parcels/parcel_models.dart';
import '../../features/parcels/parcels_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'package_detail_screen.dart';

class MyPackagesScreen extends ConsumerWidget {
  const MyPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelsAsync = ref.watch(parcelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My packages', style: AppTypography.h2),
                    Text(
                      parcelsAsync.value != null
                          ? '${parcelsAsync.value!.length} package${parcelsAsync.value!.length == 1 ? '' : 's'} sent'
                          : 'Your sent packages',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            parcelsAsync.when(
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
                message: error is ApiException ? error.message : 'Couldn\'t load your packages.',
                onRetry: () => ref.invalidate(parcelsProvider),
              ),
              data: (parcels) => parcels.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text('No packages yet.', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                      ),
                    )
                  : Column(
                      children: [
                        for (final parcel in parcels) ...[
                          _PackageCard(
                            parcel: parcel,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PackageDetailScreen(parcelId: parcel.id)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.parcel, required this.onTap});
  final Parcel parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
                Text('#${parcel.id}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
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
            const SizedBox(height: 2),
            Text(_formatRelative(parcel.createdAt), style: AppTypography.caption),
            const SizedBox(height: 6),
            Text(
              '${parcel.pickupCity} → ${parcel.dropoffCity}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('To ${parcel.recipientName}', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                Text(formatPrice(parcel.price), style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRelative(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
