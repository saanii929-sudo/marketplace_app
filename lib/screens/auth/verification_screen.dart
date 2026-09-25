import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/otp_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/overlays/app_toast.dart';
import 'account_setup_screen.dart';
import 'reset_password_screen.dart';

const _kOtpLength = 6;
const _signupPurpose = 'signup_verify';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key, required this.contact, required this.isRegistration, this.onVerified});

  final String contact;
  final bool isRegistration;

  /// Where to land after a successful registration verification — defaults
  /// to the customer `AccountSetupScreen`. Rider registration passes a
  /// builder for the rider documents screen instead, so this one OTP
  /// screen serves both signup flows.
  final Widget Function(BuildContext context)? onVerified;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _loading = false;
  bool _hasError = false;
  int _secondsLeft = 30;
  Timer? _timer;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onCompleted(String code) async {
    setState(() {
      _code = code;
      _hasError = false;
    });

    // Password reset has no separate "verify the code" endpoint — the code
    // is only actually checked when it's submitted together with the new
    // password, so it's just carried forward here.
    if (!widget.isRegistration) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(contact: widget.contact, code: code)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(destination: widget.contact, purpose: _signupPurpose, code: code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: widget.onVerified ?? (_) => const AccountSetupScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'That code didn\'t work. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (widget.isRegistration) {
        await auth.sendOtp(destination: widget.contact, purpose: _signupPurpose);
      } else {
        await auth.forgotPassword(destination: widget.contact);
      }
      if (!mounted) return;
      _startTimer();
      AppToast.show(context, 'Code resent', tone: AppToastTone.success);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t resend the code. Please try again.',
        tone: AppToastTone.error,
      );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(height: AppSpacing.lg),
                Text('Verify it\'s you', style: AppTypography.h1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We\'ve sent a 6-digit code to',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.contact.isEmpty ? 'your account' : widget.contact,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OtpField(length: _kOtpLength, hasError: _hasError, onCompleted: _onCompleted),
                const SizedBox(height: AppSpacing.lg),
                if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                if (!_loading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _secondsLeft > 0 ? 'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}' : '',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                      GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'Resend code',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _secondsLeft > 0 ? AppColors.neutral400 : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Verify',
                  loading: _loading,
                  onPressed: () {
                    if (_code.length == _kOtpLength) {
                      _onCompleted(_code);
                    } else {
                      AppToast.show(context, 'Enter the 6-digit code');
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.contact.contains('@') ? 'Wrong email? ' : 'Wrong number? ',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Go back',
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
    );
  }
}
