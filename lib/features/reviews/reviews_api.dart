import 'package:dio/dio.dart';

import '../../network/api_exception.dart';

/// Only `create()` is wired up — the given API has no "list my reviews"
/// endpoint, so once a review is submitted there's no reliable way to look
/// its id back up later to edit or delete it (the create response itself
/// doesn't echo one either). Editing/deleting stays unimplemented until
/// such a lookup exists.
class ReviewsApi {
  ReviewsApi(this._dio);
  final Dio _dio;

  /// Enforces verified purchase against a delivered [orderItemId] — see
  /// the products-reviews endpoint's own description.
  Future<void> create({required int orderItemId, required int rating, required String comment}) => _guard(
    () => _dio.post<dynamic>(
      'reviews/',
      data: {'order_item_id': orderItemId, 'rating': rating, 'comment': comment},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
