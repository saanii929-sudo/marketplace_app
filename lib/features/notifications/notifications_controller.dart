import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import 'notification.dart';
import 'notifications_api.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(dioProvider)));

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() => ref.read(notificationsApiProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(notificationsApiProvider).list());
  }

  /// Optimistically flips the local item to read so the badge/UI update
  /// instantly, then confirms with the server.
  Future<void> markRead(int id) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData([for (final n in current) n.id == id ? n.copyWith(isRead: true) : n]);
    }
    try {
      await ref.read(notificationsApiProvider).markRead(id);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
    }
    try {
      await ref.read(notificationsApiProvider).markAllRead();
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

final notificationsControllerProvider = AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

final unreadNotificationsCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsControllerProvider).value?.where((n) => !n.isRead).length ?? 0,
);
