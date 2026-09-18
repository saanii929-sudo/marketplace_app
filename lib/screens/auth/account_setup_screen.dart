import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_profile.dart';
import '../../features/auth/session.dart';
import '../../features/profile/profile_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../home/home_shell.dart';
import '../onboarding/welcome_screen.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final Set<String> _selectedSports = {};
  File? _avatarFile;
  bool _loading = false;

  Future<void> _pickAvatarSource() async {
    await AppModal.show(
      context,
      title: 'Add a profile photo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarSourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AvatarSourceTile(
            icon: Icons.photo_outlined,
            label: 'Choose from gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      final avatarFile = _avatarFile;
      if (avatarFile != null) {
        await ref.read(profileControllerProvider.notifier).uploadAvatar(avatarFile);
      }
      // Interests can't be submitted from here yet — see the note on
      // ProfileController.updateInterestIds: there's no categories-list
      // endpoint to resolve IDs for a brand-new account with no interests
      // on file, so this selection stays local-only for now.
      if (!mounted) return;
      await _enterApp();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t save your photo. You can add it later from your profile.',
        tone: AppToastTone.error,
      );
      await _enterApp();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// This app is customer-only — confirm the newly created account really
  /// is a customer before landing in Home (in the unexpected case it
  /// isn't, send them to Welcome instead).
  Future<void> _enterApp() async {
    final status = await resolveSessionStatus(ref);
    if (!mounted) return;
    final destination = status == SessionStatus.authenticatedCustomer
        ? const HomeShell()
        : const WelcomeScreen(notice: 'This app is for customer accounts only.');
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => destination), (route) => false);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Last step', style: AppTypography.caption),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tell us what\nyou play', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We\'ll tailor picks and deals to the sports you care about. You can change this anytime.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  GestureDetector(
                    onTap: _pickAvatarSource,
                    child: Row(
                      children: [
                        CustomPaint(
                          painter: _avatarFile == null
                              ? _DashedCirclePainter(color: AppColors.neutral400)
                              : null,
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: _avatarFile == null
                                ? const Center(
                                    child: Icon(Icons.add, size: 22, color: AppColors.neutral500),
                                  )
                                : ClipOval(child: Image.file(_avatarFile!, fit: BoxFit.cover)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add a profile photo',
                                style: AppTypography.label,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Optional — helps sellers recognize you',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Your interests', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: sportInterests.map((sport) {
                      final selected = _selectedSports.contains(sport);
                      return AppChip(
                        label: sport,
                        selected: selected,
                        onTap: () => setState(() {
                          selected
                              ? _selectedSports.remove(sport)
                              : _selectedSports.add(sport);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppButton(
                    label: 'Start shopping',
                    loading: _loading,
                    onPressed: _finish,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashCount = 24;
    const dashSweep = (2 * math.pi / dashCount) * 0.6;
    for (var i = 0; i < dashCount; i++) {
      final start = i * (2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AvatarSourceTile extends StatelessWidget {
  const _AvatarSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
