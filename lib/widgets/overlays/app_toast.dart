import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum AppToastTone { neutral, success, error }

/// Lightweight toast notification helper built on top of [ScaffoldMessenger].
class AppToast {
  AppToast._();

  static void show(BuildContext context, String message, {AppToastTone tone = AppToastTone.neutral}) {
    final Color background = switch (tone) {
      AppToastTone.neutral => AppColors.ink,
      AppToastTone.success => AppColors.success,
      AppToastTone.error => AppColors.error,
    };
    final IconData icon = switch (tone) {
      AppToastTone.neutral => Icons.info_outline,
      AppToastTone.success => Icons.check_circle_outline,
      AppToastTone.error => Icons.error_outline,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.white))),
            ],
          ),
        ),
      );
  }
}
