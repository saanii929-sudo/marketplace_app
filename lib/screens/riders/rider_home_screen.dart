import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/mock_catalog.dart' show formatPrice;
import '../../features/profile/profile_controller.dart';
import '../../features/riders/rider_dispatch_socket.dart';
import '../../features/riders/rider_models.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../network/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/overlays/app_toast.dart';
import 'rider_active_delivery_screen.dart';

/// Rider home — online/offline toggle, today's stats, a decorative map
/// placeholder, and live incoming-request dispatch over a WebSocket
/// (`ws/riders/dispatch/?token=`). None of this was empirically verified
/// against a live server at the time this was written — the backend was
/// still deploying — so every parsed field degrades gracefully rather than
/// crashing if something doesn't match.
class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  bool _isOnline = false;
  bool _togglingOnline = false;
  bool _navigatedToActive = false;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;

  @override
  void dispose() {
    _socketSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _setOnline(bool value) async {
    setState(() => _togglingOnline = true);
    try {
      await ref.read(ridersApiProvider).setOnline(value);
      if (!mounted) return;
      setState(() {
        _isOnline = value;
        _togglingOnline = false;
      });
      if (value) {
        _connectDispatch();
      } else {
        _socketSub?.cancel();
        _channel?.sink.close();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _togglingOnline = false);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your status. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _connectDispatch() async {
    final token = await TokenStorage.instance.readAccess();
    if (token == null || token.isEmpty || !mounted) return;
    _socketSub?.cancel();
    _channel?.sink.close();
    final channel = WebSocketChannel.connect(buildRiderDispatchSocketUri(accessToken: token));
    _channel = channel;
    _socketSub = channel.stream.listen(
      _onSocketEvent,
      onError: (_) {},
      onDone: () {
        // Closes with 4001 (bad/missing token) or 4003 (no rider profile)
        // per the backend spec — surface a toast rather than a silent hang.
        if (!mounted || !_isOnline) return;
        final code = channel.closeCode;
        if (code == 4001 || code == 4003) {
          AppToast.show(context, 'Couldn\'t connect for live requests. Please try going online again.', tone: AppToastTone.error);
          setState(() => _isOnline = false);
        }
      },
      cancelOnError: false,
    );
  }

  void _onSocketEvent(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['type'] != 'delivery_request') return;
      final request = RiderDeliveryRequest.fromJson(decoded['request'] as Map<String, dynamic>);
      _showIncomingRequest(request);
    } catch (_) {
      // Ignore malformed/unrecognized frames rather than crash.
    }
  }

  void _showIncomingRequest(RiderDeliveryRequest request) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomingRequestSheet(
        request: request,
        onAccept: () => _accept(request),
        onDecline: () => _decline(request),
      ),
    );
  }

  Future<void> _accept(RiderDeliveryRequest request) async {
    Navigator.of(context).pop();
    try {
      final delivery = await ref.read(ridersApiProvider).acceptRequest(request.id);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => RiderActiveDeliveryScreen(delivery: delivery)));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t accept that request. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _decline(RiderDeliveryRequest request) async {
    Navigator.of(context).pop();
    try {
      await ref.read(ridersApiProvider).declineRequest(request.id);
    } catch (_) {
      // Best-effort — nothing else to do if declining fails server-side.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).value;
    final earningsAsync = ref.watch(riderEarningsSummaryProvider);
    final activeDeliveryAsync = ref.watch(riderActiveDeliveryProvider);

    activeDeliveryAsync.whenData((delivery) {
      if (delivery != null && !_navigatedToActive) {
        _navigatedToActive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => RiderActiveDeliveryScreen(delivery: delivery)));
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.ink,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.neutral700, shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: profile?.avatar != null && profile!.avatar!.isNotEmpty
                        ? Image.network(profile.avatar!, fit: BoxFit.cover)
                        : const Icon(Icons.person_outline, color: AppColors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Rider',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.notifications_none_rounded, color: AppColors.white),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOnline ? 'You\'re online' : 'You\'re offline',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isOnline
                                    ? 'Looking for delivery requests nearby...'
                                    : 'Go online to start receiving delivery requests',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _togglingOnline
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : Switch(
                                value: _isOnline,
                                activeTrackColor: AppColors.success,
                                onChanged: _setOnline,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: formatPrice(earningsAsync.value?.todayEarnings ?? 0),
                          label: 'Today',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _StatCard(value: '${earningsAsync.value?.tripsToday ?? 0}', label: 'Trips')),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          value: '${(earningsAsync.value?.onlineHoursToday ?? 0).toStringAsFixed(1)}h',
                          label: 'Online',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _GridPainter()),
                          const Center(
                            child: Icon(Icons.my_location, color: AppColors.primary, size: 32),
                          ),
                          if (!_isOnline)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'You\'re offline — go online to see nearby requests',
                                  style: AppTypography.caption,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.h3),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral200
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = AppColors.neutral100);
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _IncomingRequestSheet extends StatelessWidget {
  const _IncomingRequestSheet({required this.request, required this.onAccept, required this.onDecline});
  final RiderDeliveryRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text(request.kindLabel, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Est. earning', style: AppTypography.caption),
                  Text(formatPrice(request.amount), style: AppTypography.h1),
                ],
              ),
              Text(
                '${request.distanceKm} km · ~${request.etaMinutes} min',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _RouteRow(label: 'PICKUP', address: request.pickupLabel, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          _RouteRow(label: 'DROPOFF', address: request.dropoffAddress, color: AppColors.success),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDecline,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.label, required this.address, required this.color});
  final String label;
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              Text(address, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
