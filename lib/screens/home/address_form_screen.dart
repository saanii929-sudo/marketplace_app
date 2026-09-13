import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/addresses/address.dart';
import '../../features/addresses/addresses_api.dart';
import '../../features/addresses/addresses_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_toast.dart';

/// Add/edit form for a saved address — posts to
/// `POST /accounts/addresses/` or `PUT /accounts/addresses/{id}/`.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  /// Non-null when editing an existing address.
  final Address? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController = TextEditingController(text: widget.existing?.label ?? '');
  late final _recipientController = TextEditingController(text: widget.existing?.recipientName ?? '');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
  late final _line1Controller = TextEditingController(text: widget.existing?.line1 ?? '');
  late final _line2Controller = TextEditingController(text: widget.existing?.line2 ?? '');
  late final _cityController = TextEditingController(text: widget.existing?.city ?? '');
  late final _regionController = TextEditingController(text: widget.existing?.region ?? '');
  late final _countryController = TextEditingController(text: widget.existing?.country ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final input = AddressInput(
      label: _labelController.text.trim(),
      recipientName: _recipientController.text.trim(),
      phone: _phoneController.text.trim(),
      line1: _line1Controller.text.trim(),
      line2: _line2Controller.text.trim(),
      city: _cityController.text.trim(),
      region: _regionController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: _isDefault,
    );
    try {
      final controller = ref.read(addressesControllerProvider.notifier);
      if (_isEditing) {
        await controller.updateAddress(widget.existing!.id, input);
      } else {
        await controller.create(input);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t save that address. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEditing ? 'Edit address' : 'Add new address', style: AppTypography.h2),
                        Text(
                          'Where should we deliver your gear?',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Label',
                  controller: _labelController,
                  hint: 'Home, Work, ...',
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Give this address a label' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Recipient name',
                  controller: _recipientController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a recipient name' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a phone number' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Address line 1',
                  controller: _line1Controller,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the street address' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Address line 2 (optional)',
                  controller: _line2Controller,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'City',
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a city' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Region',
                  controller: _regionController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a region' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Country',
                  controller: _countryController,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a country' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(value: _isDefault, onChanged: (v) => setState(() => _isDefault = v ?? false)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Set as default address', style: AppTypography.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(label: _isEditing ? 'Save changes' : 'Add address', loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
