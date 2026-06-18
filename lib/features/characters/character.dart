import 'package:flutter/material.dart';

import '../../core/theme/app_style.dart';

/// When real character art lands in `assets/characters/`, flip this to `true`
/// and the avatar/gallery render the generated PNG instead of the placeholder
/// blob. Until then every character shows a colored placeholder.
const bool kCharacterArtReady = false;

/// The character a user picks in Settings. Picking one does two things at once:
/// it becomes the profile avatar, and its [look] drives the whole app theme
/// (colors, typography, shapes, motion) through the existing [AppStyle] engine.
/// Changeable at any time.
///
/// Art is generated separately and dropped into
/// `assets/characters/<id>.png` (transparent, @3x). Mood variants live at
/// `assets/characters/<id>_<mood>.png` and are wired in later — the roster
/// already declares which moods each character ships with.
@immutable
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.look,
    required this.color,
    required this.face,
    this.moods = const <CharacterMood>{},
  });

  /// Stable id, also the asset file stem: `assets/characters/<id>.png`.
  final String id;

  /// Display name (proper noun, not localized).
  final String name;

  /// The structural theme this character applies to the whole app.
  final AppStyle look;

  /// Signature color, drives the placeholder + avatar ring tie-ins.
  final Color color;

  /// Placeholder face emoji, used until real art lands.
  final String face;

  /// Mood variants this character ships art for (wired in a later pass).
  final Set<CharacterMood> moods;

  /// Base, neutral art.
  String get asset => 'assets/characters/$id.png';

  /// Art for a specific [mood]. Falls back to [asset] when not shipped.
  String assetForMood(CharacterMood mood) =>
      moods.contains(mood) ? 'assets/characters/${id}_${mood.name}.png' : asset;
}

/// The mood a character can be shown in. Reserved for a later pass that ties
/// the on-screen character to app state (streaks, due tasks, time of day...).
enum CharacterMood {
  happy,
  sleepy,
  tired,
  calm,
  focused,
  sad,
  motivated,
  relaxed,
}

/// Default selection on a fresh install.
const String kDefaultCharacterId = 'dino';

/// The canonical cast. Order is stable; [kDefaultCharacterId] leads. Each
/// character maps to one of the four [AppStyle] looks so every theme stays
/// reachable purely by picking a character.
const kCharacters = <Character>[
  Character(
    id: 'dino',
    name: 'DINO',
    look: AppStyle.playful,
    color: Color(0xFF34D399),
    face: '\u{1F995}',
    moods: {
      CharacterMood.happy,
      CharacterMood.sleepy,
      CharacterMood.tired,
      CharacterMood.calm,
      CharacterMood.focused,
      CharacterMood.sad,
      CharacterMood.motivated,
      CharacterMood.relaxed,
    },
  ),
  Character(
    id: 'luna',
    name: 'LUNA',
    look: AppStyle.glass,
    color: Color(0xFF60A5FA),
    face: '\u{1F319}',
  ),
  Character(
    id: 'bear',
    name: 'BEAR',
    look: AppStyle.neutral,
    color: Color(0xFFD2A679),
    face: '\u{1F43B}',
  ),
  Character(
    id: 'pixel',
    name: 'PIXEL',
    look: AppStyle.cartoon,
    color: Color(0xFF8B5CF6),
    face: '\u{1F47E}',
  ),
  Character(
    id: 'bunni',
    name: 'BUNNI',
    look: AppStyle.playful,
    color: Color(0xFFFF7AC6),
    face: '\u{1F430}',
  ),
  Character(
    id: 'meow',
    name: 'MEOW',
    look: AppStyle.glass,
    color: Color(0xFF94A3B8),
    face: '\u{1F431}',
  ),
  Character(
    id: 'ducky',
    name: 'DUCKY',
    look: AppStyle.neutral,
    color: Color(0xFFFBBF24),
    face: '\u{1F986}',
  ),
  Character(
    id: 'zed',
    name: 'ZED',
    look: AppStyle.cartoon,
    color: Color(0xFFEF4444),
    face: '\u{1F608}',
  ),
];

/// Looks up a character by id, falling back to the default. Never returns null
/// so callers always have a concrete theme + avatar to render.
Character characterById(String? id) {
  for (final c in kCharacters) {
    if (c.id == id) return c;
  }
  return kCharacters.firstWhere((c) => c.id == kDefaultCharacterId);
}
