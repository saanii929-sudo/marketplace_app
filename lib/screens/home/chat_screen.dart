import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/chat/chat_controllers.dart';
import '../../features/chat/chat_models.dart';
import '../../features/chat/chat_socket.dart';
import '../../features/profile/profile_controller.dart';
import '../../network/api_exception.dart';
import '../../network/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/buttons/app_back_button.dart';
import '../../widgets/home/network_image_box.dart';
import '../../widgets/overlays/app_toast.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/shimmer_box.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, required this.title, this.avatarUrl});

  final int conversationId;
  final String title;
  final String? avatarUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <Message>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  bool _sending = false;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _channel?.sink.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final history = await ref.read(chatApiProvider).getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
      });
      _scrollToBottomSoon();
      unawaited(ref.read(chatApiProvider).markRead(widget.conversationId).catchError((_) {}));
      unawaited(_connectSocket());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Couldn\'t load this conversation.';
      });
    }
  }

  Future<void> _connectSocket() async {
    final token = await TokenStorage.instance.readAccess();
    if (token == null || token.isEmpty || !mounted) return;
    final channel = WebSocketChannel.connect(
      buildChatSocketUri(conversationId: widget.conversationId, accessToken: token),
    );
    _channel = channel;
    _socketSub = channel.stream.listen(_onSocketEvent, onError: (_) {}, cancelOnError: false);
  }

  void _onSocketEvent(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['type'] != 'message') return;
      _appendIfNew(Message.fromJson(decoded['message'] as Map<String, dynamic>));
    } catch (_) {
      // Ignore malformed/unrecognized socket frames rather than crash.
    }
  }

  void _appendIfNew(Message message) {
    if (_messages.any((m) => m.id == message.id)) return;
    if (!mounted) return;
    setState(() => _messages.add(message));
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      final sent = await ref.read(chatApiProvider).sendMessage(widget.conversationId, text);
      _appendIfNew(sent);
    } catch (e) {
      if (!mounted) return;
      _inputController.text = text;
      AppToast.show(
        context,
        e is ApiException ? e.message : 'Couldn\'t send that message. Please try again.',
        tone: AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(profileControllerProvider).value?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: NetworkImageBox(
                      url: widget.avatarUrl ?? '',
                      fallbackIcon: Icons.support_agent_outlined,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const _ChatShimmer()
                  : _error != null
                  ? Center(
                      child: ErrorState(
                        title: 'Something went wrong',
                        message: _error!,
                        onRetry: () {
                          setState(() => _loading = true);
                          _load();
                        },
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say hello — messages sent here arrive instantly.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(message: message, isMine: myId != null && message.senderId == myId);
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral400),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 20, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.ink : AppColors.surface,
          border: isMine ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : 2),
            bottomRight: Radius.circular(isMine ? 2 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: AppTypography.bodyMedium.copyWith(color: isMine ? AppColors.white : AppColors.ink),
            ),
            if (message.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt!),
                style: AppTypography.caption.copyWith(
                  color: isMine ? AppColors.neutral300 : AppColors.neutral500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < 5; i++) ...[
            Align(
              alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: ShimmerBox(width: 180 - (i * 10), height: 40, borderRadius: AppRadius.lg),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
