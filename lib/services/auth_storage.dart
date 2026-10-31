
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'nexora_access_token';
  static const _refreshKey = 'nexora_refresh_token';
  static const _rememberKey = 'nexora_remember_me';

  static String? _sessionAccessToken;
  static String? _sessionRefreshToken;

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool rememberMe = false,
  }) async {
    _sessionAccessToken = accessToken;
    _sessionRefreshToken = refreshToken;

    if (rememberMe) {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
      await _storage.write(key: _rememberKey, value: 'true');
    } else {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      await _storage.delete(key: _rememberKey);
    }
  }

  static Future<String?> getToken() async {
    if (_sessionAccessToken != null) {
      return _sessionAccessToken;
    }

    if (await _storage.read(key: _rememberKey) != 'true') {
      return null;
    }

    _sessionAccessToken = await _storage.read(key: _accessKey);
    return _sessionAccessToken;
  }

  static Future<String?> getRefreshToken() async {
    if (_sessionRefreshToken != null) {
      return _sessionRefreshToken;
    }

    if (await _storage.read(key: _rememberKey) != 'true') {
      return null;
    }

    _sessionRefreshToken = await _storage.read(key: _refreshKey);
    return _sessionRefreshToken;
  }

  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _sessionAccessToken = accessToken;
    _sessionRefreshToken = refreshToken;

    if (await _storage.read(key: _rememberKey) == 'true') {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  static Future<void> deleteToken() async {
    _sessionAccessToken = null;
    _sessionRefreshToken = null;

    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _rememberKey);
  }
}
