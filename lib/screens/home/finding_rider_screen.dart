import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/parcels/parcels_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import 'package_detail_screen.dart';

class FindingRiderScreen extends ConsumerStatefulWidget {
  const FindingRiderScreen({super.key, required this.parcelId});

  final int parcelId;

  @override
  ConsumerState<FindingRiderScreen> createState() => _FindingRiderScreenState();
}

class _FindingRiderScreenState extends ConsumerState<FindingRiderScreen> with TickerProviderStateMixin {
  late final AnimationController _innerController =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _outerController =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  Timer? _pollTimer;
  final _startedAt = DateTime.now();
  String? _startError;
  String? _initialStatus;
  bool _navigated = false;
  bool _slowNotice = false;

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  @override
  void dispose() {
    _innerController.dispose();
    _outerController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSearch() async {
    setState(() => _startError = null);
    try {
      await ref.read(parcelsApiProvider).findRider(widget.parcelId);
      if (!mounted) return;
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startError = e is ApiException ? e.message : 'Couldn\'t find a rider right now. Please try again.';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    if (!_slowNotice && DateTime.now().difference(_startedAt) > const Duration(minutes: 2)) {
      setState(() => _slowNotice = true);
    }
    try {
      final parcels = await ref.read(parcelsApiProvider).getParcels();
      final matches = parcels.where((p) => p.id == widget.parcelId);
      if (matches.isEmpty || !mounted) return;
      final parcel = matches.first;
      _initialStatus ??= parcel.status;

      if (parcel.isCancelled) {
        _pollTimer?.cancel();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (!_navigated && parcel.status != _initialStatus) {
        _navigated = true;
        _pollTimer?.cancel();
        ref.invalidate(parcelsProvider);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => PackageDetailScreen(parcelId: widget.parcelId)));
      }
    } catch (_) {
      // Best-effort — keep polling through a transient failure.
    }
  }

  Future<void> _cancel() async {
    final confirmed = await AppModal.confirm(
      context,
      title: 'Stop looking for a rider?',
      message: 'This will cancel your courier request.',
      confirmLabel: 'Cancel request',
    );
    if (confirmed != true) return;
    try {
      await ref.read(parcelsApiProvider).cancel(widget.parcelId);
      ref.invalidate(parcelsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t cancel. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  void _tapDot() {
    AppModal.show<void>(
      context,
      title: 'Nearby rider',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
            child: const Icon(Icons.pedal_bike, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rider nearby', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'We\'ll show real rider details once one accepts your request.',
                  style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              if (_startError != null) ...[
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _startError!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: 'Try again', onPressed: _startSearch),
              ] else ...[
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _Ring(controller: _outerController, radius: 120, dotCount: 6, dotSize: 14, onTapDot: _tapDot),
                      _Ring(controller: _innerController, radius: 70, dotCount: 3, dotSize: 16, onTapDot: _tapDot),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_outlined, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Finding your rider...',
                  style: AppTypography.h2.copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _slowNotice
                      ? 'This is taking longer than usual, but we\'re still looking.'
                      : 'We\'re matching you with a nearby rider — this usually takes under a minute.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral400),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              AppButton(label: 'Cancel', variant: AppButtonVariant.ghost, onPressed: _cancel),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.controller, required this.radius, required this.dotCount, required this.dotSize, this.onTapDot});
  final AnimationController controller;
  final double radius;
  final int dotCount;
  final double dotSize;
  final VoidCallback? onTapDot;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.rotate(angle: controller.value * 2 * pi, child: child),
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutral700, width: 1),
              ),
            ),
            for (var i = 0; i < dotCount; i++)
              _RingDot(angle: (2 * pi / dotCount) * i, radius: radius, size: dotSize, onTap: onTapDot),
          ],
        ),
      ),
    );
  }
}

class _RingDot extends StatelessWidget {
  const _RingDot({required this.angle, required this.radius, required this.size, this.onTap});
  final double angle;
  final double radius;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(radius * cos(angle), radius * sin(angle)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Icon(Icons.pedal_bike, size: size * 0.6, color: AppColors.white),
        ),
      ),
    );
  }
}
