import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/overlays/app_toast.dart';
import 'password_success_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.contact, required this.code});

  final String contact;
  final String code;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty && _passwordController.text == _confirmController.text;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(destination: widget.contact, code: widget.code, newPassword: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t reset your password. Please try again.',
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
                  Text('Set a new\npassword', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose something you haven\'t used before on SportTech.',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'New password',
                    controller: _passwordController,
                    hint: 'At least 8 characters',
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Confirm new password',
                    controller: _confirmController,
                    hint: 'Re-enter password',
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ChecklistItem(label: 'At least 8 characters', met: _hasMinLength),
                  const SizedBox(height: AppSpacing.sm),
                  _ChecklistItem(label: 'Contains a number', met: _hasNumber),
                  const SizedBox(height: AppSpacing.sm),
                  _ChecklistItem(label: 'Passwords match', met: _passwordsMatch),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(label: 'Reset password', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.neutral400;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? AppColors.success : Colors.transparent,
            border: met ? null : Border.all(color: AppColors.neutral300, width: 1.5),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
