import 'package:flutter/material.dart';

/// App-wide visual styles. Switching the style restyles the entire app
/// (colors, typography, shapes, motion). Works on top of light/dark.
enum AppStyle {
  playful,
  neutral,
  glass,
  cartoon,
}

extension AppStyleX on AppStyle {
  String get id => name;

  static AppStyle fromId(String? id) {
    return AppStyle.values.firstWhere(
      (s) => s.name == id,
      orElse: () => AppStyle.glass,
    );
  }

  /// Human label shown in the style picker (proper noun, not localized).
  String get label => switch (this) {
        AppStyle.playful => 'Playful',
        AppStyle.neutral => 'Neutral',
        AppStyle.glass => 'Glass',
        AppStyle.cartoon => 'Cartoon',
      };

  /// Brand accent / seed color per style.
  Color get accent => switch (this) {
        AppStyle.playful => const Color(0xFFC6F432), // lime neon
        AppStyle.neutral => const Color(0xFFF5B301), // amber
        AppStyle.glass => const Color(0xFF22D3EE), // cyan
        AppStyle.cartoon => const Color(0xFF8B5CF6), // violet pop
      };

  /// A secondary accent used for gradients / highlights.
  Color get accent2 => switch (this) {
        AppStyle.playful => const Color(0xFF4ADE80), // green
        AppStyle.neutral => const Color(0xFFFB7185), // rose
        AppStyle.glass => const Color(0xFF818CF8), // indigo
        AppStyle.cartoon => const Color(0xFFFF7AC6), // bubblegum pink
      };

  /// Readable foreground color to lay over [accent] (e.g. button text).
  Color get onAccent =>
      accent.computeLuminance() > 0.5 ? const Color(0xFF0B0B0D) : Colors.white;

  // ---------------------------------------------------------------------------
  // Shape
  // ---------------------------------------------------------------------------

  /// Corner radius for cards/sheets.
  double get cardRadius => switch (this) {
        AppStyle.playful => 28,
        AppStyle.neutral => 20,
        AppStyle.glass => 24,
        AppStyle.cartoon => 34,
      };

  /// Corner radius for nested chips / small surfaces.
  double get chipRadius => switch (this) {
        AppStyle.playful => 16,
        AppStyle.neutral => 12,
        AppStyle.glass => 14,
        AppStyle.cartoon => 20,
      };

  /// Corner radius for buttons (primary CTAs are fully rounded pills).
  double get buttonRadius => switch (this) {
        AppStyle.playful => 18,
        AppStyle.neutral => 14,
        AppStyle.glass => 16,
        AppStyle.cartoon => 22,
      };

  // ---------------------------------------------------------------------------
  // Motion
  // ---------------------------------------------------------------------------

  /// Motion duration for transitions.
  Duration get motion => switch (this) {
        AppStyle.playful => const Duration(milliseconds: 420),
        AppStyle.neutral => const Duration(milliseconds: 220),
        AppStyle.glass => const Duration(milliseconds: 300),
        AppStyle.cartoon => const Duration(milliseconds: 480),
      };

  /// Motion curve.
  Curve get curve => switch (this) {
        AppStyle.playful => Curves.easeOutBack,
        AppStyle.neutral => Curves.easeOutCubic,
        AppStyle.glass => Curves.easeOutCubic,
        AppStyle.cartoon => Curves.elasticOut,
      };

  /// Press-scale used by tappable cards for tactile feedback.
  double get pressScale => switch (this) {
        AppStyle.playful => 0.96,
        AppStyle.neutral => 0.985,
        AppStyle.glass => 0.97,
        AppStyle.cartoon => 0.93,
      };

  // ---------------------------------------------------------------------------
  // Base / backdrop
  // ---------------------------------------------------------------------------

  /// Scaffold base color for the dark theme. Deep, faintly tinted near-black.
  Color get baseDark => switch (this) {
        AppStyle.playful => const Color(0xFF0A0D07),
        AppStyle.neutral => const Color(0xFF0B0B0D),
        AppStyle.glass => const Color(0xFF080B11),
        AppStyle.cartoon => const Color(0xFF130C1F),
      };

  /// Scaffold base color for the light theme.
  Color get baseLight => switch (this) {
        AppStyle.playful => const Color(0xFFF4F7EC),
        AppStyle.neutral => const Color(0xFFF5F5F7),
        AppStyle.glass => const Color(0xFFEFF4FA),
        AppStyle.cartoon => const Color(0xFFF7F0FF),
      };

  /// Opacity of the ambient accent glow painted behind content. Kept low so
  /// depth comes from layered surfaces, not a muddy wash.
  double get glowOpacity => switch (this) {
        AppStyle.playful => 0.10,
        AppStyle.neutral => 0.06,
        AppStyle.glass => 0.11,
        AppStyle.cartoon => 0.14,
      };

  // ---------------------------------------------------------------------------
  // Surfaces & depth (reference-grade layering)
  // ---------------------------------------------------------------------------

  /// Whether the glass surface treatment (blur) applies.
  bool get glassy => this == AppStyle.glass;

  /// Blur strength for frosted-glass surfaces. Only meaningful for [glass].
  double get blurSigma => switch (this) {
        AppStyle.playful => 0,
        AppStyle.neutral => 0,
        AppStyle.glass => 18,
        AppStyle.cartoon => 0,
      };

  /// Primary card / surface fill, one clear step above the base.
  Color cardColor(bool dark) => dark
      ? switch (this) {
          AppStyle.playful => const Color(0xFF15190E),
          AppStyle.neutral => const Color(0xFF17171C),
          AppStyle.glass => const Color(0xFF111A27),
          AppStyle.cartoon => const Color(0xFF1F1430),
        }
      : Colors.white;

  /// Nested / secondary surface fill, a further step up from [cardColor].
  Color cardColorAlt(bool dark) => dark
      ? switch (this) {
          AppStyle.playful => const Color(0xFF1E2414),
          AppStyle.neutral => const Color(0xFF22222A),
          AppStyle.glass => const Color(0xFF1A2433),
          AppStyle.cartoon => const Color(0xFF2C1E43),
        }
      : switch (this) {
          AppStyle.playful => const Color(0xFFEDF2E3),
          AppStyle.neutral => const Color(0xFFF0F0F3),
          AppStyle.glass => const Color(0xFFEAF1F8),
          AppStyle.cartoon => const Color(0xFFF0E6FB),
        };

  /// Translucent fill for the frosted [glass] surface (paired with blur).
  Color glassFill(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.55);

  /// Soft drop shadow that lifts a card off the background.
  List<BoxShadow> cardShadow(bool dark) => dark
      ? const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0x16000000),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ];

  /// Hairline highlight along the edge of a surface for a crisp lip.
  Color hairline(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.05);
}
