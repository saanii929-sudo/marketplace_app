import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/wishlist/wishlist_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/settings_tile.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import '../onboarding/welcome_screen.dart';
import 'addresses_screen.dart';
import 'become_seller_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'orders_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileControllerProvider).value;
    if (profile == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const ProfileShimmer(),
          error: (error, _) => ErrorState(
            title: 'Couldn\'t load your profile',
            message: error is ApiException ? error.message : 'Something went wrong. Please try again.',
            onRetry: () => ref.read(profileControllerProvider.notifier).refresh(),
          ),
          data: (profile) => ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: profile.avatar != null && profile.avatar!.isNotEmpty
                        ? Image.network(
                            profile.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person_outline, size: 30, color: AppColors.neutral400),
                          )
                        : const Icon(Icons.person_outline, size: 30, color: AppColors.neutral400),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isEmpty ? 'Your account' : profile.fullName,
                          style: AppTypography.h3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email.isEmpty ? profile.phone : profile.email,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                  AppBackButton(icon: Icons.edit_outlined, onTap: () => _editProfile(context, ref)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: _StatCard(value: '12', label: 'Orders')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      value: '${ref.watch(wishlistControllerProvider).value?.length ?? 0}',
                      label: 'Wishlist',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(value: '8', label: 'Reviews')),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.shopping_bag_outlined,
                      label: 'My orders',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.location_on_outlined,
                      label: 'Saved addresses',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressesScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.credit_card_outlined,
                      label: 'Payment methods',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Push notifications',
                      trailing: Switch(
                        value: profile.pushNotificationsEnabled,
                        activeTrackColor: AppColors.success,
                        onChanged: (v) async {
                          try {
                            await ref.read(profileControllerProvider.notifier).setPushNotifications(v);
                          } catch (_) {
                            // The controller already reverts the optimistic
                            // update on failure; nothing else to do here.
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.mail_outline,
                      label: 'Email offers',
                      trailing: Switch(
                        value: profile.emailOffersEnabled,
                        activeTrackColor: AppColors.success,
                        onChanged: (v) async {
                          try {
                            await ref.read(profileControllerProvider.notifier).setEmailOffers(v);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.storefront_outlined,
                      label: 'Become a seller',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.help_outline,
                      label: 'Help & support',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  icon: Icons.logout,
                  label: 'Log out',
                  onTap: () => _logout(context, ref),
                ),
              ),
            ],
          ),
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
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(value, style: AppTypography.h2),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
