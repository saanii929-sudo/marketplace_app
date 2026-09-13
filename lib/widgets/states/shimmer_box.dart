import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A single shimmering placeholder block, shaped like the real content
/// it stands in for (a line of text, an avatar, a card).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height = 16, this.borderRadius = AppRadius.sm});

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral50,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(borderRadius)),
      ),
    );
  }
}

/// Skeleton-screen placeholder shaped like [ProfileScreen]'s content —
/// shown while `GET /accounts/me/` is in flight.
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 64, height: 64, borderRadius: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 18),
                    const SizedBox(height: AppSpacing.sm),
                    ShimmerBox(width: 180, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: ShimmerBox(height: 72, borderRadius: AppRadius.lg)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ShimmerBox(width: double.infinity, height: 168, borderRadius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(width: double.infinity, height: 112, borderRadius: AppRadius.lg),
        ],
      ),
    );
  }
}

/// Skeleton-screen placeholder shaped like a handful of address cards —
/// shown while `GET /accounts/addresses/` is in flight.
class AddressListShimmer extends StatelessWidget {
  const AddressListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            ShimmerBox(width: double.infinity, height: 118, borderRadius: AppRadius.lg),
          ],
        ],
      ),
    );
  }
}

/// Skeleton-screen placeholder shaped like a handful of cart line items —
/// shown while `GET /cart/` is in flight.
class CartLinesShimmer extends StatelessWidget {
  const CartLinesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.md),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 100, height: 12),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 160, height: 16),
                      const SizedBox(height: AppSpacing.sm),
                      ShimmerBox(width: 90, height: 28, borderRadius: AppRadius.sm),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled row of shimmering product-tile-shaped blocks, matching
/// [ProductRail]'s layout — shown while a Home discovery rail loads.
class ProductRailShimmer extends StatelessWidget {
  const ProductRailShimmer({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: ShimmerBox(width: 140, height: 20)),
          const SizedBox(height: AppSpacing.md),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                ShimmerBox(width: 168, height: 240, borderRadius: AppRadius.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A wrap of shimmering product-tile-shaped blocks, matching the
/// Categories screen's grid layout.
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key, this.tileWidth = 168});

  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [for (var i = 0; i < 6; i++) ShimmerBox(width: tileWidth, height: 240, borderRadius: AppRadius.md)],
    );
  }
}
