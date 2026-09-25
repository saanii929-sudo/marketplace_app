import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

const _starOrder = [5, 4, 3, 2, 1];

/// `GET riders/reviews/summary/` and `GET riders/reviews/`.
class RiderRatingsScreen extends ConsumerWidget {
  const RiderRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(riderReviewSummaryProvider);
    final reviewsAsync = ref.watch(riderReviewsProvider);

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
                Text('Ratings & reviews', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            summaryAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.lg),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your ratings.',
                onRetry: () => ref.invalidate(riderReviewSummaryProvider),
              ),
              data: (summary) => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(summary.average.toStringAsFixed(1), style: AppTypography.display),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      children: [
                        for (final stars in _starOrder) ...[
                          _BreakdownBar(stars: stars, percent: summary.breakdown[stars] ?? 0),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            reviewsAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    const ShimmerBox(width: double.infinity, height: 64, borderRadius: AppRadius.sm),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your reviews.',
                onRetry: () => ref.invalidate(riderReviewsProvider),
              ),
              data: (reviews) => reviews.isEmpty
                  ? Text('No reviews yet.', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500))
                  : Column(
                      children: [
                        for (final review in reviews) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.reviewerName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    for (var i = 0; i < 5; i++)
                                      Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: i < review.rating ? AppColors.warning : AppColors.neutral200,
                                      ),
                                  ],
                                ),
                                if (review.comment.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(review.comment, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
                                ],
                              ],
                            ),
                          ),
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

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.stars, required this.percent});
  final int stars;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text('$stars★', style: AppTypography.caption)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.neutral100,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 32, child: Text('$percent%', style: AppTypography.caption, textAlign: TextAlign.end)),
      ],
    );
  }
}
