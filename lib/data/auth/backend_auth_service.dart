import 'dart:async';

import '../api/api_client.dart';
import '../api/api_config.dart';
import 'auth_models.dart';

/// Authentication against the self-hosted backend.
///
/// Owns the session lifecycle: sign-up / sign-in mint tokens (held by
/// [ApiClient]), a startup restore re-mints an access token from the persisted
/// refresh token, and [authStateChanges] broadcasts every transition so the
/// router and repository react. The rest of the app never touches HTTP.
class BackendAuthService {
  BackendAuthService(this._api) {
    _api.onSessionExpired = () => _emit(null);
    if (ApiConfig.isConfigured) {
      _restore();
    } else {
      _restored = true;
    }
  }

  final ApiClient _api;

  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _current;
  bool _restored = false;
  String? _refreshToken;

  bool get isConfigured => ApiConfig.isConfigured;

  AuthUser? get currentUser => _current?.user;

  bool get isSignedIn => _current != null;

  /// Emits the current session (or null) once resolved, then every change.
  /// Stays silent until the startup restore finishes so the router can show a
  /// splash instead of flashing the sign-in screen.
  Stream<AuthSession?> authStateChanges() async* {
    if (_restored) yield _current;
    yield* _controller.stream;
  }

  // --- password ------------------------------------------------------------

  Future<void> signUpWithPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    final name = displayName?.trim();
    final json = await _api.postJson('/auth/signup', auth: false, body: {
      'email': email.trim(),
      'password': password,
      if (name != null && name.isNotEmpty) 'displayName': name,
    });
    _applySession(json as Map<String, dynamic>);
  }

  Future<void> signInWithPassword(String email, String password) async {
    final json = await _api.postJson('/auth/login', auth: false, body: {
      'email': email.trim(),
      'password': password,
    });
    _applySession(json as Map<String, dynamic>);
  }

  // --- passwordless --------------------------------------------------------

  /// Requests a magic sign-in link by email. The user completes sign-in by
  /// following the link (web/deeplink).
  Future<void> requestMagicLink(String email) async {
    await _api.postJson('/auth/magic-link', auth: false, body: {'email': email.trim()});
  }

  /// Requests a one-time code by email.
  Future<void> requestOtp(String email) async {
    await _api.postJson('/auth/otp/request', auth: false, body: {'email': email.trim()});
  }

  /// Completes sign-in with an emailed one-time code.
  Future<void> verifyOtp(String email, String code) async {
    final json = await _api.postJson('/auth/otp/verify', auth: false, body: {
      'email': email.trim(),
      'code': code.trim(),
    });
    _applySession(json as Map<String, dynamic>);
  }

  // --- lifecycle -----------------------------------------------------------

  Future<void> signOut() async {
    final token = _refreshToken;
    if (token != null) {
      try {
        await _api.postJson('/auth/logout', auth: false, body: {'refreshToken': token});
      } catch (_) {
        // Non-fatal: local teardown proceeds regardless.
      }
    }
    _refreshToken = null;
    await _api.clear();
    _emit(null);
  }

  Future<void> _restore() async {
    try {
      final stored = await _api.store.readRefreshToken();
      if (stored == null) {
        _emit(null);
        return;
      }
      final ok = await _api.restoreFromRefreshToken(stored);
      if (!ok) {
        await _api.store.clear();
        _emit(null);
        return;
      }
      _refreshToken = stored;
      final userJson = await _api.store.readUser();
      var user = userJson != null ? AuthUser.fromJson(userJson) : null;
      // Refresh the user snapshot from the server when possible.
      try {
        final me = await _api.getJson('/auth/me');
        if (me is Map<String, dynamic>) user = AuthUser.fromJson(me);
      } catch (_) {
        // Keep the cached snapshot on a transient failure.
      }
      if (user == null) {
        _emit(null);
      } else {
        await _api.store.writeUser(user.toJson());
        _emit(AuthSession(user));
      }
    } catch (_) {
      _emit(null);
    }
  }

  Future<void> _applySession(Map<String, dynamic> json) async {
    final tokens = SessionTokens.fromJson(json);
    _api.setTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    _refreshToken = tokens.refreshToken;
    await _api.store.writeRefreshToken(tokens.refreshToken);
    final user = AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    await _api.store.writeUser(user.toJson());
    _emit(AuthSession(user));
  }

  void _emit(AuthSession? session) {
    _restored = true;
    _current = session;
    if (!_controller.isClosed) _controller.add(session);
  }

  Future<void> dispose() => _controller.close();
}
