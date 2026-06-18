import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/characters/character.dart';
import '../theme/app_style.dart';

/// Provides the SharedPreferences instance. Overridden in main().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

const _kThemeModeKey = 'theme_mode';
const _kLocaleKey = 'locale';
const _kCharacterKey = 'character_id';
const _kBuddiesKey = 'buddies_enabled';
const _kProfileNameKey = 'profile_name';
const _kProfileEmojiKey = 'profile_emoji';
const _kProfileColorKey = 'profile_color';

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

/// The chosen character, persisted. Picking a character is the single control
/// that drives both the profile avatar and the app theme: see [styleProvider],
/// which derives the visual style from the selected character's look.
/// Changeable at any time.
class CharacterNotifier extends StateNotifier<Character> {
  CharacterNotifier(this._prefs)
      : super(characterById(_prefs.getString(_kCharacterKey)));

  final SharedPreferences _prefs;

  Future<void> set(Character character) async {
    state = character;
    await _prefs.setString(_kCharacterKey, character.id);
  }
}

final characterProvider =
    StateNotifierProvider<CharacterNotifier, Character>((ref) {
  return CharacterNotifier(ref.watch(sharedPreferencesProvider));
});

/// Active visual style, derived from the selected character's [Character.look].
/// Kept as an [AppStyle] provider so the whole theme engine and every existing
/// `ref.watch(styleProvider)` call site keep working unchanged.
final styleProvider = Provider<AppStyle>((ref) {
  return ref.watch(characterProvider).look;
});

/// Whether the "LIFE FRIENDS" buddies peek in over the app, persisted.
/// Defaults to on so the feature is discoverable.
class BuddiesNotifier extends StateNotifier<bool> {
  BuddiesNotifier(this._prefs) : super(_prefs.getBool(_kBuddiesKey) ?? true);

  final SharedPreferences _prefs;

  Future<void> set(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_kBuddiesKey, enabled);
  }

  Future<void> toggle() => set(!state);
}

final buddyEnabledProvider =
    StateNotifierProvider<BuddiesNotifier, bool>((ref) {
  return BuddiesNotifier(ref.watch(sharedPreferencesProvider));
});

/// The local user profile (display name + emoji/color avatar), persisted.
/// A stand-in until Supabase auth provides the real account.
@immutable
class Profile {
  const Profile({this.name, required this.emoji, required this.colorValue});

  final String? name;
  final String emoji;
  final int colorValue;

  Color get color => Color(colorValue);

  Profile copyWith({String? name, String? emoji, int? colorValue}) => Profile(
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
      );
}

class ProfileNotifier extends StateNotifier<Profile> {
  ProfileNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _defaultColor = 0xFF22D3EE;

  static Profile _load(SharedPreferences prefs) {
    final name = prefs.getString(_kProfileNameKey);
    return Profile(
      name: (name == null || name.isEmpty) ? null : name,
      emoji: prefs.getString(_kProfileEmojiKey) ?? '🙂',
      colorValue: prefs.getInt(_kProfileColorKey) ?? _defaultColor,
    );
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    state = state.copyWith(name: trimmed.isEmpty ? null : trimmed);
    if (trimmed.isEmpty) {
      await _prefs.remove(_kProfileNameKey);
    } else {
      await _prefs.setString(_kProfileNameKey, trimmed);
    }
  }

  Future<void> setAvatar({required String emoji, required int colorValue}) async {
    state = state.copyWith(emoji: emoji, colorValue: colorValue);
    await _prefs.setString(_kProfileEmojiKey, emoji);
    await _prefs.setInt(_kProfileColorKey, colorValue);
  }

  Future<void> clear() async {
    await _prefs.remove(_kProfileNameKey);
    await _prefs.remove(_kProfileEmojiKey);
    await _prefs.remove(_kProfileColorKey);
    state = const Profile(emoji: '🙂', colorValue: _defaultColor);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, Profile>((ref) {
  return ProfileNotifier(ref.watch(sharedPreferencesProvider));
});
