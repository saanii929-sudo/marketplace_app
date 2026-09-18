import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/notifications_controller.dart';
import '../../screens/home/notifications_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../overlays/app_modal.dart';

const _cities = ['Accra, GH', 'Lagos, NG', 'Nairobi, KE', 'Cairo, EG', 'Johannesburg, ZA'];

/// Home screen header: tappable delivery-location pill and a notification
/// bell — backed by `GET /notifications/` for the unread count badge.
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  String _city = _cities.first;

  Future<void> _pickCity() async {
    final selected = await AppModal.show<String>(
      context,
      title: 'Deliver to',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _cities.map((city) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              city == _city ? Icons.radio_button_checked : Icons.radio_button_off,
              color: city == _city ? AppColors.primary : AppColors.neutral400,
            ),
            title: Text(city, style: AppTypography.bodyLarge),
            onTap: () => Navigator.of(context).pop(city),
          );
        }).toList(),
      ),
    );
    if (selected != null) setState(() => _city = selected);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _pickCity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.ink),
                const SizedBox(width: 4),
                Text(
                  _city,
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.neutral500),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 26, color: AppColors.ink),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '$unreadCount',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
