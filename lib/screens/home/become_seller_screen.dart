import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/states/confirmation_state.dart';

const _benefits = [
  'Reach thousands of athletes browsing SportTech every week',
  'Get paid out within 48 hours of a completed delivery',
  'Free seller tools — inventory, order and insights dashboard',
  'A dedicated seller support team, seven days a week',
];

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _categoryError = false;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _categoryError = _selectedCategories.isEmpty);
    if (!formValid || _selectedCategories.isEmpty) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.ink,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sell on SportTech',
                    style: AppTypography.h1.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Join thousands of verified sellers reaching athletes across Ghana.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _submitted
                  ? _SuccessView(
                      businessName: _businessNameController.text.trim(),
                    )
                  : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final benefit in _benefits) ...[
            _BenefitRow(text: benefit),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Business name',
            controller: _businessNameController,
            hint: 'e.g. Northmark Sports Store',
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Enter your business name'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('What do you sell?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < mockCategories.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: mockCategories[i].label,
                    selected: _selectedCategories.contains(
                      mockCategories[i].label,
                    ),
                    onTap: () => setState(() {
                      final label = mockCategories[i].label;
                      _selectedCategories.contains(label)
                          ? _selectedCategories.remove(label)
                          : _selectedCategories.add(label);
                      _categoryError = false;
                    }),
                  ),
                ],
              ],
            ),
          ),
          if (_categoryError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick at least one category',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Phone number',
            controller: _phoneController,
            hint: '024 000 0000',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter your phone number'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Apply to sell',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x1A1FA855),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: AppColors.success),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.businessName});
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ConfirmationState(
            title: 'Application submitted',
            message:
                "We'll review ${businessName.isEmpty ? 'your' : "$businessName's"} application and get back to you within 2 business days.",
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Back to profile',
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
