import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The SportTech brand mark: a bold monogram lockup used on splash and
/// wherever a compact logo is needed.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? AppColors.white : AppColors.ink,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.5, size * 0.5),
          painter: _BoltPainter(color: light ? AppColors.ink : AppColors.accent),
        ),
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  _BoltPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.58, 0)
      ..lineTo(0, size.height * 0.6)
      ..lineTo(size.width * 0.42, size.height * 0.6)
      ..lineTo(size.width * 0.32, size.height)
      ..lineTo(size.width, size.height * 0.36)
      ..lineTo(size.width * 0.56, size.height * 0.36)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BoltPainter oldDelegate) => oldDelegate.color != color;
}

/// Diagonal motion/speed lines used as a decorative backdrop accent.
class MotionLinesPainter extends CustomPainter {
  MotionLinesPainter({required this.color, this.lineCount = 6});

  final Color color;
  final int lineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final spacing = size.width / lineCount;
    for (var i = 0; i < lineCount; i++) {
      final x = i * spacing;
      final opacity = 1 - (i / lineCount) * 0.8;
      paint.color = color.withValues(alpha: opacity.clamp(0.08, 1));
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * 0.4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MotionLinesPainter oldDelegate) => false;
}

/// A themed hero illustration block: a dark geometric backdrop, motion
/// lines, and a centerpiece icon. Used across Welcome and Onboarding so
/// each screen gets a distinct but consistent visual identity.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({
    super.key,
    required this.icon,
    this.background = AppColors.navy,
    this.height = 280,
  });

  final IconData icon;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: background),
            CustomPaint(painter: MotionLinesPainter(color: AppColors.white)),
            Positioned(
              right: -30,
              bottom: -30,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
                ),
                child: Icon(icon, size: 44, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
