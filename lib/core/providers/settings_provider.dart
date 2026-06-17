import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_style.dart';

/// Provides the SharedPreferences instance. Overridden in main().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

const _kThemeModeKey = 'theme_mode';
const _kLocaleKey = 'locale';
const _kStyleKey = 'app_style';

/// Theme mode (light / dark / system), persisted.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    switch (prefs.getString(_kThemeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark; // dark by default
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

/// App locale. null = follow system language.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale? _load(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(_kLocaleKey);
    } else {
      await _prefs.setString(_kLocaleKey, locale.languageCode);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});

/// Active visual style (playful / neutral / glass), persisted.
class StyleNotifier extends StateNotifier<AppStyle> {
  StyleNotifier(this._prefs)
      : super(AppStyleX.fromId(_prefs.getString(_kStyleKey)));

  final SharedPreferences _prefs;

  Future<void> set(AppStyle style) async {
    state = style;
    await _prefs.setString(_kStyleKey, style.id);
  }
}

final styleProvider =
    StateNotifierProvider<StyleNotifier, AppStyle>((ref) {
  return StyleNotifier(ref.watch(sharedPreferencesProvider));
});
