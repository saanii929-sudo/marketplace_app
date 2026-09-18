import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/notification.dart';
import '../../features/notifications/notifications_controller.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

const _iconByType = {
  'order_update': Icons.local_shipping_outlined,
  'promo': Icons.local_offer_outlined,
  'seller_update': Icons.storefront_outlined,
};

/// Backed by `GET /notifications/`, `POST /notifications/{id}/read/` and
/// `POST /notifications/read-all/`.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _openNotification(BuildContext context, WidgetRef ref, AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await ref.read(notificationsControllerProvider.notifier).markRead(notification.id);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t mark that as read.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsControllerProvider.notifier).markAllRead();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t mark all as read.',
        tone: AppToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsControllerProvider);
    final hasUnread = notificationsAsync.value?.any((n) => !n.isRead) ?? false;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications', style: AppTypography.h2),
                        Text(
                          'Order updates, promos and more',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread)
                    GestureDetector(
                      onTap: () => _markAllRead(context, ref),
                      child: Text(
                        'Mark all read',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      const ShimmerBox(width: double.infinity, height: 72, borderRadius: AppRadius.lg),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
                error: (error, _) => ErrorState(
                  title: 'Something went wrong',
                  message: error is ApiException ? error.message : 'Couldn\'t load your notifications.',
                  onRetry: () => ref.read(notificationsControllerProvider.notifier).refresh(),
                ),
                data: (notifications) => notifications.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No notifications yet',
                        message: 'Order updates and offers will show up here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) =>
                            _NotificationTile(notification: notifications[i], onTap: () => _openNotification(context, ref, notifications[i])),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconByType[notification.type] ?? Icons.notifications_none_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title.isEmpty ? 'Notification' : notification.title,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notification.body, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral600)),
                  ],
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(_formatDate(notification.createdAt!), style: AppTypography.caption.copyWith(color: AppColors.neutral400)),
                  ],
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
