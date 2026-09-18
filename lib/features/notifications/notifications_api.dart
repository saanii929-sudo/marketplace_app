import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'notification.dart';

class NotificationsApi {
  NotificationsApi(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list() => _guard(() async {
    final notifications = <AppNotification>[];
    String? nextUrl = 'notifications/';
    while (nextUrl != null) {
      final response = await _dio.get<Map<String, dynamic>>(nextUrl);
      final data = response.data!;
      notifications.addAll(
        (data['results'] as List<dynamic>).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)),
      );
      nextUrl = data['next'] as String?;
    }
    return notifications;
  });

  Future<void> markRead(int id) => _guard(() => _dio.post<dynamic>('notifications/$id/read/'));

  Future<void> markAllRead() => _guard(() => _dio.post<dynamic>('notifications/read-all/'));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
