import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/catalog_controllers.dart';
import '../../features/chat/chat_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/home/product_tile.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'chat_screen.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key, required this.slug});

  final String slug;

  Future<void> _messageSeller(BuildContext context, WidgetRef ref, String businessName, String logo) async {
    try {
      final conversation = await ref
          .read(chatApiProvider)
          .startConversation(kind: 'customer_seller', sellerSlug: slug);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            title: businessName,
            avatarUrl: logo,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t start a chat right now. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider(slug));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: sellerAsync.when(
          loading: () => const _SellerProfileShimmer(),
          error: (error, _) => ErrorState(
            title: 'Something went wrong',
            message: error is ApiException ? error.message : 'Couldn\'t load this store.',
            onRetry: () => ref.invalidate(sellerProfileProvider(slug)),
          ),
          data: (seller) => ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: NetworkImageBox(
                      url: seller.logo,
                      fallbackIcon: Icons.storefront_outlined,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                seller.businessName,
                                style: AppTypography.h2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (seller.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 20, color: AppColors.success),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(seller.rating.toStringAsFixed(1), style: AppTypography.bodyMedium),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${seller.productCount} product${seller.productCount == 1 ? '' : 's'}',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                        if (seller.isFeatured) ...[
                          const SizedBox(height: 6),
                          const AppBadge(label: 'Featured seller', tone: AppBadgeTone.accent),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (seller.tagline.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(seller.tagline, style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral600)),
              ],
              if (seller.supportPhone.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.neutral500),
                    const SizedBox(width: AppSpacing.xs),
                    Text(seller.supportPhone, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Message seller',
                icon: Icons.chat_bubble_outline,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () => _messageSeller(context, ref, seller.businessName, seller.logo),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              Text('Products', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              if (seller.products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No products listed yet.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final product in seller.products)
                          ProductTile(product: product.toProduct(), width: tileWidth),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerProfileShimmer extends StatelessWidget {
  const _SellerProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: [
        AppBackButton(onTap: () => Navigator.of(context).pop()),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const ShimmerBox(width: 64, height: 64, borderRadius: AppRadius.lg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 20),
                  const SizedBox(height: AppSpacing.sm),
                  ShimmerBox(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const ProductGridShimmer(),
      ],
    );
  }
}
