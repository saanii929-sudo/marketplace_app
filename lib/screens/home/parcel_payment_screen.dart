import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/parcels/parcel_models.dart';
import '../../features/parcels/parcels_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import 'finding_rider_screen.dart';

/// Confirmed server-side that `find-rider/` refuses to run until payment
/// lands ("Please complete payment before we can find you a rider"), so
/// this screen sits between parcel creation and the search — same order as
/// Bolt/Uber-style apps, which commit you to the trip before showing
/// "finding your driver."
class ParcelPaymentScreen extends ConsumerStatefulWidget {
  const ParcelPaymentScreen({super.key, required this.parcelId, required this.price});

  final int parcelId;
  final double price;

  @override
  ConsumerState<ParcelPaymentScreen> createState() => _ParcelPaymentScreenState();
}

class _ParcelPaymentScreenState extends ConsumerState<ParcelPaymentScreen> with WidgetsBindingObserver {
  Timer? _pollTimer;
  final _pollingStartedAt = DateTime.now();
  bool _hasAutoLaunched = false;
  bool _navigatedOnSuccess = false;
  ParcelCheckoutStatus? _initialStatus;
  String? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCheckout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialStatus != null) {
      ref.invalidate(parcelCheckoutStatusProvider(widget.parcelId));
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _startError = null);
    try {
      final status = await ref.read(parcelsApiProvider).startCheckout(widget.parcelId);
      if (!mounted) return;
      setState(() => _initialStatus = status);
      _handleStatus(status);
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startError = e is ApiException ? e.message : 'Couldn\'t start payment. Please try again.';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (DateTime.now().difference(_pollingStartedAt) > const Duration(minutes: 10)) {
        _pollTimer?.cancel();
        return;
      }
      if (mounted) ref.invalidate(parcelCheckoutStatusProvider(widget.parcelId));
    });
  }

  Future<void> _openCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 'Couldn\'t open the payment page.', tone: AppToastTone.error);
    }
  }

  void _handleStatus(ParcelCheckoutStatus status) {
    if (!_hasAutoLaunched && status.isPending && status.checkoutUrl.isNotEmpty) {
      _hasAutoLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckoutUrl(status.checkoutUrl));
    }
    if (status.isSuccess && !_navigatedOnSuccess) {
      _navigatedOnSuccess = true;
      _pollTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => FindingRiderScreen(parcelId: widget.parcelId)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F4EE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ErrorState(title: 'Something went wrong', message: _startError!, onRetry: _startCheckout),
            ),
          ),
        ),
      );
    }

    final initialStatus = _initialStatus;
    if (initialStatus == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F4EE),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final statusAsync = ref.watch(parcelCheckoutStatusProvider(widget.parcelId));
    statusAsync.whenData(_handleStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: statusAsync.when(
            loading: () => _WaitingView(
              status: initialStatus,
              price: widget.price,
              onOpenAgain: () => _openCheckoutUrl(initialStatus.checkoutUrl),
              onCheckNow: () => ref.invalidate(parcelCheckoutStatusProvider(widget.parcelId)),
            ),
            error: (error, _) => Center(
              child: ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t check your payment status.',
                onRetry: () => ref.invalidate(parcelCheckoutStatusProvider(widget.parcelId)),
              ),
            ),
            data: (status) => status.isFailure
                ? _FailureView(status: status)
                : _WaitingView(
                    status: status,
                    price: widget.price,
                    onOpenAgain: () => _openCheckoutUrl(status.checkoutUrl),
                    onCheckNow: () => ref.invalidate(parcelCheckoutStatusProvider(widget.parcelId)),
                  ),
          ),
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.status,
    required this.price,
    required this.onOpenAgain,
    required this.onCheckNow,
  });

  final ParcelCheckoutStatus status;
  final double price;
  final VoidCallback onOpenAgain;
  final VoidCallback onCheckNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: AppSpacing.xl),
        Text('Waiting for payment', style: AppTypography.h2, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Complete your payment with Hubtel in the browser. This screen will update automatically once it\'s confirmed.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          status.reference.isNotEmpty ? 'Ref: ${status.reference} · ${formatPrice(price)}' : formatPrice(price),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: 'Open payment page again', onPressed: onOpenAgain),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'I\'ve paid — check now', variant: AppButtonVariant.secondary, onPressed: onCheckNow),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Back to Home',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.status});
  final ParcelCheckoutStatus status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorState(
            title: 'Payment didn\'t go through',
            message: status.failureReason.isNotEmpty
                ? status.failureReason
                : 'Your Hubtel payment wasn\'t completed. Your package request has been saved — try again from Home.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Back to Home',
            expand: false,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
