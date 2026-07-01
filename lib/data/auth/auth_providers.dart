import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/realtime_client.dart';
import 'auth_models.dart';
import 'backend_auth_service.dart';

/// Single shared HTTP transport to the backend. Holds the in-memory access
/// token and drives token refresh for the whole app.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: ApiConfig.baseUrl);
  ref.onDispose(client.dispose);
  return client;
});

/// Realtime signalling client, shared by the repository's watch streams.
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final rt = RealtimeClient(ref.watch(apiClientProvider));
  ref.onDispose(rt.dispose);
  return rt;
});

/// Single shared auth service.
final authServiceProvider = Provider<BackendAuthService>((ref) {
  final service = BackendAuthService(ref.watch(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// True when a real backend is wired up (API_BASE_URL provided). The UI uses
/// this to decide whether to offer sign-in / cloud sync or stay in local demo
/// mode.
final backendConfiguredProvider = Provider<bool>((ref) => ApiConfig.isConfigured);

/// Live auth state stream. Stays in the loading state until the startup restore
/// resolves, then emits the current session (or null) and every change.
final authStateProvider = StreamProvider<AuthSession?>((ref) {
  final auth = ref.watch(authServiceProvider);
  if (!auth.isConfigured) return Stream<AuthSession?>.value(null);
  return auth.authStateChanges();
});

/// The current signed-in user (null when signed out or unconfigured).
final currentUserProvider = Provider<AuthUser?>((ref) {
  ref.watch(authStateProvider); // re-evaluate on every auth change
  return ref.watch(authServiceProvider).currentUser;
});

/// Convenience flag for "is someone signed in".
final isSignedInProvider =
    Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
