import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/misc/illustrations.dart';
import '../../widgets/misc/progress_dots.dart';
import '../auth/login_screen.dart';

class _OnboardingPage {
  const _OnboardingPage({required this.icon, required this.color, required this.title, required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.search_rounded,
    color: AppColors.navy,
    title: 'Discover sporting products',
    body: 'Browse thousands of jerseys, footwear, and training gear across every sport, all in one place.',
  ),
  _OnboardingPage(
    icon: Icons.verified_user_outlined,
    color: AppColors.ink,
    title: 'Buy from trusted sellers',
    body: 'Every seller on SportTech is verified, so you shop with confidence and know exactly what you\'re getting.',
  ),
  _OnboardingPage(
    icon: Icons.local_shipping_outlined,
    color: Color(0xFF1F2A44),
    title: 'Get it delivered, fast',
    body: 'Track your order in real time, from checkout to your doorstep, wherever you are.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _finish() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HeroIllustration(icon: page.icon, background: page.color, height: 280),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(page.title, style: AppTypography.h1, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.body,
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              ProgressDots(count: _pages.length, index: _index),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _index == _pages.length - 1 ? 'Get started' : 'Next',
                onPressed: _next,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
