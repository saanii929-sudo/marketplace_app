import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart';
import '../../features/catalog/catalog_controllers.dart';
import '../../features/catalog/product.dart';
import '../../features/cart/cart_controller.dart';
import '../../features/wishlist/wishlist_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/home/product_tile.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/shimmer_box.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    final slug = widget.product.slug;
    if (slug != null && slug.isNotEmpty) {
      Future.microtask(() => ref.read(catalogApiProvider).postProductView(slug));
    }
  }

  Future<void> _addToCart(int? variantId) async {
    final productId = int.tryParse(widget.product.id);
    if (productId == null) {
      AppToast.show(context, 'This product can\'t be added to your cart.', tone: AppToastTone.error);
      return;
    }
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addItem(productId: productId, variantId: variantId, qty: _quantity);
      if (!mounted) return;
      AppToast.show(context, 'Added to cart', tone: AppToastTone.success);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t add that to your cart.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _toggleWishlist() async {
    final productId = int.tryParse(widget.product.id);
    if (productId == null) return;
    try {
      await ref.read(wishlistControllerProvider.notifier).toggle(productId);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your wishlist.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productId = int.tryParse(product.id);
    final wishlisted = ref.watch(wishlistControllerProvider).value?.has(productId ?? -1) ?? false;
    final discount = product.discountPercent;
    final topInset = MediaQuery.of(context).padding.top;
    final slug = product.slug;

    final detailAsync = slug != null && slug.isNotEmpty ? ref.watch(productDetailProvider(slug)) : null;
    final reviewsAsync = slug != null && slug.isNotEmpty ? ref.watch(productReviewsProvider(slug)) : null;
    final detail = detailAsync?.value;

    final related = detail != null
        ? detail.relatedProducts.map((p) => p.toProduct()).toList()
        : (slug == null ? mockProducts.where((p) => p.category == product.category && p.id != product.id).toList() : <Product>[]);

    final galleryImages = detail != null && detail.images.isNotEmpty
        ? detail.images.map((i) => i.url).toList()
        : [product.imageUrl];
    final selectedImageIndex = _selectedImageIndex.clamp(0, galleryImages.length - 1);

    final variants = detail?.variants ?? const [];
    final sizes = variants.map((v) => v.size).where((s) => s.isNotEmpty).toSet().toList();
    final legacySizes = slug == null ? productSizes : const <String>[];
    final effectiveSizes = sizes.isNotEmpty ? sizes : legacySizes;
    final effectiveSelectedSize = _selectedSize ?? (effectiveSizes.isNotEmpty ? effectiveSizes.first : null);
    final selectedVariant = sizes.isNotEmpty && effectiveSelectedSize != null
        ? variants.firstWhere((v) => v.size == effectiveSelectedSize, orElse: () => variants.first)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.60,
                  child: NetworkImageBox(
                    url: galleryImages[selectedImageIndex],
                    fallbackIcon: product.icon,
                    cacheWidth: 800,
                  ),
                ),
                Positioned(
                  top: topInset + AppSpacing.sm,
                  left: AppSpacing.lg,
                  child: const AppBackButton(),
                ),
                Positioned(
                  top: topInset + AppSpacing.sm,
                  right: AppSpacing.lg,
                  child: GestureDetector(
                    onTap: _toggleWishlist,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        wishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: wishlisted ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (galleryImages.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: galleryImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final isSelected = i == selectedImageIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: isSelected ? AppColors.ink : Colors.transparent, width: 2),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: NetworkImageBox(
                          url: galleryImages[i],
                          fallbackIcon: product.icon,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          cacheWidth: 160,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(product.name, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _StarRow(rating: product.rating),
                      const SizedBox(width: 6),
                      Text(
                        '${product.rating.toStringAsFixed(1)} · ${product.reviewCount} reviews',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: AppTypography.h2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            formatPrice(product.originalPrice!),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                      if (discount != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: AppBadge(
                            label: '-$discount%',
                            tone: AppBadgeTone.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (effectiveSizes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Size', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < effectiveSizes.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          _SizeCircle(
                            label: effectiveSizes[i],
                            selected: effectiveSizes[i] == effectiveSelectedSize,
                            onTap: () => setState(() => _selectedSize = effectiveSizes[i]),
                          ),
                        ],
                      ],
                    ),
                  ] else if (slug != null && detailAsync != null && detailAsync.isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Size', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          const ShimmerBox(width: 44, height: 44, borderRadius: 22),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Description', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  if (slug == null)
                    Text(
                      product.description,
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral600),
                    )
                  else
                    detailAsync!.when(
                      loading: () => const _TextBlockShimmer(),
                      error: (error, _) => Text(
                        'Couldn\'t load the full description.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                      data: (d) => Text(
                        d.description.isEmpty ? product.description : d.description,
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.neutral600),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Details', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(label: 'Brand', value: product.brand),
                  _DetailRow(label: 'Category', value: product.category),
                  _DetailRow(label: 'SKU', value: detail?.sku.isNotEmpty == true ? detail!.sku : product.sku),
                  _DetailRow(
                    label: 'Delivery',
                    value: '2–5 business days',
                    showDivider: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Sold by', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  if (slug == null)
                    _SellerCard(seller: sellerForProduct(product))
                  else
                    detailAsync!.when(
                      loading: () => const ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.lg),
                      error: (error, _) => const SizedBox.shrink(),
                      data: (d) => d.seller != null
                          ? _RealSellerCard(seller: d.seller!)
                          : _SellerCard(seller: sellerForProduct(product)),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Ratings & reviews', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.md),
                  if (slug == null) ...[
                    for (var i = 0; i < ratingBreakdown.length; i++) ...[
                      _RatingBar(stars: 5 - i, percent: ratingBreakdown[i]),
                      if (i < ratingBreakdown.length - 1) const SizedBox(height: 6),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < mockReviews.length; i++) ...[
                      _MockReviewTile(review: mockReviews[i]),
                      if (i < mockReviews.length - 1) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ] else
                    reviewsAsync!.when(
                      loading: () => const _TextBlockShimmer(),
                      error: (error, _) => Text(
                        'Couldn\'t load reviews.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                      data: (reviews) => reviews.isEmpty
                          ? Text(
                              'No reviews yet — be the first to review this product.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < _breakdown(reviews).length; i++) ...[
                                  _RatingBar(stars: 5 - i, percent: _breakdown(reviews)[i]),
                                  if (i < 4) const SizedBox(height: 6),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                for (var i = 0; i < reviews.length; i++) ...[
                                  _ReviewTile(review: reviews[i]),
                                  if (i < reviews.length - 1) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    const Divider(),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ],
                            ),
                    ),
                ],
              ),
            ),
            if (related.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('You may also like', style: AppTypography.h3),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    for (var i = 0; i < related.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.md),
                      ProductTile(product: related[i]),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 110),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _QtyStepper(
                quantity: _quantity,
                onDecrement: () =>
                    setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                onIncrement: () =>
                    setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label:
                      'Add to Cart · ${formatPrice(product.price * _quantity)}',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () => _addToCart(selectedVariant?.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Best-effort per-star percentage breakdown computed from the fetched
/// review page itself — the given API describes the reviews endpoint as
/// including "a rating histogram" but its documented response schema
/// doesn't actually expose one, so this is the closest honest substitute
/// rather than guessing at an undocumented field name.
List<int> _breakdown(List<ProductReview> reviews) {
  if (reviews.isEmpty) return const [0, 0, 0, 0, 0];
  final counts = List.filled(5, 0);
  for (final review in reviews) {
    final star = review.rating.clamp(1, 5);
    counts[5 - star]++;
  }
  return counts.map((c) => ((c / reviews.length) * 100).round()).toList();
}

class _TextBlockShimmer extends StatelessWidget {
  const _TextBlockShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 8),
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 8),
        ShimmerBox(width: 160, height: 14),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final filled = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: AppColors.warning,
        );
      }),
    );
  }
}

class _SizeCircle extends StatelessWidget {
  const _SizeCircle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});
  final Seller seller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: AppColors.ink,
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
                            seller.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (seller.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 15,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          seller.rating.toStringAsFixed(1),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            seller.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Visit store',
            variant: AppButtonVariant.secondary,
            onPressed: () => AppToast.show(context, 'Opening ${seller.name}'),
          ),
        ],
      ),
    );
  }
}

/// Same layout as [_SellerCard] but sourced from the real product detail's
/// `seller` object instead of the deterministic mock stand-in.
class _RealSellerCard extends StatelessWidget {
  const _RealSellerCard({required this.seller});
  final CatalogSeller seller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.ink),
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
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (seller.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 15, color: AppColors.success),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(seller.rating.toStringAsFixed(1), style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (seller.tagline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(seller.tagline, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Visit store',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SellerProfileScreen(slug: seller.slug)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.stars, required this.percent});
  final int stars;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text('$stars★', style: AppTypography.caption),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.neutral100,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 36,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: AppTypography.caption,
          ),
        ),
      ],
    );
  }
}

class _MockReviewTile extends StatelessWidget {
  const _MockReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.name,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 14,
              color: AppColors.warning,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          review.text,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.userName,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 14,
              color: AppColors.warning,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          review.comment,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
    );
  }
}
