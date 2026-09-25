import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'rider_cash_out_screen.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Earnings/wallet screen — `GET riders/earnings/summary/` and
/// `GET riders/earnings/activity/`.
class RiderEarningsScreen extends ConsumerWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(riderEarningsSummaryProvider);
    final activityAsync = ref.watch(riderEarningsActivityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Text('Earnings', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            summaryAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 300, borderRadius: AppRadius.lg),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your earnings.',
                onRetry: () => ref.invalidate(riderEarningsSummaryProvider),
              ),
              data: (summary) => _EarningsSummarySection(summary: summary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Recent activity', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            activityAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    const ShimmerBox(width: double.infinity, height: 48, borderRadius: AppRadius.sm),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your activity.',
                onRetry: () => ref.invalidate(riderEarningsActivityProvider),
              ),
              data: (activity) => activity.isEmpty
                  ? Text('No activity yet.', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500))
                  : Column(
                      children: [
                        for (final entry in activity) ...[
                          _ActivityRow(entry: entry),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Cash out',
              onPressed: (summaryAsync.value?.availableBalance ?? 0) <= 0
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderCashOutScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsSummarySection extends StatelessWidget {
  const _EarningsSummarySection({required this.summary});
  final RiderEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final maxAmount = summary.week.isEmpty ? 1.0 : summary.week.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: AppTypography.caption.copyWith(color: AppColors.neutral400, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                formatPrice(summary.availableBalance),
                style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Earnings this week', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.lg),
        if (summary.week.isNotEmpty)
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < summary.week.length && i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 96 * (summary.week[i] / maxAmount).clamp(0.05, 1.0),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(i < _weekdayLabels.length ? _weekdayLabels[i] : '', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: _StatCard(value: '${summary.totalTrips}', label: 'Total trips')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StatCard(value: formatPrice(summary.avgPerTrip), label: 'Avg per trip')),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

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
          Text(value, style: AppTypography.h3),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final RiderActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.createdAt;
    final timeLabel = time == null
        ? ''
        : '${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(entry.isCashOut ? Icons.account_balance_wallet_outlined : Icons.pedal_bike, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              if (timeLabel.isNotEmpty) Text(timeLabel, style: AppTypography.caption),
            ],
          ),
        ),
        Text(
          '${entry.isCashOut ? '-' : '+'}${formatPrice(entry.amount)}',
          style: AppTypography.bodyMedium.copyWith(
            color: entry.isCashOut ? AppColors.error : AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
