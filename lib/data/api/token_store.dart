import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the session across app restarts in the platform secure store
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android,
/// WebCrypto-wrapped localStorage on web).
///
/// Only the refresh token and a small snapshot of the user are persisted; the
/// short-lived access token stays in memory and is re-minted via /auth/refresh
/// on startup.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kRefresh = 'tasker.refresh_token';
  static const _kUser = 'tasker.user';

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _kRefresh, value: token);

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeUser(Map<String, dynamic> user) =>
      _storage.write(key: _kUser, value: jsonEncode(user));

  Future<void> clear() async {
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
