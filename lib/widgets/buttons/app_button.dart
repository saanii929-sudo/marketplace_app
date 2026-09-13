import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

const double _kButtonRadius = AppRadius.lg;

enum AppButtonVariant { primary, secondary, ghost }

/// Unified button used across the app: primary (filled), secondary
/// (outlined), and ghost (text). Handles disabled + loading states.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand;

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final Widget content = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: variant == AppButtonVariant.primary ? AppColors.white : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.buttonLabel.copyWith(color: _labelColor())),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: _disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.neutral200,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.white,
            side: BorderSide(color: _disabled ? AppColors.neutral200 : AppColors.neutral300, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: _disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _labelColor() {
    if (_disabled && variant != AppButtonVariant.primary) return AppColors.neutral400;
    return switch (variant) {
      AppButtonVariant.primary => AppColors.white,
      AppButtonVariant.secondary => AppColors.ink,
      AppButtonVariant.ghost => AppColors.ink,
    };
  }
}
