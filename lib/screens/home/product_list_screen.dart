import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart' show Product;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/home/product_tile.dart';
import '../../widgets/states/empty_state.dart';

/// Full-grid view behind a rail's "See all" — shows everything already
/// fetched for that rail (Home's discovery arrays aren't paginated, so
/// there's nothing more to load beyond what the rail already has).
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key, required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.h2),
                      Text(
                        '${products.length} item${products.length == 1 ? '' : 's'}',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nothing here yet',
                      message: 'Check back soon for more.',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
                          return Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              for (final product in products) ProductTile(product: product, width: tileWidth),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
