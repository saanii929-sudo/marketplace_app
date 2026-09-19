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
import '../../widgets/buttons/social_sign_in_row.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/navigation/segmented_tabs.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _loading = false;
  int _identifierMode = 0; // 0 = email, 1 = phone

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showTerms() {
    AppModal.show(
      context,
      title: 'Terms & Privacy',
      child: Text(
        'By creating a SportTech account you agree to our Terms of Service and Privacy Policy, '
        'covering how listings are moderated, how payments are held in escrow until delivery is '
        'confirmed, and how your data is used to personalize your shopping experience.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
      ),
    );
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    final isEmail = _identifierMode == 0;
    final identifier = isEmail ? _emailController.text.trim() : normalizeGhanaPhone(_emailController.text);

    setState(() => _loading = true);
    try {
      final auth = ref.read(authControllerProvider.notifier);
      await auth.register(
        email: isEmail ? identifier : '',
        phone: isEmail ? '' : identifier,
        fullName: _nameController.text.trim(),
        password: _passwordController.text,
      );
      // The account isn't verified yet, so logging in here would fail —
      // OTP verification itself establishes the session (see
      // AuthApi.verifyOtp), which is why this goes straight to
      // VerificationScreen instead of logging in first.
      await auth.sendOtp(destination: identifier, purpose: 'signup_verify');
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerificationScreen(contact: identifier, isRegistration: true)),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t create your account. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF6F4EE),
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
                    Text('Create your account', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Set up your profile to start shopping and tracking orders.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Full name',
                      controller: _nameController,
                      hint: 'Jordan Mensah',
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your ${_identifierMode == 0 ? 'email address' : 'phone number'}'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: 'Create a password',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Confirm password',
                      controller: _confirmController,
                      hint: 'Re-enter password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() {
                              _acceptedTerms = v ?? false;
                              _termsError = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTerms,
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_termsError) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Please accept the Terms of Service and Privacy Policy to continue',
                        style: AppTypography.caption.copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(label: 'Create account', loading: _loading, onPressed: _submit),
                    const SizedBox(height: AppSpacing.xl),
                    const SocialSignInRow(),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: Text(
                              'Log in',
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
