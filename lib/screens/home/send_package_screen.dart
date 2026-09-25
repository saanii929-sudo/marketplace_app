import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/addresses/addresses_controller.dart';
import '../../features/parcels/parcels_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import 'finding_rider_screen.dart';

class _PackageSizeOption {
  const _PackageSizeOption({required this.value, required this.label, required this.fromPrice});
  final String value;
  final String label;
  final double fromPrice;
}

const _sizeOptions = [
  _PackageSizeOption(value: 'document', label: 'Document', fromPrice: 15),
  _PackageSizeOption(value: 'small', label: 'Small', fromPrice: 25),
  _PackageSizeOption(value: 'medium', label: 'Medium', fromPrice: 40),
  _PackageSizeOption(value: 'large', label: 'Large', fromPrice: 65),
];

/// A same-day courier request — `POST /parcels/` (multipart). Pricing is
/// server-computed; the "from GH₵X" figures shown here are just a rough
/// guide per size, not what gets submitted.
class SendPackageScreen extends ConsumerStatefulWidget {
  const SendPackageScreen({super.key});

  @override
  ConsumerState<SendPackageScreen> createState() => _SendPackageScreenState();
}

class _SendPackageScreenState extends ConsumerState<SendPackageScreen> {
  final _dropoffLine1Controller = TextEditingController();
  final _dropoffCityController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _declaredValueController = TextEditingController();
  int _sizeIndex = 0;
  File? _photo;
  bool _submitting = false;

  @override
  void dispose() {
    _dropoffLine1Controller.dispose();
    _dropoffCityController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _descriptionController.dispose();
    _declaredValueController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    await AppModal.show(
      context,
      title: 'Add a photo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () async {
              Navigator.of(context).pop();
              final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
              if (picked != null) setState(() => _photo = File(picked.path));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_outlined,
            label: 'Choose from gallery',
            onTap: () async {
              Navigator.of(context).pop();
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
              if (picked != null) setState(() => _photo = File(picked.path));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _findRider(String pickupLine1, String pickupCity) async {
    if (_recipientNameController.text.trim().isEmpty ||
        _recipientPhoneController.text.trim().isEmpty ||
        _dropoffLine1Controller.text.trim().isEmpty ||
        _dropoffCityController.text.trim().isEmpty) {
      AppToast.show(context, 'Please fill in the recipient and dropoff details.', tone: AppToastTone.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      final parcel = await ref
          .read(parcelsApiProvider)
          .create(
            recipientName: _recipientNameController.text.trim(),
            recipientPhone: _recipientPhoneController.text.trim(),
            pickupLine1: pickupLine1,
            pickupCity: pickupCity,
            dropoffLine1: _dropoffLine1Controller.text.trim(),
            dropoffCity: _dropoffCityController.text.trim(),
            packageSize: _sizeOptions[_sizeIndex].value,
            description: _descriptionController.text.trim(),
            declaredValue: _declaredValueController.text.trim().isEmpty ? null : _declaredValueController.text.trim(),
            photo: _photo,
          );
      ref.invalidate(parcelsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => FindingRiderScreen(parcelId: parcel.id)),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t send that request. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesControllerProvider).value ?? const [];
    final defaultAddress = addresses.isEmpty
        ? null
        : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
    final pickupLabel = defaultAddress != null
        ? '${defaultAddress.label} — ${defaultAddress.line1}, ${defaultAddress.city}'
        : 'Add a delivery address first';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send a package', style: AppTypography.h2),
                    Text('Same-day courier, door to door', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Pickup & dropoff', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            _AddressRow(dotColor: AppColors.error, caption: 'PICKUP FROM', address: pickupLabel, isPlaceholder: defaultAddress == null),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Dropoff address', controller: _dropoffLine1Controller, hint: 'Street, landmark'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Dropoff city', controller: _dropoffCityController, hint: 'e.g. Accra'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Recipient name', controller: _recipientNameController, hint: 'Who\'s receiving this?'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Recipient phone',
              controller: _recipientPhoneController,
              hint: '024 000 0000',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Package size', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (var i = 0; i < _sizeOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SizeTile(
                      option: _sizeOptions[i],
                      selected: _sizeIndex == i,
                      onTap: () => setState(() => _sizeIndex = i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'e.g. Documents, a gift, spare parts',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Declared value (optional)',
              controller: _declaredValueController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              helperText: 'Used for insurance if the package is lost or damaged.',
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: _photo == null
                          ? const Icon(Icons.camera_alt_outlined, color: AppColors.neutral500)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Image.file(_photo!, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _photo == null ? 'Add a photo (optional)' : 'Photo attached',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ESTIMATED FROM', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                  Text(formatPrice(_sizeOptions[_sizeIndex].fromPrice), style: AppTypography.h3),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Find a rider',
              loading: _submitting,
              onPressed: defaultAddress == null
                  ? null
                  : () => _findRider(defaultAddress.line1, defaultAddress.city),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.dotColor, required this.caption, required this.address, this.isPlaceholder = false});
  final Color dotColor;
  final String caption;
  final String address;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  address,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPlaceholder ? AppColors.neutral400 : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeTile extends StatelessWidget {
  const _SizeTile({required this.option, required this.selected, required this.onTap});
  final _PackageSizeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : AppColors.surface,
          border: Border.all(color: selected ? AppColors.ink : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(option.label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('from ${formatPrice(option.fromPrice)}', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
