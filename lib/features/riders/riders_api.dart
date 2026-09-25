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

  /// Returns `null` if there's nothing on file yet (a 404), rather than
  /// surfacing that as an error — mirrors `SellersApi.getStatus()`.
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

  // --- Rider-ops endpoints (Phase 7: real backend replacing the earlier
  // local simulation). None of these shapes have been empirically verified
  // against a live server yet — they follow the spec exactly as handed to
  // the backend dev, and every model field is parsed defensively so a
  // mismatch degrades gracefully rather than crashing.

  Future<void> setOnline(bool isOnline) =>
      _guard(() => _dio.patch<dynamic>('riders/status/', data: {'is_online': isOnline}));

  Future<RiderDelivery> acceptRequest(int requestId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('riders/delivery-requests/$requestId/accept/');
    return RiderDelivery.fromJson(response.data!);
  });

  Future<void> declineRequest(int requestId) =>
      _guard(() => _dio.post<dynamic>('riders/delivery-requests/$requestId/decline/'));

  // The user confirmed `POST trips/{id}/confirm-pickup/`, `.../complete/`,
  // `.../proof-of-delivery/` and `.../rate-rider/` as real — the resource
  // is called a "trip," not a "rider delivery" as originally guessed.
  // `getActiveDelivery()`/`getDeliveries()` below are repointed to
  // `trips/active/`/`trips/` to match — that specific pairing wasn't
  // directly confirmed, only inferred from the trip-action endpoints'
  // naming, so it's the one part of this block still worth double-checking
  // against the live server.

  /// `null` if there's no delivery currently in progress.
  Future<RiderDelivery?> getActiveDelivery() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('trips/active/');
      final data = response.data;
      return data == null ? null : RiderDelivery.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<RiderDelivery> confirmPickup(int tripId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('trips/$tripId/confirm-pickup/');
    return RiderDelivery.fromJson(response.data!);
  });

  /// Step 2 of completion: the rider submits the customer's OTP code plus a
  /// proof-of-delivery photo. The server almost certainly validates the
  /// code here (a wrong one should come back as a normal validation error
  /// via [ApiException]) — [completeTrip] below is the separate finalize
  /// call made once this succeeds.
  Future<void> submitProofOfDelivery(int tripId, {required String otpCode, required File photo}) => _guard(() async {
    final form = FormData.fromMap({'otp_code': otpCode, 'photo': await MultipartFile.fromFile(photo.path)});
    await _dio.post<dynamic>('trips/$tripId/proof-of-delivery/', data: form);
  });

  Future<void> completeTrip(int tripId) => _guard(() => _dio.post<dynamic>('trips/$tripId/complete/'));

  Future<List<RiderDelivery>> getDeliveries() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('trips/');
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
      'document_type': documentType,
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
