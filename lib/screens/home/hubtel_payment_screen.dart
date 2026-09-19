import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/checkout/checkout_controllers.dart';
import '../../features/checkout/hubtel_status.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import 'order_detail_screen.dart';

class HubtelPaymentScreen extends ConsumerStatefulWidget {
  const HubtelPaymentScreen({super.key, required this.reference});

  final String reference;

  @override
  ConsumerState<HubtelPaymentScreen> createState() => _HubtelPaymentScreenState();
}

class _HubtelPaymentScreenState extends ConsumerState<HubtelPaymentScreen> with WidgetsBindingObserver {
  Timer? _pollTimer;
  final _pollingStartedAt = DateTime.now();
  bool _hasAutoLaunched = false;
  bool _navigatedOnSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(hubtelCheckoutStatusProvider(widget.reference));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (DateTime.now().difference(_pollingStartedAt) > const Duration(minutes: 3)) {
        _pollTimer?.cancel();
        return;
      }
      if (mounted) ref.invalidate(hubtelCheckoutStatusProvider(widget.reference));
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

  void _handleStatus(HubtelCheckoutStatus status) {
    if (!_hasAutoLaunched && status.isPending && status.checkoutUrl.isNotEmpty) {
      _hasAutoLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckoutUrl(status.checkoutUrl));
    }
    final order = status.order;
    if (status.isSuccess && order != null && !_navigatedOnSuccess) {
      _navigatedOnSuccess = true;
      _pollTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: order.orderNumber)),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(hubtelCheckoutStatusProvider(widget.reference));
    statusAsync.whenData(_handleStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: statusAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) => Center(
              child: ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t check your payment status.',
                onRetry: () => ref.invalidate(hubtelCheckoutStatusProvider(widget.reference)),
              ),
            ),
            data: (status) => status.isFailure
                ? _FailureView(status: status)
                : _WaitingView(
                    status: status,
                    onOpenAgain: () => _openCheckoutUrl(status.checkoutUrl),
                    onCheckNow: () => ref.invalidate(hubtelCheckoutStatusProvider(widget.reference)),
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
    required this.onOpenAgain,
    required this.onCheckNow,
  });

  final HubtelCheckoutStatus status;
  final VoidCallback onOpenAgain;
  final VoidCallback onCheckNow;

  @override
  Widget build(BuildContext context) {
    final total = status.order?.total;
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
        if (status.reference.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ref: ${status.reference}${total != null ? ' · ${formatPrice(total)}' : ''}',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
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
  final HubtelCheckoutStatus status;

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
                : 'Your Hubtel payment wasn\'t completed. Your order has been saved — contact support to retry it.',
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
