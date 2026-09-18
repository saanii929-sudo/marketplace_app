import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/misc/illustrations.dart';
import '../home/home_shell.dart';
import '../onboarding/welcome_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6));

  @override
  void initState() {
    super.initState();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    // Runs the session check and the minimum splash display time together,
    // so a fast (or cached) check never makes the splash flash by too
    // quickly, and a slow one never holds it beyond what the check needs.
    final results = await Future.wait([
      resolveSessionStatus(ref),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    final status = results[0] as SessionStatus;

    Widget destination = switch (status) {
      SessionStatus.authenticatedCustomer => const HomeShell(),
      SessionStatus.wrongRole => const WelcomeScreen(
        notice: 'This app is for customer accounts only. Please sign in with a customer account.',
      ),
      SessionStatus.unauthenticated => const WelcomeScreen(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 76, light: true),
                const SizedBox(height: 20),
                Text(
                  'SPORTTECH',
                  style: AppTypography.h2.copyWith(color: AppColors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text(
                  'SHOP. TRAIN. PERFORM.',
                  style: AppTypography.overline.copyWith(color: AppColors.neutral400, letterSpacing: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
