import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access/refresh token pair returned by `/auth/login/`
/// across app restarts.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();
  static const _accessKey = 'sporttech_access_token';
  static const _refreshKey = 'sporttech_refresh_token';

  String? _cachedAccess;
  String? _cachedRefresh;

  Future<String?> readAccess() async => _cachedAccess ??= await _storage.read(key: _accessKey);
  Future<String?> readRefresh() async => _cachedRefresh ??= await _storage.read(key: _refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> updateAccess(String access) async {
    _cachedAccess = access;
    await _storage.write(key: _accessKey, value: access);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
