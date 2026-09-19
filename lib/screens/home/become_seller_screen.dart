import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/phone_utils.dart';
import '../../features/catalog/catalog_controllers.dart';
import '../../features/sellers/seller_application.dart';
import '../../features/sellers/sellers_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/confirmation_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

const _benefits = [
  'Reach thousands of athletes browsing SportTech every week',
  'Get paid out within 48 hours of a completed delivery',
  'Free seller tools — inventory, order and insights dashboard',
  'A dedicated seller support team, seven days a week',
];

/// "Sell on SportTech" — submits to `POST /sellers/apply/` (multipart, with
/// a required ID document and optional business certificate upload) and
/// checks `GET /sellers/apply/status/` first so a repeat visit shows the
/// existing application instead of the form again.
class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedCategoryId;
  File? _idDocument;
  File? _businessCertificate;
  bool _categoryError = false;
  bool _idDocumentError = false;
  bool _loading = false;
  bool _submitted = false;

  /// Set when the user taps "Apply again" on a rejected application, so
  /// the form shows instead of the (still-rejected, until resubmitted)
  /// status view.
  bool _forceShowForm = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument({required bool isIdDocument}) async {
    await AppModal.show(
      context,
      title: isIdDocument ? 'Upload ID document' : 'Upload business certificate',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DocumentSourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () => _pickImage(ImageSource.camera, isIdDocument: isIdDocument),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DocumentSourceTile(
            icon: Icons.photo_outlined,
            label: 'Choose from gallery',
            onTap: () => _pickImage(ImageSource.gallery, isIdDocument: isIdDocument),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isIdDocument}) async {
    Navigator.of(context).pop();
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (isIdDocument) {
        _idDocument = File(picked.path);
        _idDocumentError = false;
      } else {
        _businessCertificate = File(picked.path);
      }
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _categoryError = _selectedCategoryId == null;
      _idDocumentError = _idDocument == null;
    });
    if (!formValid || _categoryError || _idDocumentError) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(sellersApiProvider)
          .apply(
            businessName: _businessNameController.text.trim(),
            categoryId: _selectedCategoryId!,
            phone: normalizeGhanaPhone(_phoneController.text),
            idDocument: _idDocument!,
            businessCertificate: _businessCertificate,
          );
      ref.invalidate(sellerApplicationStatusProvider);
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t submit your application. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(sellerApplicationStatusProvider);

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
                  ? _SuccessView(businessName: _businessNameController.text.trim())
                  : _forceShowForm
                  ? _buildForm()
                  : statusAsync.when(
                      loading: () => const ShimmerBox(width: double.infinity, height: 140, borderRadius: AppRadius.lg),
                      error: (error, _) => _buildForm(),
                      data: (status) => status == null
                          ? _buildForm()
                          : _StatusView(
                              status: status,
                              onApplyAgain: () => setState(() => _forceShowForm = true),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final categoriesAsync = ref.watch(categoriesProvider);

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
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your business name' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('What do you sell?', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          categoriesAsync.when(
            loading: () => const ShimmerBox(width: double.infinity, height: 36, borderRadius: AppRadius.pill),
            error: (error, _) => Text(
              'Couldn\'t load categories.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            data: (categories) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    AppChip(
                      label: categories[i].name,
                      selected: _selectedCategoryId == categories[i].id,
                      onTap: () => setState(() {
                        _selectedCategoryId = categories[i].id;
                        _categoryError = false;
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_categoryError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Pick a category', style: AppTypography.caption.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Phone number',
            controller: _phoneController,
            hint: '024 000 0000',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          _DocumentPickerRow(
            label: 'ID document',
            subtitle: 'A government-issued ID — required for verification',
            file: _idDocument,
            onTap: () => _pickDocument(isIdDocument: true),
          ),
          if (_idDocumentError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Upload your ID document', style: AppTypography.caption.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _DocumentPickerRow(
            label: 'Business certificate',
            subtitle: 'Optional — speeds up review if your business is registered',
            file: _businessCertificate,
            onTap: () => _pickDocument(isIdDocument: false),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Apply to sell', loading: _loading, onPressed: _submit),
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

class _DocumentPickerRow extends StatelessWidget {
  const _DocumentPickerRow({required this.label, required this.subtitle, required this.file, required this.onTap});
  final String label;
  final String subtitle;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: file != null ? AppColors.success : AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: file == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.description_outlined, size: 20, color: AppColors.neutral500),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.file(file!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.label),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (file != null)
              const Icon(Icons.check_circle, size: 20, color: AppColors.success)
            else
              Text(
                'Upload',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentSourceTile extends StatelessWidget {
  const _DocumentSourceTile({required this.icon, required this.label, required this.onTap});
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

/// Shown instead of the form when `GET /sellers/apply/status/` says an
/// application already exists, so a repeat visit doesn't invite a
/// duplicate submission.
class _StatusView extends StatelessWidget {
  const _StatusView({required this.status, required this.onApplyAgain});
  final SellerApplicationStatus status;
  final VoidCallback onApplyAgain;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = status.isApproved
        ? ('Approved', AppBadgeTone.success)
        : status.isRejected
        ? ('Rejected', AppBadgeTone.error)
        : ('Pending review', AppBadgeTone.neutral);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                status.businessName.isEmpty ? 'Your application' : status.businessName,
                style: AppTypography.h3,
              ),
            ),
            AppBadge(label: label, tone: tone),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (status.categoryName.isNotEmpty)
          Text('Category: ${status.categoryName}', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
        const SizedBox(height: AppSpacing.lg),
        if (status.isPending)
          Text(
            'We\'re reviewing your application and will get back to you within 2 business days.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
          )
        else if (status.isRejected) ...[
          ErrorState(
            title: 'Application rejected',
            message: status.reviewerNote.isNotEmpty
                ? status.reviewerNote
                : 'Your application wasn\'t approved this time. Contact support for details.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Apply again', onPressed: onApplyAgain),
        ]
        else
          Text(
            'Your seller account is approved — check your email for next steps.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
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
