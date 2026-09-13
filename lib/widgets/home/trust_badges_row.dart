import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class _TrustItem {
  const _TrustItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _items = [
  _TrustItem(Icons.verified_user_outlined, 'Verified sellers'),
  _TrustItem(Icons.lock_outline, 'Secure payments'),
  _TrustItem(Icons.local_shipping_outlined, 'Fast delivery'),
  _TrustItem(Icons.replay_outlined, 'Easy returns'),
  _TrustItem(Icons.support_agent_outlined, 'Customer support'),
];

/// Row of trust indicators shown below the product sections.
class TrustBadgesRow extends StatelessWidget {
  const TrustBadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.neutral50, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: AppSpacing.lg,
        children: _items.map((item) {
          return SizedBox(
            width: 84,
            child: Column(
              children: [
                Icon(item.icon, size: 22, color: AppColors.ink),
                const SizedBox(height: 6),
                Text(item.label, style: AppTypography.caption, textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
