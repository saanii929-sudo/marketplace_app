import 'dart:io';

import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'seller_application.dart';

class SellersApi {
  SellersApi(this._dio);
  final Dio _dio;

  /// Submits a seller application. [idDocument] is required by the given
  /// endpoint; [businessCertificate] is optional (no asterisk in the spec).
  Future<void> apply({
    required String businessName,
    required int categoryId,
    required String phone,
    required File idDocument,
    File? businessCertificate,
  }) => _guard(() async {
    final form = FormData.fromMap({
      'business_name': businessName,
      'category_id': categoryId,
      'phone': phone,
      'id_document': await MultipartFile.fromFile(idDocument.path),
      if (businessCertificate != null)
        'business_certificate': await MultipartFile.fromFile(businessCertificate.path),
    });
    await _dio.post<dynamic>('sellers/apply/', data: form);
  });

  /// Returns `null` if the caller hasn't applied yet (a 404 from this
  /// endpoint), rather than surfacing that as an error.
  Future<SellerApplicationStatus?> getStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('sellers/apply/status/');
      return SellerApplicationStatus.fromJson(response.data!);
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
