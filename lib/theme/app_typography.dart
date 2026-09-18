import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// SportTech type scale. Poppins throughout, from display headlines to
/// captions, for a single consistent voice across the app.
class AppTypography {
  AppTypography._();

  static TextStyle _poppins(double size, FontWeight weight, {double? height, double? letterSpacing, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  static TextStyle display = _poppins(40, FontWeight.w900, height: 1.05, letterSpacing: -0.5);
  static TextStyle h1 = _poppins(32, FontWeight.w900, height: 1.1, letterSpacing: -0.4);
  static TextStyle h2 = _poppins(24, FontWeight.w800, height: 1.15, letterSpacing: -0.2);
  static TextStyle h3 = _poppins(20, FontWeight.w800, height: 1.2);

  static TextStyle bodyLarge = _poppins(16, FontWeight.w500, height: 1.45);
  static TextStyle bodyMedium = _poppins(14, FontWeight.w500, height: 1.4);
  static TextStyle bodySmall = _poppins(13, FontWeight.w500, height: 1.35, color: AppColors.neutral600);

  static TextStyle label = _poppins(14, FontWeight.w600, height: 1.2);
  static TextStyle caption = _poppins(11, FontWeight.w500, height: 1.3, color: AppColors.neutral500);
  static TextStyle overline = _poppins(
    12,
    FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.4,
    color: AppColors.neutral500,
  );

  static TextStyle buttonLabel = _poppins(15, FontWeight.w600, height: 1, letterSpacing: 0.2);
}
