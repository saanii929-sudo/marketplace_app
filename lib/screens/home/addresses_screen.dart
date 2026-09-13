import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/addresses/address.dart';
import '../../features/addresses/addresses_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'address_form_screen.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _setDefault(BuildContext context, WidgetRef ref, Address address) async {
    try {
      await ref.read(addressesControllerProvider.notifier).setDefault(address.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update your default address.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Address address) async {
    try {
      await ref.read(addressesControllerProvider.notifier).delete(address.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t delete that address.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved addresses', style: AppTypography.h2),
                    Text('Where we deliver your gear', style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            addressesAsync.when(
              loading: () => const AddressListShimmer(),
              error: (error, stackTrace) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your addresses.',
                onRetry: () => ref.read(addressesControllerProvider.notifier).refresh(),
              ),
              data: (addresses) => Column(
                children: [
                  for (final address in addresses) ...[
                    _AddressCard(
                      address: address,
                      onSetDefault: () => _setDefault(context, ref, address),
                      onDelete: () => _delete(context, ref, address),
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddressFormScreen(existing: address)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            AppButton(
              label: '+ Add new address',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressFormScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onSetDefault, required this.onDelete, required this.onEdit});
  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(address.label, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              if (address.isDefault) ...[const SizedBox(width: AppSpacing.sm), const _DefaultPill()],
            ],
          ),
          const SizedBox(height: 4),
          Text(address.fullAddress, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
          const SizedBox(height: AppSpacing.md),
          if (address.isDefault)
            AppButton(label: 'Edit', variant: AppButtonVariant.secondary, onPressed: onEdit)
          else
            Row(
              children: [
                Expanded(child: _CompactButton(label: 'Set as default', onPressed: onSetDefault)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _CompactButton(label: 'Edit', onPressed: onEdit)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _CompactButton(label: 'Delete', foregroundColor: AppColors.error, onPressed: onDelete)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Small solid black "Default" pill (distinct from the tone-based [AppBadge]
/// palette, matching the reference design).
class _DefaultPill extends StatelessWidget {
  const _DefaultPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text('Default', style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
    );
  }
}

/// Compact outlined button for the 2-3-across action rows on an address
/// card. Unlike [AppButton] (whose label sits in a `Row(mainAxisSize.min)`,
/// which always demands its full unwrapped width regardless of how little
/// space is available), this passes [Text] straight through as the button's
/// child so it can wrap to a second line instead of overflowing when three
/// of these share a row.
class _CompactButton extends StatelessWidget {
  const _CompactButton({required this.label, required this.onPressed, this.foregroundColor});
  final String label;
  final VoidCallback onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? AppColors.ink;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
