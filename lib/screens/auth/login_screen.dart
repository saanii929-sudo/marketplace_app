import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/session.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/buttons/social_sign_in_row.dart';
import '../../widgets/navigation/segmented_tabs.dart';
import '../../widgets/overlays/app_toast.dart';
import '../home/home_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verification_screen.dart';

/// The given API has no structured error code for "account exists but
/// isn't verified yet" — this is a best-effort match on the login error
/// message's wording, since that's all the backend surfaces.
bool _looksLikeUnverifiedError(String message) {
  final m = message.toLowerCase();
  return m.contains('not verified') || m.contains('not been verified') || m.contains('please verify') || m.contains('verify your');
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  int _identifierMode = 0; // 0 = email, 1 = phone

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _emailController.text.trim();
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(identifier: identifier, password: _passwordController.text);
      final status = await resolveSessionStatus(ref);
      if (!mounted) return;
      switch (status) {
        case SessionStatus.authenticatedCustomer:
          Navigator.of(
            context,
          ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (route) => false);
        case SessionStatus.wrongRole:
          AppToast.show(
            context,
            'This app is for customer accounts only. Please sign in with a customer account.',
            tone: AppToastTone.error,
          );
        case SessionStatus.unauthenticated:
          AppToast.show(context, 'Couldn\'t confirm your account. Please try again.', tone: AppToastTone.error);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && _looksLikeUnverifiedError(e.message)) {
        await _redirectToVerification(identifier);
        return;
      }
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t log in. Please try again.', tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The account exists but isn't verified — send a fresh code and take
  /// the user straight to the same verification flow used right after
  /// registration, instead of just showing the error as a toast.
  Future<void> _redirectToVerification(String identifier) async {
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(destination: identifier, purpose: 'signup_verify');
    } catch (_) {
      // Best-effort — the verification screen's own "Resend code" lets the
      // user retry if this send failed.
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VerificationScreen(contact: identifier, isRegistration: true)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFFF6F4EE),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: ResponsiveCenter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Welcome back', style: GoogleFonts.caladea(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Log in to pick up your gear where you left off.',
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
                      controller: _emailController,
                      hint: _identifierMode == 0 ? 'you@example.com' : '+1 234 567 8900',
                      keyboardType: _identifierMode == 0 ? TextInputType.emailAddress : TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your ${_identifierMode == 0 ? 'email address' : 'phone number'}'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: 'Enter your password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(label: 'Log in', loading: _loading, onPressed: _submit),
                    const SizedBox(height: AppSpacing.xl),
                    const SocialSignInRow(),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                            child: Text(
                              'Create one',
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
      ),
    );
  }
}
