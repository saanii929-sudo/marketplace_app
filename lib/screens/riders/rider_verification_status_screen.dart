import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/order.dart' show humanizeStatus;
import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/error_state.dart';
import 'rider_login_screen.dart';

/// The real screen in the rider-onboarding tail: reads
/// `GET /riders/verification-status/` for the overall status, and
/// `GET riders/documents/` for the per-document breakdown if it's
/// available yet.
class RiderVerificationStatusScreen extends ConsumerWidget {
  const RiderVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(riderVerificationStatusProvider);
    final documentsAsync = ref.watch(riderDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: statusAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) => Center(
              child: ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t check your verification status.',
                onRetry: () => ref.invalidate(riderVerificationStatusProvider),
              ),
            ),
            data: (status) => ListView(
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(color: Color(0x1AF5A623), shape: BoxShape.circle),
                    child: const Icon(Icons.access_time_rounded, size: 32, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  status?.isApproved == true ? 'You\'re verified!' : 'We\'re reviewing your documents',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  status != null && status.status.isNotEmpty
                      ? 'Status: ${humanizeStatus(status.status)}'
                      : 'This usually takes less than 24 hours. We\'ll notify you the moment you\'re approved to go online.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                documentsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (documents) => documents.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            for (final document in documents) ...[
                              _DocumentStatusRow(document: document),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Back to login',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  const _DocumentStatusRow({required this.document});
  final RiderDocument document;

  @override
  Widget build(BuildContext context) {
    final label = riderDocumentTypes
        .firstWhere((t) => t.$1 == document.documentType, orElse: () => (document.documentType, document.documentType))
        .$2;
    final (badgeLabel, tone) = document.isVerified
        ? ('Verified', AppBadgeTone.success)
        : document.isRejected
        ? ('Rejected', AppBadgeTone.error)
        : ('Pending', AppBadgeTone.warning);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          AppBadge(label: badgeLabel, tone: tone),
        ],
      ),
    );
  }
}
