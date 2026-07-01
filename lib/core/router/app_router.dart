import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/auth_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/lists/lists_screen.dart';
import '../../features/friends/friends_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/account_screen.dart';
import 'auth_splash.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Auth-gate state the router redirect reads. `null` while the auth stream is
/// still resolving (show splash), then a resolved signed-in / signed-out flag.
enum _Gate { resolving, signedOut, ready }

final _gateProvider = Provider<_Gate>((ref) {
  // Local demo mode: no backend, never gate.
  if (!ref.watch(backendConfiguredProvider)) return _Gate.ready;

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (_) =>
        ref.watch(isSignedInProvider) ? _Gate.ready : _Gate.signedOut,
    loading: () => _Gate.resolving,
    error: (_, _) => _Gate.signedOut,
  );
});

final routerProvider = Provider<GoRouter>((ref) {
  // Repaint the router whenever the gate changes so redirect re-runs.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<_Gate>(_gateProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/lists',
    refreshListenable: refresh,
    redirect: (context, state) {
      final gate = ref.read(_gateProvider);
      final loc = state.matchedLocation;
      switch (gate) {
        case _Gate.resolving:
          return loc == '/splash' ? null : '/splash';
        case _Gate.signedOut:
          return loc == '/auth' ? null : '/auth';
        case _Gate.ready:
          // Bounce away from the gate routes once the user is in.
          if (loc == '/auth' || loc == '/splash') return '/lists';
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AuthSplash(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AuthScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/lists',
                builder: (context, state) => const ListsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                builder: (context, state) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'account',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const AccountScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
