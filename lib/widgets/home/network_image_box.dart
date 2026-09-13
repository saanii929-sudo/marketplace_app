import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../states/skeleton.dart';

/// A network image with a skeleton while loading and an icon fallback if
/// the load fails, so a slow/broken photo never breaks a card layout.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String url;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// Decodes the image at roughly this pixel width instead of full
  /// resolution, so a large source photo doesn't cost more to decode/paint
  /// than the space it's actually shown in (a common cause of scroll jank).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          color: AppColors.neutral100,
          alignment: Alignment.center,
          child: Icon(fallbackIcon, size: 32, color: AppColors.neutral400),
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: cacheWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Skeleton(width: double.infinity, height: double.infinity, borderRadius: 0);
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.neutral100,
            alignment: Alignment.center,
            child: Icon(fallbackIcon, size: 32, color: AppColors.neutral400),
          );
        },
      ),
    );
  }
}
