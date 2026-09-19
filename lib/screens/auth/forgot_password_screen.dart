import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/phone_utils.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/navigation/segmented_tabs.dart';
import '../../widgets/overlays/app_toast.dart';
import 'verification_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  bool _loading = false;
  int _identifierMode = 0; // 0 = email, 1 = phone

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final destination = _identifierMode == 0
        ? _contactController.text.trim()
        : normalizeGhanaPhone(_contactController.text);
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(destination: destination);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerificationScreen(contact: destination, isRegistration: false)),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t send a reset code. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF6F4EE),
        body: SafeArea(
          child: ResponsiveCenter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Forgot your\npassword?', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enter the email or phone number linked to your account and we\'ll send you a reset link.',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SegmentedTabs(
                    labels: const ['Email', 'Phone'],
                    selectedIndex: _identifierMode,
                    onChanged: (i) => setState(() => _identifierMode = i),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    key: ValueKey(_identifierMode),
                    label: _identifierMode == 0 ? 'Email address' : 'Phone number',
                    controller: _contactController,
                    hint: _identifierMode == 0 ? 'you@example.com' : '+1 234 567 8900',
                    keyboardType: _identifierMode == 0 ? TextInputType.emailAddress : TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your ${_identifierMode == 0 ? 'email address' : 'phone number'}'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(label: 'Send reset link', loading: _loading, onPressed: _submit),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Remembered it? ',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Back to login',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
