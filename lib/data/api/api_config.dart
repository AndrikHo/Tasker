/// Backend endpoint configuration.
///
/// The API base URL is injected at build time via `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=https://api.tasker.app
///
/// When no URL is provided the app stays in local demo mode (no sign-in, purely
/// in-memory data), exactly like the old Supabase-less skeleton. This keeps all
/// three targets runnable before the backend is deployed.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// True once a real backend URL is wired up.
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// WebSocket origin derived from [baseUrl] (http -> ws, https -> wss).
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring('https://'.length)}';
    }
    if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring('http://'.length)}';
    }
    return baseUrl;
  }
}
