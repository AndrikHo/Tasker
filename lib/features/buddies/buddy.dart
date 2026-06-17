import 'package:flutter/material.dart';

/// A "LIFE FRIENDS" buddy: a small cartoon character that peeks in from the
/// edge of the screen now and then.
///
/// The roster below is the canonical cast. Art is generated separately and
/// dropped into `assets/mascots/<id>.png` (transparent, @3x, foot-baseline
/// aligned to the bottom of the canvas — see assets/mascots/SPEC.md). Until a
/// PNG exists for a buddy, [BuddyArt] renders a colored placeholder blob using
/// [color] + [face]. Swapping in real art is a one-line change in [BuddyArt].
class Buddy {
  const Buddy({
    required this.id,
    required this.name,
    required this.color,
    required this.face,
  });

  /// Stable id, also the asset file stem: `assets/mascots/<id>.png`.
  final String id;

  /// Display name (proper noun, not localized).
  final String name;

  /// Signature color, drives the placeholder + any accent tie-ins.
  final Color color;

  /// Placeholder face emoji, used until real art lands.
  final String face;

  String get asset => 'assets/mascots/$id.png';
}

/// The canonical cast. Order is stable; pick randomly at the call site.
const kBuddies = <Buddy>[
  Buddy(id: 'zed', name: 'ZED', color: Color(0xFFEF4444), face: '\u{1F608}'),
  Buddy(id: 'bunni', name: 'BUNNI', color: Color(0xFFFF7AC6), face: '\u{1F430}'),
  Buddy(id: 'meow', name: 'MEOW', color: Color(0xFF94A3B8), face: '\u{1F431}'),
  Buddy(id: 'bear', name: 'BEAR', color: Color(0xFFD2A679), face: '\u{1F43B}'),
  Buddy(id: 'panda', name: 'PANDA', color: Color(0xFF4ADE80), face: '\u{1F43C}'),
  Buddy(id: 'ducky', name: 'DUCKY', color: Color(0xFFFBBF24), face: '\u{1F986}'),
  Buddy(id: 'devv', name: 'DEVV', color: Color(0xFFDC2626), face: '\u{1F916}'),
  Buddy(id: 'luna', name: 'LUNA', color: Color(0xFF60A5FA), face: '\u{1F319}'),
  Buddy(id: 'dino', name: 'DINO', color: Color(0xFF34D399), face: '\u{1F995}'),
  Buddy(id: 'byte', name: 'BYTE', color: Color(0xFF22D3EE), face: '\u{1F47E}'),
];
