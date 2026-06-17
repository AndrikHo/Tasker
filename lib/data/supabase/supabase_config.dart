import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase initialization.
///
/// Fill SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Until real values are provided this is a safe no-op so the skeleton runs
/// without a backend.
class SupabaseConfig {
  static const String _url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
