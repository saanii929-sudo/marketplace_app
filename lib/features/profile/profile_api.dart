import 'dart:io';

import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'user_profile.dart';

class ProfileApi {
  ProfileApi(this._dio);
  final Dio _dio;

  Future<UserProfile> getMe() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('accounts/me/');
    return UserProfile.fromJson(response.data!);
  });

  Future<UserProfile> updateMe({
    String? fullName,
    String? avatar,
    String? bio,
    bool? pushNotificationsEnabled,
    bool? emailOffersEnabled,
  }) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'accounts/me/',
      data: {
        'full_name': ?fullName,
        'avatar': ?avatar,
        'bio': ?bio,
        'push_notifications_enabled': ?pushNotificationsEnabled,
        'email_offers_enabled': ?emailOffersEnabled,
      },
    );
    return UserProfile.fromJson(response.data!);
  });

  /// Uploads a new avatar image and returns its URL.
  Future<String> uploadAvatar(File file) => _guard(() async {
    final form = FormData.fromMap({'avatar': await MultipartFile.fromFile(file.path)});
    final response = await _dio.post<Map<String, dynamic>>('accounts/me/avatar/', data: form);
    return response.data!['avatar'] as String;
  });

  Future<void> updateInterests(List<int> categoryIds) =>
      _guard(() => _dio.put<dynamic>('accounts/me/interests/', data: {'category_ids': categoryIds}));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
