import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

String _twoDigit(int n) => n.toString().padLeft(2, '0');

String formatCountdown(Duration d) => '${_twoDigit(d.inHours)}:${_twoDigit(d.inMinutes % 60)}:${_twoDigit(d.inSeconds % 60)}';

/// Ticks a [Duration] down to zero once a second, handing the remaining
/// time to [builder]. Shared by [CountdownTimer] and [CountdownPill].
class CountdownBuilder extends StatefulWidget {
  const CountdownBuilder({super.key, required this.duration, required this.builder});

  final Duration duration;
  final Widget Function(BuildContext context, Duration remaining) builder;

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder> {
  late Duration _remaining = widget.duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}

/// Small `HH:MM:SS` countdown with a timer icon, used on flash-deal cards.
class CountdownTimer extends StatelessWidget {
  const CountdownTimer({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return CountdownBuilder(
      duration: duration,
      builder: (context, remaining) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            formatCountdown(remaining),
            style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Black "Ends HH:MM:SS" pill used next to the Flash Deals section header.
class CountdownPill extends StatelessWidget {
  const CountdownPill({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return CountdownBuilder(
      duration: duration,
      builder: (context, remaining) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          'Ends ${formatCountdown(remaining)}',
          style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
