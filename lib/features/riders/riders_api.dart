import 'dart:io';

import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'rider_models.dart';

class RidersApi {
  RidersApi(this._dio);
  final Dio _dio;

  Future<void> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
    required String vehicleType,
    String vehicleMake = '',
    String vehicleModel = '',
    String plateNumber = '',
    String color = '',
  }) => _guard(
    () => _dio.post<dynamic>(
      'riders/register/',
      data: {
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'password': password,
        'vehicle_type': vehicleType,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'plate_number': plateNumber,
        'color': color,
      },
    ),
  );

  Future<RiderVehicle?> getVehicle() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('riders/vehicle/');
      final data = response.data;
      return data == null ? null : RiderVehicle.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<RiderVehicle> updateVehicle(RiderVehicle vehicle) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>('riders/vehicle/', data: vehicle.toJson());
    final data = response.data;
    return data == null ? vehicle : RiderVehicle.fromJson(data);
  });

  Future<RiderVerificationStatus?> getVerificationStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('riders/verification-status/');
      final data = response.data;
      return data == null ? null : RiderVerificationStatus.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  /// Confirmed real (backend dev verified via a live GET/PATCH/GET
  /// round-trip) — the source of truth for `acceptance_rate`,
  /// `rating_avg`, and the two preference toggles.
  Future<RiderSettings> getSettings() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/me/settings/');
    return RiderSettings.fromJson(response.data!);
  });

  /// Either field is optional and independent — only send what changed.
  Future<RiderSettings> updateSettings({double? minTripValue, bool? pushNotificationsEnabled}) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'riders/me/settings/',
      data: {
        'min_trip_value': ?minTripValue?.toStringAsFixed(2),
        'push_notifications_enabled': ?pushNotificationsEnabled,
      },
    );
    return RiderSettings.fromJson(response.data!);
  });

  Future<void> setOnline(bool isOnline) =>
      _guard(() => _dio.patch<dynamic>('riders/status/', data: {'is_online': isOnline}));

  /// Confirmed real (backend dev, `RiderLocationPingView`) — a separate
  /// endpoint from `riders/status/`, which has no lat/lng fields at all.
  /// No backend-enforced interval; pinged on a client-side timer while online.
  /// `LocationPingSerializer` caps lat/lng at 6 decimal places
  /// (`max_digits=9, decimal_places=6`) — raw GPS doubles from `geolocator`
  /// have far more precision than that, so every ping 400s without rounding.
  Future<void> sendLocationPing({required double lat, required double lng}) => _guard(
    () => _dio.post<dynamic>(
      'riders/location/',
      data: {'lat': _roundTo6dp(lat), 'lng': _roundTo6dp(lng)},
    ),
  );

  Future<RiderDelivery> acceptRequest(int requestId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('riders/delivery-requests/$requestId/accept/');
    return RiderDelivery.fromJson(response.data!);
  });

  Future<void> declineRequest(int requestId) =>
      _guard(() => _dio.post<dynamic>('riders/delivery-requests/$requestId/decline/'));

  /// Confirmed real (backend dev verified via source: `riders/urls.py:25` →
  /// `RiderActiveDeliveryView`) — 204 with no body if there's nothing
  /// in-progress, 200 with the active trip otherwise.
  Future<RiderDelivery?> getActiveDelivery() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('riders/deliveries/active/');
      final data = response.data;
      return data == null ? null : RiderDelivery.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) return null;
      throw ApiException.fromDioException(e);
    }
  }

  /// Backend dev has confirmed twice now (source review, then a live 404 on
  /// `GET trips/`) that there's no `trips/` prefix anywhere in this API —
  /// it's namespaced under `riders/deliveries/`, matching the confirmed
  /// `riders/deliveries/active/`. Switched these four from the original
  /// `trips/{id}/...` Swagger paste, which apparently didn't match reality.
  Future<RiderDelivery> confirmPickup(int tripId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('riders/deliveries/$tripId/confirm-pickup/');
    return RiderDelivery.fromJson(response.data!);
  });

  Future<void> submitProofOfDelivery(int tripId, {required String otpCode, required File photo}) => _guard(() async {
    final form = FormData.fromMap({'otp_code': otpCode, 'photo': await MultipartFile.fromFile(photo.path)});
    await _dio.post<dynamic>('riders/deliveries/$tripId/proof-of-delivery/', data: form);
  });

  Future<void> completeTrip(int tripId) =>
      _guard(() => _dio.post<dynamic>('riders/deliveries/$tripId/complete/'));

  Future<List<RiderDelivery>> getDeliveries() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/deliveries/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => RiderDelivery.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<RiderEarningsSummary> getEarningsSummary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/earnings/summary/');
    return RiderEarningsSummary.fromJson(response.data!);
  });

  Future<List<RiderActivityEntry>> getEarningsActivity() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/earnings/activity/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => RiderActivityEntry.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<List<RiderPayoutMethod>> getPayoutMethods() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('riders/payout-methods/');
    return (response.data ?? []).map((e) => RiderPayoutMethod.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<RiderPayoutMethod> addPayoutMethod({required String provider, required String accountNumber}) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          'riders/payout-methods/',
          data: {'provider': provider, 'account_number': accountNumber},
        );
        return RiderPayoutMethod.fromJson(response.data!);
      });

  Future<void> setDefaultPayoutMethod(int id) =>
      _guard(() => _dio.post<dynamic>('riders/payout-methods/$id/set-default/'));

  Future<double> cashOut({required double amount, required int payoutMethodId}) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      'riders/cash-out/',
      data: {'amount': amount, 'payout_method_id': payoutMethodId},
    );
    final balance = response.data?['balance'];
    return balance == null ? 0 : double.tryParse(balance.toString()) ?? 0;
  });

  Future<List<RiderReview>> getReviews() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/reviews/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => RiderReview.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<RiderReviewSummary> getReviewSummary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('riders/reviews/summary/');
    return RiderReviewSummary.fromJson(response.data!);
  });

  Future<RiderDocument> uploadDocument({required String documentType, required File file}) => _guard(() async {
    final form = FormData.fromMap({
      'doc_type': documentType,
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post<Map<String, dynamic>>('riders/documents/', data: form);
    return RiderDocument.fromJson(response.data!);
  });

  Future<List<RiderDocument>> getDocuments() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('riders/documents/');
    return (response.data ?? []).map((e) => RiderDocument.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

double _roundTo6dp(double value) => (value * 1000000).round() / 1000000;
