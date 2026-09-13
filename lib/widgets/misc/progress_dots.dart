import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Onboarding-style progress indicator: active dot elongates into a bar.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
