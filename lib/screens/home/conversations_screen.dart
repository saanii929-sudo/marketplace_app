import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/chat_controllers.dart';
import '../../features/chat/chat_models.dart';
import '../../network/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

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
                Text('Messages', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            conversationsAsync.when(
              loading: () => const _ConversationsShimmer(),
              error: (error, _) => ErrorState(
                title: 'Something went wrong',
                message: error is ApiException ? error.message : 'Couldn\'t load your messages.',
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (conversations) => conversations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          'No conversations yet.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final conversation in conversations) ...[
                          _ConversationTile(
                            conversation: conversation,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conversation.id,
                                    title: conversation.displayTitle,
                                    avatarUrl: conversation.seller?.logo,
                                  ),
                                ),
                              ).then((_) => ref.invalidate(conversationsProvider));
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});
  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: NetworkImageBox(
                url: conversation.seller?.logo ?? '',
                fallbackIcon: conversation.seller != null ? Icons.storefront_outlined : Icons.support_agent_outlined,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayTitle,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessagePreview?.body ?? 'No messages yet',
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasUnread ? AppColors.neutral700 : AppColors.neutral500,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastMessageAt != null)
                  Text(
                    _formatConversationTime(conversation.lastMessageAt!),
                    style: AppTypography.caption,
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      '${conversation.unreadCount}',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsShimmer extends StatelessWidget {
  const _ConversationsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          const ShimmerBox(width: double.infinity, height: 76, borderRadius: AppRadius.lg),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

String _formatConversationTime(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
  if (isToday) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}';
}
