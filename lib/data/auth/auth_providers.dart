import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'auth_service.dart';

/// Single shared auth service.
final authServiceProvider = Provider<AuthService>((ref) => const AuthService());

/// True when a real backend is wired up. The UI uses this to decide whether to
/// offer sign-in / cloud sync or stay in local demo mode.
final backendConfiguredProvider =
    Provider<bool>((ref) => SupabaseConfig.isConfigured);

/// Live auth state stream. Seeds with the current session so listeners get an
/// immediate value instead of waiting for the first change event.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final auth = ref.watch(authServiceProvider);
  if (!auth.isConfigured) return Stream<AuthState?>.value(null);
  return auth.authStateChanges();
});

/// The current signed-in user (null when signed out or unconfigured).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // re-evaluate on every auth change
  return ref.watch(authServiceProvider).currentUser;
});

/// Convenience flag for "is someone signed in".
final isSignedInProvider =
    Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
