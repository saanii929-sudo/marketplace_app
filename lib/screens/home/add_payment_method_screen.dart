import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/payments/payments_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/navigation/segmented_tabs.dart';
import '../../widgets/overlays/app_toast.dart';

/// Add-card form — posts to `POST /payments/methods/`.
///
/// This app has no Paystack (or other gateway) SDK integration, so there's
/// no way to produce the real tokenization result that endpoint expects.
/// Only the non-sensitive fields it actually asks for (brand, last 4
/// digits, expiry) are collected here — never a full card number or
/// CVV — and a locally-generated placeholder stands in for the token (see
/// `PaymentsApi`/`PaymentMethodsController.create`). The card saved this
/// way is not connected to a real chargeable card until a gateway SDK is
/// wired in.
class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _expiryController = TextEditingController();
  bool _saving = false;

  /// 0 = card (has an expiry), 1 = mobile money (doesn't).
  int _typeMode = 0;
  bool get _isCard => _typeMode == 0;

  @override
  void dispose() {
    _brandController.dispose();
    _last4Controller.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    int? month;
    int? year;
    if (_isCard) {
      final expiryParts = _expiryController.text.trim().split('/');
      month = int.parse(expiryParts[0]);
      year = 2000 + int.parse(expiryParts[1]);
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(paymentMethodsControllerProvider.notifier)
          .create(
            brand: _brandController.text.trim(),
            last4: _last4Controller.text.trim(),
            expiryMonth: month,
            expiryYear: year,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t save that payment method. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add payment method', style: AppTypography.h2),
                        Text(
                          'Cards and mobile money',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.neutral500),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Demo mode — no real payment gateway is connected yet, so this payment method won\'t actually be charged.',
                          style: AppTypography.caption.copyWith(color: AppColors.neutral600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SegmentedTabs(
                  labels: const ['Card', 'Mobile Money'],
                  selectedIndex: _typeMode,
                  onChanged: (i) => setState(() => _typeMode = i),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: _isCard ? 'Card brand' : 'Provider',
                  controller: _brandController,
                  hint: _isCard ? 'Visa, Mastercard…' : 'MTN MoMo, Vodafone Cash…',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Enter the ${_isCard ? 'card brand' : 'provider'}' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: _isCard ? 'Last 4 digits' : 'Last 4 digits of number',
                  controller: _last4Controller,
                  hint: '1234',
                  keyboardType: TextInputType.number,
                  textInputAction: _isCard ? TextInputAction.next : TextInputAction.done,
                  validator: (v) {
                    final digits = v?.trim() ?? '';
                    if (digits.length != 4 || int.tryParse(digits) == null) {
                      return 'Enter the last 4 digits';
                    }
                    return null;
                  },
                ),
                if (_isCard) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Expiry (MM/YY)',
                    controller: _expiryController,
                    hint: '09/28',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(v?.trim() ?? '');
                      return match == null ? 'Enter a valid expiry as MM/YY' : null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                AppButton(label: 'Save payment method', loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
