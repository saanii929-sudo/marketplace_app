import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_catalog.dart' show formatPrice;
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

enum _DeliveryPhase { toPickup, toCustomer }

class RiderActiveDeliveryScreen extends ConsumerStatefulWidget {
  const RiderActiveDeliveryScreen({super.key, required this.delivery});

  final RiderDelivery delivery;

  @override
  ConsumerState<RiderActiveDeliveryScreen> createState() => _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState extends ConsumerState<RiderActiveDeliveryScreen> {
  /// Resuming after a restart can land mid-delivery — `picked_up`/
  /// `heading_to_dropoff` should skip straight to the code-entry step
  /// instead of re-showing "Confirm pickup".
  late _DeliveryPhase _phase =
      widget.delivery.isHeadingToPickup ? _DeliveryPhase.toPickup : _DeliveryPhase.toCustomer;
  final _codeController = TextEditingController();
  File? _proofPhoto;
  bool _confirming = false;
  bool _completing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirmPickup() async {
    setState(() => _confirming = true);
    try {
      await ref.read(ridersApiProvider).confirmPickup(widget.delivery.id);
      if (!mounted) return;
      setState(() {
        _phase = _DeliveryPhase.toCustomer;
        _confirming = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t confirm pickup. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _pickPhoto() async {
    await AppModal.show(
      context,
      title: 'Proof of delivery photo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () async {
              Navigator.of(context).pop();
              final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
              if (picked != null) setState(() => _proofPhoto = File(picked.path));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_outlined,
            label: 'Choose from gallery',
            onTap: () async {
              Navigator.of(context).pop();
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
              if (picked != null) setState(() => _proofPhoto = File(picked.path));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markDelivered() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      AppToast.show(context, 'Enter the 4-digit delivery code.', tone: AppToastTone.error);
      return;
    }
    final photo = _proofPhoto;
    if (photo == null) {
      AppToast.show(context, 'Take a proof-of-delivery photo to continue.', tone: AppToastTone.error);
      return;
    }
    setState(() => _completing = true);
    try {
      final api = ref.read(ridersApiProvider);
      await api.submitProofOfDelivery(widget.delivery.id, otpCode: code, photo: photo);
      await api.completeTrip(widget.delivery.id);
      ref.invalidate(riderActiveDeliveryProvider);
      ref.invalidate(riderDeliveriesProvider);
      ref.invalidate(riderEarningsSummaryProvider);
      ref.invalidate(riderEarningsActivityProvider);
      if (!mounted) return;
      AppToast.show(
        context,
        'Delivered — ${formatPrice(widget.delivery.amount)} added to your balance',
        tone: AppToastTone.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'That code didn\'t match. Please check with the customer and try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = _phase == _DeliveryPhase.toPickup;
    final delivery = widget.delivery;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _RoutePainter(isPickup: isPickup))),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBackButton(onTap: () => Navigator.of(context).pop()),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(
                            isPickup ? 'Heading to pickup' : 'Heading to customer',
                            style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPickup ? const Color(0x1AF5A623) : const Color(0x1A1FA855),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      isPickup ? 'HEADING TO PICKUP' : 'HEADING TO CUSTOMER',
                      style: AppTypography.caption.copyWith(
                        color: isPickup ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Icon(
                          isPickup ? Icons.storefront_outlined : Icons.person_outline,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPickup ? delivery.pickupLabel : delivery.customerName,
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              isPickup ? delivery.pickupAddress : delivery.dropoffAddress,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isPickup) ...[
                    if (delivery.reference.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(color: AppColors.neutral50, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Text('Order #${delivery.reference}', style: AppTypography.bodyMedium),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AppButton(label: 'Confirm pickup', loading: _confirming, onPressed: _confirmPickup),
                  ] else ...[
                    Text('Proof of delivery photo', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: _proofPhoto == null
                                  ? const Icon(Icons.camera_alt_outlined, color: AppColors.neutral500)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Image.file(_proofPhoto!, fit: BoxFit.cover),
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _proofPhoto == null ? 'Take a photo' : 'Photo attached',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Ask the customer for their 4-digit delivery code', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _CodeDigitBox(index: i, controller: _codeController)),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(label: 'Mark as delivered', loading: _completing, onPressed: _markDelivered),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeDigitBox extends StatefulWidget {
  const _CodeDigitBox({required this.index, required this.controller});
  final int index;
  final TextEditingController controller;

  @override
  State<_CodeDigitBox> createState() => _CodeDigitBoxState();
}

class _CodeDigitBoxState extends State<_CodeDigitBox> {
  final _localController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _localController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final digits = widget.controller.text.padRight(4).split('');
    digits[widget.index] = value.isEmpty ? ' ' : value;
    widget.controller.text = digits.join().trimRight();
    if (value.isNotEmpty && widget.index < 3) {
      FocusScope.of(context).nextFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TextField(
        controller: _localController,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.h3,
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: _onChanged,
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

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.isPickup});
  final bool isPickup;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF0EEE7));
    final start = Offset(size.width * 0.2, size.height * 0.85);
    final end = Offset(size.width * 0.75, size.height * 0.15);
    final paint = Paint()
      ..color = isPickup ? AppColors.warning : AppColors.success
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashLength = 8.0;
    final totalDistance = (end - start).distance;
    final dashCount = (totalDistance / (dashLength * 2)).floor();
    for (var i = 0; i < dashCount; i++) {
      final t0 = (i * 2 * dashLength) / totalDistance;
      final t1 = ((i * 2 + 1) * dashLength) / totalDistance;
      canvas.drawLine(Offset.lerp(start, end, t0)!, Offset.lerp(start, end, t1.clamp(0, 1))!, paint);
    }

    canvas.drawCircle(start, 7, Paint()..color = AppColors.ink);
    canvas.drawCircle(end, 7, Paint()..color = isPickup ? AppColors.warning : AppColors.success);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.isPickup != isPickup;
}
