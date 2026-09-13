import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/states/confirmation_state.dart';
import 'login_screen.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF6F4EE),
        body: SafeArea(
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const ConfirmationState(
                  centered: false,
                  title: 'Password updated',
                  message: 'Your password has been changed. Use it next time you log in to SportTech.',
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Continue to login',
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
