import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/phone_utils.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/overlays/app_toast.dart';
import '../auth/verification_screen.dart';
import 'rider_documents_screen.dart';
import 'rider_login_screen.dart';

const _vehicleTypes = [
  ('bicycle', 'Bicycle', Icons.pedal_bike),
  ('motorcycle', 'Motorcycle', Icons.two_wheeler),
  ('car', 'Car', Icons.directions_car_outlined),
  ('van', 'Van', Icons.airport_shuttle_outlined),
];

class RiderRegisterScreen extends ConsumerStatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  ConsumerState<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends ConsumerState<RiderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _vehicleType = _vehicleTypes.first.$1;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = normalizeGhanaPhone(_phoneController.text);

    setState(() => _loading = true);
    try {
      await ref
          .read(ridersApiProvider)
          .register(
            email: '',
            phone: phone,
            fullName: _nameController.text.trim(),
            password: _passwordController.text,
            vehicleType: _vehicleType,
          );
      await ref.read(authControllerProvider.notifier).sendOtp(destination: phone, purpose: 'signup_verify');
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            contact: phone,
            isRegistration: true,
            onVerified: (_) => const RiderDocumentsScreen(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t create your rider account. Please try again.',
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
                    Text('Become a rider', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tell us a bit about you and how you\'ll be delivering.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Full name',
                      controller: _nameController,
                      hint: 'Kojo Boateng',
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phoneController,
                      hint: '024 000 0000',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: 'Create a password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('What do you ride?', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final vehicle in _vehicleTypes)
                          _VehicleTypeTile(
                            icon: vehicle.$3,
                            label: vehicle.$2,
                            selected: _vehicleType == vehicle.$1,
                            onTap: () => setState(() => _vehicleType = vehicle.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(label: 'Continue', loading: _loading, onPressed: _submit),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Already riding with us? ',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
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

class _VehicleTypeTile extends StatelessWidget {
  const _VehicleTypeTile({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.surface,
          border: Border.all(color: selected ? AppColors.ink : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.ink),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
