import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

/// Thrown when an auth action is attempted before Supabase is configured.
class AuthNotConfigured implements Exception {
  const AuthNotConfigured();
  @override
  String toString() =>
      'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.';
}

/// Wraps Supabase auth so the rest of the app never touches the SDK directly.
///
/// Every method is a safe no-op / clear error when the backend is not yet
/// configured, so the app keeps running on local demo data until credentials
/// land.
class AuthService {
  const AuthService();

  bool get isConfigured => SupabaseConfig.isConfigured;

  GoTrueClient get _auth => SupabaseConfig.client.auth;

  /// The currently signed-in user, or null.
  User? get currentUser => isConfigured ? _auth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  /// Emits on every sign-in / sign-out / token refresh. Emits nothing extra
  /// when unconfigured (callers treat the initial state as signed-out).
  Stream<AuthState> authStateChanges() {
    if (!isConfigured) return const Stream<AuthState>.empty();
    return _auth.onAuthStateChange;
  }

  /// Sends a magic-link / OTP email. The user finishes sign-in by following
  /// the link (web/deeplink) which restores the session automatically.
  Future<void> signInWithEmail(String email, {String? emailRedirectTo}) async {
    if (!isConfigured) throw const AuthNotConfigured();
    await _auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: emailRedirectTo,
    );
  }

  /// Starts the Google OAuth flow.
  Future<void> signInWithGoogle({String? redirectTo}) async {
    if (!isConfigured) throw const AuthNotConfigured();
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  /// Starts the Apple OAuth flow (used once iOS goes to the App Store).
  Future<void> signInWithApple({String? redirectTo}) async {
    if (!isConfigured) throw const AuthNotConfigured();
    await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: redirectTo,
    );
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _auth.signOut();
  }
}
