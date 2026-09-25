import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// `GET riders/documents/` — per-document status/expiry/file.
class RiderDocumentsViewScreen extends ConsumerWidget {
  const RiderDocumentsViewScreen({super.key});

  void _viewDocument(BuildContext context, RiderDocument document, String label) {
    AppModal.show<void>(
      context,
      title: label,
      child: document.fileUrl != null && document.fileUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(
                document.fileUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: const Icon(Icons.insert_drive_file_outlined, size: 32, color: AppColors.neutral400),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(riderDocumentsProvider);

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
                    Text('Documents', style: AppTypography.h2),
                    documentsAsync.maybeWhen(
                      data: (documents) => Text(
                        documents.every((d) => d.isVerified) && documents.isNotEmpty
                            ? 'All documents verified'
                            : 'Verification status per document',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            documentsAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    const ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.lg),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your documents.',
                onRetry: () => ref.invalidate(riderDocumentsProvider),
              ),
              data: (documents) => documents.isEmpty
                  ? Text('No documents on file yet.', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500))
                  : Column(
                      children: [
                        for (final document in documents) ...[
                          _DocumentTile(document: document, onView: (label) => _viewDocument(context, document, label)),
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.onView});
  final RiderDocument document;
  final ValueChanged<String> onView;

  @override
  Widget build(BuildContext context) {
    final label = riderDocumentTypes
        .firstWhere((t) => t.$1 == document.documentType, orElse: () => (document.documentType, document.documentType))
        .$2;
    final expiry = document.expiresAt;
    final (bg, border, iconBg, icon, statusText, statusColor) = document.isRejected
        ? (const Color(0x1AE5342B), AppColors.error, AppColors.error, Icons.close, 'Rejected', AppColors.error)
        : document.isVerified
        ? (const Color(0x1A1FA855), AppColors.success, AppColors.success, Icons.check, 'Verified', AppColors.success)
        : (AppColors.neutral50, AppColors.border, AppColors.neutral200, Icons.access_time, 'Pending', AppColors.neutral600);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.label),
                Text(
                  expiry != null ? '$statusText · expires ${_formatDate(expiry)}' : statusText,
                  style: AppTypography.bodySmall.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => onView(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.year}';
}
