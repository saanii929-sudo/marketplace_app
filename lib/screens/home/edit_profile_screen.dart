import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_profile.dart' show sportInterests;
import '../../features/profile/profile_controller.dart';
import '../../features/profile/user_profile.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/overlays/app_toast.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.fullName);
  late final _emailController = TextEditingController(text: widget.profile.email);
  late final _phoneController = TextEditingController(text: widget.profile.phone);
  late final _bioController = TextEditingController(text: widget.profile.bio);

  /// Maps a known interest's name (lowercased) to its real category ID —
  /// only interests already on the account can be resolved to an ID (see
  /// the interests gap noted in the plan).
  late final Map<String, int> _knownInterestIds = {
    for (final interest in widget.profile.interests) interest.name.toLowerCase(): interest.id,
  };
  late final Set<String> _selectedInterests = widget.profile.interests.map((i) => i.name).toSet();

  bool _saving = false;
  bool _uploadingAvatar = false;
  File? _pendingAvatarPreview;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _pendingAvatarPreview = file;
      _uploadingAvatar = true;
    });
    try {
      await ref.read(profileControllerProvider.notifier).uploadAvatar(file);
      // The controller's own state now has the new avatar URL; the local
      // file preview stays on screen (same image) so there's no flash back
      // to the old avatar while the network image would otherwise reload.
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingAvatarPreview = null);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t upload that photo. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(fullName: _nameController.text.trim(), bio: _bioController.text.trim());

      final selectedKnownIds = _selectedInterests
          .map((name) => _knownInterestIds[name.toLowerCase()])
          .whereType<int>()
          .toList();
      if (selectedKnownIds.length != _knownInterestIds.length ||
          !_knownInterestIds.values.every(selectedKnownIds.contains)) {
        await ref.read(profileControllerProvider.notifier).updateInterestIds(selectedKnownIds);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t save your changes. Please try again.',
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
                        Text('Edit profile', style: AppTypography.h2),
                        Text(
                          'Keep your details up to date',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: _pendingAvatarPreview != null
                          ? Image.file(_pendingAvatarPreview!, fit: BoxFit.cover)
                          : (widget.profile.avatar != null && widget.profile.avatar!.isNotEmpty)
                          ? Image.network(
                              widget.profile.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person_outline, size: 26, color: AppColors.neutral400),
                            )
                          : const Icon(Icons.person_outline, size: 26, color: AppColors.neutral400),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _changePhoto,
                      child: Text(
                        _uploadingAvatar ? 'Uploading…' : 'Change photo',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Full name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                  helperText: 'Contact support to change your verified email',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  helperText: 'Contact support to change your verified phone',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('About you', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Your interests', style: AppTypography.label),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: sportInterests.map((sport) {
                    final selected = _selectedInterests.contains(sport);
                    return AppChip(
                      label: sport,
                      selected: selected,
                      onTap: () => setState(() {
                        selected ? _selectedInterests.remove(sport) : _selectedInterests.add(sport);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(label: 'Save changes', loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
