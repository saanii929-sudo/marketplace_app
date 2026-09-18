import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/payments/payment_method.dart';
import '../../features/payments/payments_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/payment_card_logo.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  Future<void> _setDefault(BuildContext context, WidgetRef ref, PaymentMethod method) async {
    try {
      await ref.read(paymentMethodsControllerProvider.notifier).setDefault(method.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your default payment method.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, PaymentMethod method) async {
    try {
      await ref.read(paymentMethodsControllerProvider.notifier).delete(method.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t remove that payment method.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsControllerProvider);

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
                    Text('Payment methods', style: AppTypography.h2),
                    Text(
                      'Cards and mobile money on file',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            methodsAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    const ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.lg),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your payment methods.',
                onRetry: () => ref.read(paymentMethodsControllerProvider.notifier).refresh(),
              ),
              data: (methods) => Column(
                children: [
                  for (final method in methods) ...[
                    _PaymentMethodCard(
                      method: method,
                      onSetDefault: () => _setDefault(context, ref, method),
                      onRemove: () => _remove(context, ref, method),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            AppButton(
              label: '+ Add payment method',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.method, required this.onSetDefault, required this.onRemove});
  final PaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          PaymentCardLogo(type: method.type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•••• ${method.last4}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                Text(method.subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          if (method.isDefault)
            const AppBadge(label: 'Default', tone: AppBadgeTone.success)
          else
            GestureDetector(
              onTap: onSetDefault,
              child: Text(
                'Set default',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 18, color: AppColors.neutral400)),
        ],
      ),
    );
  }
}
