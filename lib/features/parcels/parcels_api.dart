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
    String paymentMethod = 'online',
    double? pickupLat,
    double? pickupLng,
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
      'payment_method': paymentMethod,
      // Without these, `find_nearest_eligible_rider()` silently bails out
      // (confirmed by the backend dev) — no error, just behaves exactly
      // like "no riders available."
      'pickup_lat': ?pickupLat,
      'pickup_lng': ?pickupLng,
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

  /// Starts a Hubtel checkout for the parcel's price. Documented as "No
  /// response body," but the endpoint's own description says the client
  /// should open the returned `checkout_url` — parsed defensively same as
  /// every other "no response body" endpoint that's turned out to lie.
  Future<ParcelCheckoutStatus> startCheckout(int parcelId) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>('parcels/$parcelId/checkout/');
    return ParcelCheckoutStatus.fromJson(response.data ?? const {});
  });

  /// Polled after opening `checkout_url` — re-confirms against Hubtel
  /// directly rather than waiting on the payment webhook.
  Future<ParcelCheckoutStatus> getCheckoutStatus(int parcelId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('parcels/$parcelId/checkout/status/');
    return ParcelCheckoutStatus.fromJson(response.data ?? const {});
  });

  /// Customer-facing — rates the rider once a parcel's been delivered.
  /// Lives here rather than a separate `trips` feature module since it's
  /// the only customer-facing trip endpoint and this is where it's used.
  /// Path corrected to `riders/deliveries/` — backend dev confirmed there's
  /// no `trips/` prefix anywhere in this API (same fix as the rider-side
  /// pickup/proof-of-delivery/complete calls in `RidersApi`).
  Future<void> rateRider(int tripId, {required int stars, String comment = ''}) => _guard(
    () => _dio.post<dynamic>('riders/deliveries/$tripId/rate-rider/', data: {'stars': stars, 'comment': comment}),
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
