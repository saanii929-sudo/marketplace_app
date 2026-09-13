import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_catalog.dart' show mockPopularSearches;
import '../../features/catalog/catalog_controllers.dart';
import '../../features/catalog/product.dart';
import '../../features/discovery/discovery_controllers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/badges/app_badge.dart';
import '../../widgets/overlays/app_toast.dart';

/// Recent searches come from `GET discovery/search/recent/` (seeded once,
/// then kept up to date locally each session); popular searches stay mock
/// since `discovery/search/popular/` has no confirmed schema (see the
/// Phase 2 plan). Product suggestions filter the full real catalog
/// (`allProductsProvider`) client-side, since the products endpoint has no
/// search query param.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String>? _recent;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CatalogProductSummary> _suggestions(List<CatalogProductSummary> allProducts) {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase();
    return allProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.brandName.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q),
        )
        .toList();
  }

  void _search(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _recent = [value, ...?_recent?.where((s) => s != value)].take(6).toList();
      _controller.text = value;
      _query = value;
    });
    ref.read(discoveryApiProvider).logSearch(value);
    AppToast.show(context, 'Searching "$value"');
  }

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(allProductsProvider);
    final recentSearchesAsync = ref.watch(recentSearchesProvider);
    _recent ??= recentSearchesAsync.value?.map((s) => s.queryText).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 18, color: AppColors.neutral500),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              onChanged: (v) => setState(() => _query = v),
                              onSubmitted: _search,
                              style: AppTypography.bodyMedium,
                              decoration: const InputDecoration(
                                hintText: 'Search football boots, jerseys…',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() {
                                _controller.clear();
                                _query = '';
                              }),
                              child: const Icon(Icons.close, size: 18, color: AppColors.neutral500),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                children: _query.trim().isEmpty
                    ? _buildIdleContent(context)
                    : _buildSuggestions(context, allProductsAsync.value ?? const []),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIdleContent(BuildContext context) {
    final recent = _recent ?? const [];
    return [
      if (recent.isNotEmpty) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent searches', style: AppTypography.h3),
            GestureDetector(
              onTap: () => setState(() => _recent = []),
              child: Text(
                'Clear all',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: recent.map((s) => _SearchChip(label: s, icon: Icons.history, onTap: () => _search(s))).toList(),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
      Text('Popular searches', style: AppTypography.h3),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: mockPopularSearches
            .map((s) => _SearchChip(label: s, icon: Icons.trending_up, onTap: () => _search(s)))
            .toList(),
      ),
    ];
  }

  List<Widget> _buildSuggestions(BuildContext context, List<CatalogProductSummary> allProducts) {
    final results = _suggestions(allProducts);
    if (results.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Text('No matches for "$_query"', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
        ),
      ];
    }
    return results.map((summary) {
      final product = summary.toProduct();
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(product.icon, size: 20, color: AppColors.neutral500),
        ),
        title: Text(product.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${product.brand} · ${product.category}', style: AppTypography.caption),
        trailing: product.badgeLabel != null ? AppBadge(label: product.badgeLabel!, tone: AppBadgeTone.accent) : null,
        onTap: () => _search(product.name),
      );
    }).toList();
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.neutral500),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
