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
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import '../home/help_support_screen.dart';
import '../onboarding/welcome_screen.dart';
import 'rider_bank_screen.dart';
import 'rider_documents_view_screen.dart';
import 'rider_ratings_screen.dart';
import 'rider_vehicle_screen.dart';

class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  bool? _pushNotificationsOverride;
  bool? _onlyAcceptTripsOver15Override;

  Future<void> _setPushNotifications(bool value) async {
    final previous = _pushNotificationsOverride;
    setState(() => _pushNotificationsOverride = value);
    try {
      await ref.read(ridersApiProvider).updateSettings(pushNotificationsEnabled: value);
      ref.invalidate(riderSettingsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pushNotificationsOverride = previous);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update that setting. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _setOnlyAcceptTripsOver15(bool value) async {
    final previous = _onlyAcceptTripsOver15Override;
    setState(() => _onlyAcceptTripsOver15Override = value);
    try {
      await ref.read(ridersApiProvider).updateSettings(minTripValue: value ? 15 : 0);
      ref.invalidate(riderSettingsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _onlyAcceptTripsOver15Override = previous);
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t update that setting. Please try again.',
        tone: AppToastTone.error,
      );
    }
  }

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
    final settingsAsync = ref.watch(riderSettingsProvider);

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
                              settingsAsync.value?.ratingAvg.toStringAsFixed(1) ?? '—',
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
                  Expanded(
                    child: _StatCard(
                      value: settingsAsync.value?.formattedAcceptanceRate ?? '—',
                      label: 'Acceptance',
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
                        value: _pushNotificationsOverride ?? settingsAsync.value?.pushNotificationsEnabled ?? true,
                        activeTrackColor: AppColors.success,
                        onChanged: settingsAsync.value == null ? null : _setPushNotifications,
                      ),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.help_outline,
                      label: 'Only accept trips over GH₵15',
                      trailing: Switch(
                        value:
                            _onlyAcceptTripsOver15Override ?? ((settingsAsync.value?.minTripValue ?? 0) > 0),
                        activeTrackColor: AppColors.success,
                        onChanged: settingsAsync.value == null ? null : _setOnlyAcceptTripsOver15,
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
