import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/layout/responsive_center.dart';
import '../../widgets/overlays/app_modal.dart';
import '../../widgets/overlays/app_toast.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../riders/rider_login_screen.dart';

enum _WelcomeButtonVariant { primary, secondary, outlined }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.notice});

  final String? notice;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final List<Animation<double>> _fades = List.generate(
    3,
    (i) => CurvedAnimation(
      parent: _controller,
      curve: Interval(0.15 * i, 0.15 * i + 0.6, curve: Curves.easeOut),
    ),
  );

  late final List<Animation<Offset>> _slides = List.generate(
    3,
    (i) => Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.15 * i, 0.15 * i + 0.6, curve: Curves.easeOutCubic)),
    ),
  );

  @override
  void initState() {
    super.initState();
    final notice = widget.notice;
    if (notice != null && notice.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppToast.show(context, notice, tone: AppToastTone.error);
      });
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    final confirmed = await AppModal.confirm(
      context,
      title: 'Continue as guest?',
      message: 'You can browse SportTech freely, but you\'ll need an account to check out or track orders.',
      confirmLabel: 'Continue as guest',
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: ResponsiveCenter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _animated(
                          0,
                          _WelcomeButton(
                            label: 'Continue as rider',
                            icon: Icons.two_wheeler_outlined,
                            variant: _WelcomeButtonVariant.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _animated(
                          1,
                          _WelcomeButton(
                            label: 'Continue as customer',
                            icon: Icons.shopping_bag_outlined,
                            variant: _WelcomeButtonVariant.secondary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _animated(
                          2,
                          _WelcomeButton(
                            label: 'Continue as a guest',
                            icon: Icons.explore_outlined,
                            variant: _WelcomeButtonVariant.outlined,
                            onTap: () => _continueAsGuest(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatefulWidget {
  const _WelcomeButton({required this.label, required this.icon, required this.variant, required this.onTap});

  final String label;
  final IconData icon;
  final _WelcomeButtonVariant variant;
  final VoidCallback onTap;

  @override
  State<_WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<_WelcomeButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, Border? border, List<BoxShadow>? shadow) = switch (widget.variant) {
      _WelcomeButtonVariant.primary => (
        AppColors.primary,
        AppColors.white,
        null,
        [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      _WelcomeButtonVariant.secondary => (
        AppColors.surface,
        AppColors.ink,
        Border.all(color: AppColors.ink, width: 1.5),
        null,
      ),
      _WelcomeButtonVariant.outlined => (
        Colors.transparent,
        AppColors.ink,
        Border.all(color: AppColors.neutral300, width: 1.5),
        null,
      ),
    };

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: background,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 32, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTypography.bodyLarge.copyWith(color: foreground, fontWeight: FontWeight.w700, fontSize: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
