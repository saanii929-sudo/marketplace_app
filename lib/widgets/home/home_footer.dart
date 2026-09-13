import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../misc/illustrations.dart';
import '../overlays/app_toast.dart';

const _links = [
  'About SportTech',
  'Customer service',
  'Shipping information',
  'Returns',
  'Privacy',
  'Terms',
  'Seller center',
];

/// Home screen footer: informational links and a brand sign-off.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(size: 36, light: true),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: _links.map((link) {
              return GestureDetector(
                onTap: () => AppToast.show(context, 'Coming soon'),
                child: Text(link, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral400)),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(color: AppColors.neutral700),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '© 2026 SportTech. All rights reserved.',
            style: AppTypography.caption.copyWith(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}
