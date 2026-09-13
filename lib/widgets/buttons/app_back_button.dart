import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Circular bordered icon button — used as the back button at the top of
/// auth/detail screens, and reused anywhere else that same look fits (e.g.
/// an edit-profile action).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap, this.icon = Icons.arrow_back});

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}
