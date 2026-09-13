import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../misc/illustrations.dart';
import '../overlays/app_toast.dart';

/// Large full-width tappable banner for a sports collection.
class CollectionBanner extends StatelessWidget {
  const CollectionBanner({super.key, required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: GestureDetector(
        onTap: () => AppToast.show(context, 'Opening ${collection.title}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: collection.color),
                CustomPaint(painter: MotionLinesPainter(color: AppColors.white, lineCount: 8)),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(collection.icon, size: 72, color: AppColors.white.withValues(alpha: 0.14)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(collection.title, style: AppTypography.h2.copyWith(color: AppColors.white)),
                      const SizedBox(height: 4),
                      Text(collection.subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral300)),
                    ],
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
