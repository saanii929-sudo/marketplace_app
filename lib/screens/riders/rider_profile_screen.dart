import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/session.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/riders/riders_controllers.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/settings_tile.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import '../home/help_support_screen.dart';
import '../onboarding/welcome_screen.dart';
import 'rider_bank_screen.dart';
import 'rider_documents_view_screen.dart';
import 'rider_ratings_screen.dart';
import 'rider_vehicle_screen.dart';

/// Rider profile — reuses the same `/accounts/me/` call and
/// [profileControllerProvider] the customer app uses (an account's profile
/// isn't role-specific), including its own `date_joined` for "Rider since"
/// instead of a dedicated endpoint. Deliveries count comes from the real
/// earnings summary's `total_trips`. There's no given "acceptance rate"
/// endpoint, so that stat card is dropped rather than fabricated.
class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  // No given endpoint for rider notification preferences — these stay
  // local-only UI state rather than a fabricated persisted setting.
  bool _pushNotificationsEnabled = true;
  bool _onlyAcceptTripsOver15 = false;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    clearUserScopedProviders(ref);
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final earningsAsync = ref.watch(riderEarningsSummaryProvider);
    final reviewSummaryAsync = ref.watch(riderReviewSummaryProvider);

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
                        Text(profile.fullName.isEmpty ? 'Rider' : profile.fullName, style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(
                              reviewSummaryAsync.value?.average.toStringAsFixed(1) ?? '—',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: earningsAsync.value != null ? '${earningsAsync.value!.totalTrips}' : '—',
                      label: 'Deliveries',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(value: _riderSince(profile.dateJoined), label: 'Rider since')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.two_wheeler_outlined,
                      label: 'Vehicle info',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderVehicleScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.description_outlined,
                      label: 'Documents',
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const RiderDocumentsViewScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.credit_card_outlined,
                      label: 'Bank & MoMo',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderBankScreen())),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.star_border_rounded,
                      label: 'Ratings & reviews',
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RiderRatingsScreen())),
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
                        value: _pushNotificationsEnabled,
                        activeTrackColor: AppColors.success,
                        onChanged: (v) => setState(() => _pushNotificationsEnabled = v),
                      ),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.help_outline,
                      label: 'Only accept trips over GH₵15',
                      trailing: Switch(
                        value: _onlyAcceptTripsOver15,
                        activeTrackColor: AppColors.success,
                        onChanged: (v) => setState(() => _onlyAcceptTripsOver15 = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  icon: Icons.help_outline,
                  label: 'Help & support',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
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

String _riderSince(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '—';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} \'${(date.year % 100).toString().padLeft(2, '0')}';
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
          Text(value, style: AppTypography.h3),
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
