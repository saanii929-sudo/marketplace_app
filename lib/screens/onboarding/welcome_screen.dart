import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/misc/illustrations.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../riders/rider_login_screen.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.notice});

  final String? notice;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    final notice = widget.notice;
    if (notice != null && notice.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppToast.show(context, notice, tone: AppToastTone.error);
      });
    }
  }

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
                AppButton(
                  label: 'Continue as rider',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Continue as customer',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Continue as a guest',
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
