import 'dart:io';

import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'parcel_models.dart';

class ParcelsApi {
  ParcelsApi(this._dio);
  final Dio _dio;

  Future<List<Parcel>> getParcels() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('parcels/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => Parcel.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<Parcel> create({
    required String recipientName,
    required String recipientPhone,
    required String pickupLine1,
    required String pickupCity,
    required String dropoffLine1,
    required String dropoffCity,
    required String packageSize,
    String description = '',
    String? declaredValue,
    File? photo,
  }) => _guard(() async {
    final form = FormData.fromMap({
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'pickup_line1': pickupLine1,
      'pickup_city': pickupCity,
      'dropoff_line1': dropoffLine1,
      'dropoff_city': dropoffCity,
      'package_size': packageSize,
      'description': description,
      'declared_value': ?declaredValue,
    });
    if (photo != null) {
      form.files.add(MapEntry('photo', await MultipartFile.fromFile(photo.path)));
    }
    final response = await _dio.post<Map<String, dynamic>>('parcels/', data: form);
    return Parcel.fromJson(response.data!);
  });

  Future<void> cancel(int id) => _guard(() => _dio.post<dynamic>('parcels/$id/cancel/'));

  /// The explicit "start matching" step — `POST /parcels/` only creates the
  /// parcel, this is what actually triggers dispatch. No response body.
  Future<void> findRider(int parcelId) => _guard(() => _dio.post<dynamic>('parcels/$parcelId/find-rider/'));

  /// Customer-facing — rates the rider once a parcel's been delivered.
  /// Lives here rather than a separate `trips` feature module since it's
  /// the only customer-facing trip endpoint and this is where it's used.
  Future<void> rateRider(int tripId, {required int stars, String comment = ''}) => _guard(
    () => _dio.post<dynamic>('trips/$tripId/rate-rider/', data: {'stars': stars, 'comment': comment}),
  );

  Future<ParcelTracking?> getTracking(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('parcels/$id/tracking/');
      final data = response.data;
      return data == null ? null : ParcelTracking.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
