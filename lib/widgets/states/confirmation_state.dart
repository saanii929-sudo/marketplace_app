import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Success/confirmation illustration + copy (e.g. password reset success,
/// order placed).
class ConfirmationState extends StatelessWidget {
  const ConfirmationState({super.key, required this.title, required this.message, this.centered = true});

  final String title;
  final String message;

  /// Whether the title/message are centered under the icon (the default,
  /// for a full-screen confirmation) or left-aligned below a centered icon
  /// (for a screen with its own top-flowing layout).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Align(
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color(0x1A1FA855), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: AppTypography.h2, textAlign: textAlign),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
          textAlign: textAlign,
        ),
      ],
    );
  }
}
