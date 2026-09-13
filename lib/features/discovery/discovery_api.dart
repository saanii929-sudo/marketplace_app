import 'package:dio/dio.dart';

import '../../network/api_exception.dart';
import 'discovery.dart';

class DiscoveryApi {
  DiscoveryApi(this._dio);
  final Dio _dio;

  Future<DiscoveryHome> getHome() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('discovery/home/');
    return DiscoveryHome.fromJson(response.data!);
  });

  Future<List<RecentlyViewedEntry>> getRecentlyViewed() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>('discovery/recently-viewed/');
    final results = response.data?['results'] as List<dynamic>? ?? [];
    return results.map((e) => RecentlyViewedEntry.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<List<RecentSearch>> getRecentSearches() => _guard(() async {
    final response = await _dio.get<List<dynamic>>('discovery/search/recent/');
    return (response.data ?? []).map((e) => RecentSearch.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Fire-and-forget — failures are ignored, this is purely analytics.
  Future<void> logSearch(String queryText) async {
    try {
      await _dio.post<dynamic>('discovery/search/log/', data: {'query_text': queryText});
    } on DioException {
      // Ignored — see doc comment above.
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
