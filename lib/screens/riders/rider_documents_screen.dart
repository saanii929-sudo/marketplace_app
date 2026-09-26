import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import 'rider_verification_status_screen.dart';

class RiderDocumentsScreen extends ConsumerStatefulWidget {
  const RiderDocumentsScreen({super.key});

  @override
  ConsumerState<RiderDocumentsScreen> createState() => _RiderDocumentsScreenState();
}

class _RiderDocumentsScreenState extends ConsumerState<RiderDocumentsScreen> {
  final _files = <String, File>{};
  final _uploading = <String>{};

  Future<void> _pickDocument(String documentType, String label) async {
    await AppModal.show(
      context,
      title: 'Upload $label',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () async {
              Navigator.of(context).pop();
              await _pickImage(documentType, ImageSource.camera);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_outlined,
            label: 'Choose from gallery',
            onTap: () async {
              Navigator.of(context).pop();
              await _pickImage(documentType, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String documentType, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() => _uploading.add(documentType));
    try {
      await ref.read(ridersApiProvider).uploadDocument(documentType: documentType, file: file);
      if (!mounted) return;
      setState(() {
        _files[documentType] = file;
        _uploading.remove(documentType);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading.remove(documentType));
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t upload that document. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  void _continue() {
    if (!_files.containsKey(riderDocumentTypes.first.$1)) {
      AppToast.show(context, 'Please upload your Government ID to continue.', tone: AppToastTone.error);
      return;
    }
    ref.invalidate(riderVerificationStatusProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RiderVerificationStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            AppBackButton(onTap: () => Navigator.of(context).pop()),
            const SizedBox(height: AppSpacing.lg),
            Text('Upload your documents', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We verify every rider before their first delivery — this usually takes under 24 hours.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final documentType in riderDocumentTypes) ...[
              _DocumentRow(
                label: documentType.$2,
                uploaded: _files.containsKey(documentType.$1),
                uploading: _uploading.contains(documentType.$1),
                onTap: () => _pickDocument(documentType.$1, documentType.$2),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Submit for review', onPressed: _continue),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.label, required this.uploaded, required this.uploading, required this.onTap});
  final String label;
  final bool uploaded;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: uploaded ? const Color(0x1A1FA855) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: uploaded ? AppColors.success : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: uploaded ? AppColors.success : AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neutral500),
                  )
                : Icon(
                    uploaded ? Icons.check : Icons.upload_outlined,
                    size: 18,
                    color: uploaded ? AppColors.white : AppColors.neutral500,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.label),
                const SizedBox(height: 2),
                Text(
                  uploaded ? 'Uploaded' : (uploading ? 'Uploading…' : 'Not uploaded'),
                  style: AppTypography.bodySmall.copyWith(color: uploaded ? AppColors.success : AppColors.neutral500),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: uploading ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(uploaded ? 'Replace' : 'Upload'),
          ),
        ],
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
