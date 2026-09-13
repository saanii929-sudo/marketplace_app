import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/misc/illustrations.dart';
import '../../widgets/overlays/app_modal.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../home/home_shell.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    final confirmed = await AppModal.confirm(
      context,
      title: 'Continue as guest?',
      message: 'You can browse SportTech freely, but you\'ll need an account to check out or track orders.',
      confirmLabel: 'Continue as guest',
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: ResponsiveCenter(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandMark(size: 40),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      ),
                      child: const Text('How it works'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const HeroIllustration(icon: Icons.sports_soccer, height: 240),
                const SizedBox(height: AppSpacing.xxl),
                Text('Shop. Train.\nPerform.', style: AppTypography.display),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The fastest marketplace for authentic sporting gear — from trusted sellers, delivered to your door.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Create account',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Log in',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Continue as guest',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _continueAsGuest(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
