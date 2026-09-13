import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/discovery/discovery.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_button.dart';
import '../overlays/app_toast.dart';
import 'network_image_box.dart';

/// Auto-scrolling campaign carousel — backed by `banners` from
/// `GET discovery/home/`. The real banner has a title/subtitle/CTA label
/// but no short all-caps "tag" line like the old mock campaigns did, so
/// that pill is dropped in favor of showing the subtitle as a second line
/// under the title.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.banners});

  final List<DiscoveryBanner> banners;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _controller = PageController();
  int _index = 0;
  Timer? _autoScrollTimer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.banners.length < 2) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = 0;
      _startAutoScroll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final banner in widget.banners) {
      if (banner.image.isNotEmpty) precacheImage(NetworkImage(banner.image), context);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: 190,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final banner = widget.banners[i];
              return RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageBox(
                      url: banner.image,
                      fallbackIcon: Icons.campaign_outlined,
                      cacheWidth: 800,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.82),
                            AppColors.ink.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            banner.title,
                            style: AppTypography.h2.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          if (banner.subtitle.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              banner.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: banner.ctaLabel.isNotEmpty ? banner.ctaLabel : 'Shop now',
                            expand: false,
                            onPressed: () => AppToast.show(
                              context,
                              'Browsing ${banner.title}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Row(
                        children: List.generate(widget.banners.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 4),
                            width: active ? 14 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
