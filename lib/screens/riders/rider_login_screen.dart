import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/phone_utils.dart';
import '../../features/auth/session.dart';
import '../../features/riders/rider_session.dart';
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
import 'rider_documents_screen.dart';
import 'rider_home_shell.dart';
import 'rider_register_screen.dart';
import 'rider_verification_status_screen.dart';

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  int _identifierMode = 0; // 0 = phone, 1 = email

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _identifierMode == 0
        ? normalizeGhanaPhone(_identifierController.text)
        : _identifierController.text.trim();
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(identifier: identifier, password: _passwordController.text);
      final status = await resolveSessionStatus(ref);
      if (!mounted) return;
      switch (status) {
        case SessionStatus.authenticatedRider:
          final destination = await resolveRiderEntryDestination(ref);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => switch (destination) {
                RiderEntryDestination.home => const RiderHomeShell(),
                RiderEntryDestination.documentsNeeded => const RiderDocumentsScreen(),
                RiderEntryDestination.verificationPending => const RiderVerificationStatusScreen(),
              },
            ),
            (route) => false,
          );
        case SessionStatus.authenticatedCustomer:
          AppToast.show(
            context,
            'This is a customer account — continue as a customer instead.',
            tone: AppToastTone.error,
          );
        case SessionStatus.wrongRole:
          AppToast.show(context, 'Couldn\'t sign you in with this account.', tone: AppToastTone.error);
        case SessionStatus.unauthenticated:
          AppToast.show(context, 'Couldn\'t confirm your account. Please try again.', tone: AppToastTone.error);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, e is ApiException ? e.message : 'Couldn\'t log in. Please try again.', tone: AppToastTone.error);
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
                    Text('Welcome back, rider', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Log in to go online and start picking up deliveries.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SegmentedTabs(
                      labels: const ['Phone', 'Email'],
                      selectedIndex: _identifierMode,
                      onChanged: (i) => setState(() => _identifierMode = i),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      key: ValueKey(_identifierMode),
                      label: _identifierMode == 0 ? 'Phone number' : 'Email address',
                      controller: _identifierController,
                      hint: _identifierMode == 0 ? '024 000 0000' : 'you@example.com',
                      keyboardType: _identifierMode == 0 ? TextInputType.phone : TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your ${_identifierMode == 0 ? 'phone number' : 'email address'}'
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
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(label: 'Log in', loading: _loading, onPressed: _submit),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New to SportTech Rider? ',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RiderRegisterScreen()),
                            ),
                            child: Text(
                              'Sign up',
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
