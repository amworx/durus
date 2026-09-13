import 'package:flutter/material.dart';

/// Persisted theme keys (stored in SharedPreferences under 'theme_key').
const String kThemeDaftar = 'd1'; // دفتر — warm brown, default
const String kThemeLawh = 'd2'; // لوح — teal
const String kThemeMaktab = 'd3'; // مكتب — slate

/// Builds the app [ThemeData] for a given theme key and brightness.
///
/// The three keys map to Material 3 seed colors. Light mode gets a warm
/// "paper" surface tint per theme so each option feels distinct.
ThemeData buildTheme(String key, {required bool dark}) {
  final bool compact = key == kThemeMaktab;

  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _seedFor(key),
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: _surfaceFor(key, dark: dark),
  );

  return ThemeData(
    colorScheme: scheme,
    visualDensity:
        compact ? VisualDensity.compact : VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Color _seedFor(String key) {
  return switch (key) {
    kThemeLawh => const Color(0xFF00897B),
    kThemeMaktab => const Color(0xFF1E293B),
    _ => const Color(0xFF7A5C3E),
  };
}

/// Light-mode surface tint. Returns null in dark mode (keep the tonal
/// surface) and for themes with no custom paper color.
Color? _surfaceFor(String key, {required bool dark}) {
  if (dark) {
    return null;
  }
  return switch (key) {
    kThemeLawh => const Color(0xFFF2FAF7),
    kThemeMaktab => null,
    _ => const Color(0xFFFDF8F2),
  };
}