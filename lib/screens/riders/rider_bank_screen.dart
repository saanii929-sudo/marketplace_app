import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

/// Payout methods — `GET`/`POST riders/payout-methods/`,
/// `POST riders/payout-methods/{id}/set-default/`.
class RiderBankScreen extends ConsumerWidget {
  const RiderBankScreen({super.key});

  Future<void> _addMethod(BuildContext context, WidgetRef ref) async {
    final providerController = TextEditingController();
    final accountController = TextEditingController();
    final added = await AppModal.show<bool>(
      context,
      title: 'Add bank or MoMo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(label: 'Provider', controller: providerController, hint: 'e.g. Vodafone Cash, Fidelity Bank'),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Account / number', controller: accountController, hint: '•••• 1234'),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add',
            onPressed: () {
              if (providerController.text.trim().isEmpty || accountController.text.trim().isEmpty) return;
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (added != true || !context.mounted) return;
    try {
      await ref
          .read(ridersApiProvider)
          .addPayoutMethod(provider: providerController.text.trim(), accountNumber: accountController.text.trim());
      ref.invalidate(riderPayoutMethodsProvider);
      if (context.mounted) AppToast.show(context, 'Payout method added', tone: AppToastTone.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t add that payout method. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(ridersApiProvider).setDefaultPayoutMethod(id);
      ref.invalidate(riderPayoutMethodsProvider);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your default payout method.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(riderPayoutMethodsProvider);

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
                    Text('Bank & MoMo', style: AppTypography.h2),
                    Text(
                      'Where your earnings are paid out',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            methodsAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 140, borderRadius: AppRadius.lg),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your payout methods.',
                onRetry: () => ref.invalidate(riderPayoutMethodsProvider),
              ),
              data: (methods) => Column(
                children: [
                  for (final method in methods) ...[
                    _PayoutRow(
                      title: method.title,
                      subtitle: method.subtitle,
                      isDefault: method.isDefault,
                      onSetDefault: () => _setDefault(context, ref, method.id),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _addMethod(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: Text('+ Add bank or MoMo', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.title, required this.subtitle, required this.isDefault, required this.onSetDefault});
  final String title;
  final String subtitle;
  final bool isDefault;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDefault ? AppColors.neutral100 : AppColors.surface,
        border: Border.all(color: isDefault ? AppColors.ink : AppColors.border, width: isDefault ? 1.5 : 1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            isDefault ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
            color: isDefault ? AppColors.ink : AppColors.neutral400,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(isDefault ? 'Default payout method' : subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (!isDefault)
            OutlinedButton(
              onPressed: onSetDefault,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Set default'),
            ),
        ],
      ),
    );
  }
}
