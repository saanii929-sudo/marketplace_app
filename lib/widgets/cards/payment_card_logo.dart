import 'package:flutter/material.dart';

import '../../features/payments/payment_method.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Small brand-colored chip standing in for a card network / mobile-money
/// logo (Visa, Mastercard, MTN MoMo) — used on the payment methods list and
/// at checkout.
class PaymentCardLogo extends StatelessWidget {
  const PaymentCardLogo({super.key, required this.type});
  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (type) {
      PaymentType.visa => (const Color(0xFF1A1F71), AppColors.white, 'VISA'),
      PaymentType.mastercard => (AppColors.ink, AppColors.white, 'Mastercard'),
      PaymentType.momo => (const Color(0xFFFFCB05), AppColors.ink, 'MTN MoMo'),
      PaymentType.other => (AppColors.neutral300, AppColors.ink, 'Card'),
    };

    return Container(
      width: 52,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
