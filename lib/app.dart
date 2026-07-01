import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ambient_background.dart';
import 'data/profile/profile_sync.dart';
import 'features/buddies/buddy_overlay.dart';
import 'l10n/app_localizations.dart';

class TaskerApp extends ConsumerWidget {
  const TaskerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the backend profile in sync with the local profile for the lifetime
    // of the app (no-op in local demo mode).
    ref.watch(profileSyncProvider);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final style = ref.watch(styleProvider);

    return MaterialApp.router(
      title: 'Tasker',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.build(style, Brightness.light),
      darkTheme: AppTheme.build(style, Brightness.dark),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Paint the ambient glow behind every route. Uses the resolved
        // brightness so it matches light/dark automatically.
        return AmbientBackground(
          style: style,
          brightness: Theme.of(context).brightness,
          child: BuddyOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
