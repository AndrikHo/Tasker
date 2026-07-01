import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Thrown for any non-2xx backend response. [code] mirrors the server's stable
/// error code when present (e.g. AuthError codes), [message] is human-readable.
class ApiException implements Exception {
  ApiException(this.status, this.message, {this.code});

  final int status;
  final String message;
  final String? code;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status${code != null ? ' $code' : ''}): $message';
}

/// Session tokens returned by the auth endpoints.
class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory SessionTokens.fromJson(Map<String, dynamic> j) => SessionTokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        expiresIn: (j['expiresIn'] as num?)?.toInt() ?? 0,
      );
}

/// Low-level REST transport to the Tasker backend.
///
/// Injects the bearer access token, transparently refreshes it via
/// `/auth/refresh` on a 401 and retries the original request once. When the
/// refresh itself fails the session is cleared and [onSessionExpired] fires so
/// the auth layer can drop the user to the sign-in screen.
class ApiClient {
  ApiClient({required this.baseUrl, TokenStore? store, http.Client? httpClient})
      : _store = store ?? TokenStore(),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStore _store;
  final http.Client _http;

  String? _accessToken;
  String? _refreshToken;

  /// Called when the session can no longer be refreshed (forced sign-out).
  void Function()? onSessionExpired;

  String? get accessToken => _accessToken;
  bool get hasSession => _refreshToken != null;

  TokenStore get store => _store;

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Adopt only an access token (used after a refresh that returns a new pair).
  void _setAccess(String token) => _accessToken = token;

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _store.clear();
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool withAuth = true, bool json = true}) {
    return {
      if (json) 'content-type': 'application/json',
      'accept': 'application/json',
      if (withAuth && _accessToken != null)
        'authorization': 'Bearer $_accessToken',
    };
  }

  // --- verbs ---------------------------------------------------------------

  Future<dynamic> getJson(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> postJson(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patchJson(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> deleteJson(String path, {Object? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final res = await _raw(method, path, body: body, auth: auth);

    // Transparently refresh once on an authenticated 401.
    if (res.statusCode == 401 && auth && !isRetry && _refreshToken != null) {
      final refreshed = await _refresh();
      if (refreshed) {
        return _send(method, path, body: body, auth: auth, isRetry: true);
      }
      await clear();
      onSessionExpired?.call();
    }

    return _decode(res);
  }

  Future<http.Response> _raw(
    String method,
    String path, {
    Object? body,
    required bool auth,
  }) {
    final uri = _uri(path);
    final headers = _headers(withAuth: auth, json: body != null);
    final payload = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: payload);
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: payload);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: payload);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  dynamic _decode(http.Response res) {
    final status = res.statusCode;
    final text = res.body;
    dynamic json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } catch (_) {
        json = null;
      }
    }
    if (status >= 200 && status < 300) {
      return json; // may be null for 204
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    throw ApiException(
      status,
      (map['message'] as String?) ?? 'Request failed ($status)',
      code: map['code'] as String?,
    );
  }

  // --- refresh -------------------------------------------------------------

  Future<bool> _refresh() async {
    final token = _refreshToken;
    if (token == null) return false;
    try {
      final res = await _http.post(
        _uri('/auth/refresh'),
        headers: {'content-type': 'application/json', 'accept': 'application/json'},
        body: jsonEncode({'refreshToken': token}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tokens = SessionTokens.fromJson(json);
      _setAccess(tokens.accessToken);
      _refreshToken = tokens.refreshToken;
      await _store.writeRefreshToken(tokens.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Explicit refresh used at startup to re-mint an access token from a stored
  /// refresh token. Returns true when a live session was restored.
  Future<bool> restoreFromRefreshToken(String refreshToken) async {
    _refreshToken = refreshToken;
    final ok = await _refresh();
    if (!ok) {
      _refreshToken = null;
      _accessToken = null;
    }
    return ok;
  }

  void dispose() => _http.close();
}
