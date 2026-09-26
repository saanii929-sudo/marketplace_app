import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

class RiderCashOutScreen extends ConsumerStatefulWidget {
  const RiderCashOutScreen({super.key});

  @override
  ConsumerState<RiderCashOutScreen> createState() => _RiderCashOutScreenState();
}

class _RiderCashOutScreenState extends ConsumerState<RiderCashOutScreen> {
  double? _amount;
  int? _payoutMethodId;
  bool _submitting = false;

  Future<void> _cashOut(double balance) async {
    final amount = _amount ?? balance;
    if (_payoutMethodId == null) {
      AppToast.show(context, 'Please choose where to send this.', tone: AppToastTone.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(ridersApiProvider).cashOut(amount: amount, payoutMethodId: _payoutMethodId!);
      ref.invalidate(riderEarningsSummaryProvider);
      ref.invalidate(riderEarningsActivityProvider);
      if (!mounted) return;
      AppToast.show(context, 'Cash out requested — ${formatPrice(amount)}', tone: AppToastTone.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t process that cash out. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(riderEarningsSummaryProvider);
    final payoutMethodsAsync = ref.watch(riderPayoutMethodsProvider);
    final balance = summaryAsync.value?.availableBalance ?? 0;
    final amount = _amount ?? balance;

    payoutMethodsAsync.whenData((methods) {
      if (_payoutMethodId == null && methods.isNotEmpty) {
        final defaultMethod = methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _payoutMethodId = defaultMethod.id);
        });
      }
    });

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
                    Text('Cash out', style: AppTypography.h2),
                    Text('Transfer to your linked account', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: const Color(0x1A1FA855), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                children: [
                  Text(
                    'AVAILABLE TO WITHDRAW',
                    style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(formatPrice(balance), style: AppTypography.h1),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Amount', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text('GH₵ ${amount.toStringAsFixed(2)}', style: AppTypography.h3),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _QuickAmountChip(label: 'GH₵50', onTap: () => setState(() => _amount = balance < 50 ? balance : 50))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _QuickAmountChip(label: 'GH₵100', onTap: () => setState(() => _amount = balance < 100 ? balance : 100))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _QuickAmountChip(label: 'All', onTap: () => setState(() => _amount = balance))),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Send to', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            payoutMethodsAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.lg),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your payout methods.',
                onRetry: () => ref.invalidate(riderPayoutMethodsProvider),
              ),
              data: (methods) => methods.isEmpty
                  ? Text(
                      'No payout methods yet — add one from Bank & MoMo in your profile.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    )
                  : Column(
                      children: [
                        for (final method in methods) ...[
                          _PayoutMethodTile(
                            title: method.title,
                            subtitle: method.isDefault ? 'Default payout method' : method.subtitle,
                            selected: _payoutMethodId == method.id,
                            onTap: () => setState(() => _payoutMethodId = method.id),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Cash out',
              loading: _submitting,
              onPressed: amount <= 0 || amount > balance || _payoutMethodId == null ? null : () => _cashOut(balance),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      child: Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _PayoutMethodTile extends StatelessWidget {
  const _PayoutMethodTile({required this.title, required this.subtitle, required this.selected, required this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.surface,
          border: Border.all(color: selected ? AppColors.ink : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.ink : AppColors.neutral400,
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
