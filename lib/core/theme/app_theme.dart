import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_style.dart';

/// Builds ThemeData for a given [AppStyle] and [Brightness].
///
/// Scaffolds are transparent: the [AmbientBackground] painted at the app root
/// shows through. Depth comes from layered [SurfaceCard]s, not from heavy
/// glows, matching the reference design language.
class AppTheme {
  static ThemeData build(AppStyle style, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: style.accent,
      brightness: brightness,
    ).copyWith(
      surface: style.cardColor(dark),
      surfaceContainerHigh: style.cardColorAlt(dark),
    );

    final textTheme = _textTheme(style, brightness, scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: style.accent,
          foregroundColor: style.onAccent,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 54),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: style.accent,
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: style.accent,
        foregroundColor: style.onAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.buttonRadius + 6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        space: 0,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: style.cardColor(dark),
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(style.cardRadius + 8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: style.cardColorAlt(dark),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.cardRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(style.cardRadius),
          borderSide: BorderSide(color: style.accent, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  static TextTheme _textTheme(
      AppStyle style, Brightness brightness, ColorScheme scheme) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final fonted = switch (style) {
      AppStyle.playful => GoogleFonts.nunitoTextTheme(base),
      AppStyle.neutral => GoogleFonts.interTextTheme(base),
      AppStyle.glass => GoogleFonts.outfitTextTheme(base),
    };
    return fonted.copyWith(
      headlineMedium: fonted.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineSmall: fonted.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: scheme.onSurface,
      ),
      titleLarge: fonted.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: fonted.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      labelLarge: fonted.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
