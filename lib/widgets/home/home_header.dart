import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../overlays/app_modal.dart';
import '../overlays/app_toast.dart';

const _cities = ['Accra, GH', 'Lagos, NG', 'Nairobi, KE', 'Cairo, EG', 'Johannesburg, ZA'];

/// Home screen header: tappable delivery-location pill and a notification
/// bell with an unread count badge.
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _city = _cities.first;
  int _unreadCount = 3;

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
            onTap: () {
              setState(() => _unreadCount = 0);
              AppToast.show(context, 'No new notifications');
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 26, color: AppColors.ink),
                if (_unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '$_unreadCount',
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
