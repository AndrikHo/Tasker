/// The signed-in account as the app cares about it. Deliberately small: the
/// UI reads `id` for the "me" member and `displayName`/`handle` for profile
/// bootstrapping.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    this.handle,
    this.displayName,
  });

  final String id;
  final String email;
  final bool emailVerified;
  final String? handle;
  final String? displayName;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        email: (j['email'] as String?) ?? '',
        emailVerified: (j['emailVerified'] as bool?) ?? false,
        handle: j['handle'] as String?,
        displayName: j['displayName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'emailVerified': emailVerified,
        'handle': handle,
        'displayName': displayName,
      };
}

/// A live session: the authenticated user plus the fact that tokens are held by
/// the [ApiClient]. Emitted by the auth state stream; `null` means signed out.
class AuthSession {
  const AuthSession(this.user);

  final AuthUser user;
}

/// Auth-specific failure carrying a user-facing message and the server's stable
/// code when available (e.g. `invalid_credentials`).
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

/// Social identity providers offered on the sign-in screen. Only [google] and
/// [apple] are backed by the server today; [kakao] and [facebook] are shown for
/// layout continuity and wired later.
enum SocialProvider { google, apple, kakao, facebook }
