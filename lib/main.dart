import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The backend session is restored lazily by BackendAuthService (via its
  // provider); no blocking init is needed here. Local demo mode runs when no
  // API_BASE_URL is configured.

  // Load persisted settings (theme, locale).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TaskerApp(),
    ),
  );
}
