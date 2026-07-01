import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'backend_tasker_repository.dart';
import 'tasker_repository.dart';

/// The active repository, or null when the app is running in local demo mode
/// (backend not configured, or no user signed in yet).
///
/// Rebuilds on every auth change so it flips on at sign-in and off at sign-out.
/// Screens that have been migrated to the backend watch this; while it is null
/// they keep using the local in-memory providers.
final taskerRepositoryProvider = Provider<TaskerRepository?>((ref) {
  ref.watch(authStateProvider);
  if (!ref.watch(backendConfiguredProvider)) return null;
  if (!ref.watch(isSignedInProvider)) return null;
  return BackendTaskerRepository(
    ref.watch(apiClientProvider),
    ref.watch(realtimeClientProvider),
  );
});
