import 'package:flutter/material.dart';

/// The app's single type family — Zain, chosen for on-screen readability.
/// See docs/font-picker.html for the comparison page used to pick it.
const String kFontFamily = 'Zain';

/// Persisted theme keys (stored in SharedPreferences under 'theme_key').
const String kThemeFusayfesa = 'f4'; // فسيفساء — light warm-paper mosaic, default
const String kThemeSukoon = 's5'; // سكون — near-black dark premium

/// Normalizes a persisted theme key. Legacy keys ('d1'/'d2'/'d3' from the
/// old seed-color themes) map to the default فسيفساء so returning users
/// don't fall back to an unknown key.
String normalizeThemeKey(String? key) {
  return switch (key) {
    kThemeFusayfesa || kThemeSukoon => key!,
    _ => kThemeFusayfesa,
  };
}

/// Builds the app [ThemeData] for a design key.
///
/// Each key is a complete design system: فسيفساء (light warm-paper mosaic
/// with giant Reem Kufi numerals) and سكون (near-black dark premium with a
/// single amber accent and hairline borders). The design IS the brightness,
/// so there is no separate dark-mode toggle.
ThemeData buildTheme(String key) {
  return switch (key) {
    kThemeSukoon => _buildSukoon(),
    _ => _buildFusayfesa(),
  };
}

// ---------------------------------------------------------------------------
// فسيفساء — light, warm paper, bento mosaic, big rounded tiles
// ---------------------------------------------------------------------------
ThemeData _buildFusayfesa() {
  const Color ink = Color(0xFF14213D);
  const Color paper = Color(0xFFFAF8F4);
  const Color muted = Color(0xFF6F7A8C);
  const Color teal = Color(0xFF0E7C66);
  const Color ember = Color(0xFFE8622B);

  const ColorScheme scheme = ColorScheme(
    brightness: Brightness.light,
    primary: teal,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDFF3EC),
    onPrimaryContainer: Color(0xFF0A3B2E),
    secondary: ember,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFDE8D9),
    onSecondaryContainer: Color(0xFF5A2A12),
    tertiary: Color(0xFF3B4A8C),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE8ECF7),
    onTertiaryContainer: Color(0xFF232A4E),
    error: Color(0xFFB3382C),
    onError: Colors.white,
    errorContainer: Color(0xFFFBE3E3),
    onErrorContainer: Color(0xFF5C1A12),
    surface: Colors.white,
    onSurface: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF6F4EF),
    surfaceContainer: Color(0xFFF1EEE8),
    surfaceContainerHigh: Color(0xFFEBE8E1),
    surfaceContainerHighest: Color(0xFFE3E0D9),
    onSurfaceVariant: muted,
    outline: Color(0xFFBEB8AA),
    outlineVariant: Color(0xFFE7E2D6),
    shadow: ink,
    scrim: ink,
    inverseSurface: ink,
    onInverseSurface: paper,
    inversePrimary: Color(0xFF9DD8C6),
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  return base.copyWith(
    textTheme: _arabicTextTheme(
      base.textTheme,
      displayWeight: FontWeight.w800,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Color(0xFFECEAE3)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7E2D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7E2D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB3382C)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: const Color(0xFFDFF3EC),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? teal : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? teal : muted,
          size: 24,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE7E2D6),
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: Color(0xFFE7E2D6)),
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontFamily: kFontFamily),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFFE7E2D6)),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: teal,
        side: const BorderSide(color: Color(0xFFB7D8CE)),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: muted,
      textColor: ink,
    ),
  );
}

// ---------------------------------------------------------------------------
// سكون — near-black, zero shadows, hairline borders, one amber accent
// ---------------------------------------------------------------------------
ThemeData _buildSukoon() {
  const Color ink = Color(0xFFF2F0EB);
  const Color bg = Color(0xFF0A0A0C);
  const Color surface = Color(0xFF121216);
  const Color surfaceHigh = Color(0xFF1A1A20);
  const Color muted = Color(0xFF8F8F86);
  const Color amber = Color(0xFFE8AD65);
  const Color hairline = Color(0xFF232329);

  const ColorScheme scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: amber,
    onPrimary: Color(0xFF1A1208),
    primaryContainer: Color(0xFF2A2114),
    onPrimaryContainer: Color(0xFFF3D9B5),
    secondary: Color(0xFFC9C4B8),
    onSecondary: Color(0xFF1E1D1A),
    secondaryContainer: Color(0xFF2A2A30),
    onSecondaryContainer: Color(0xFFE4E0D5),
    tertiary: muted,
    onTertiary: Color(0xFF141416),
    tertiaryContainer: Color(0xFF232329),
    onTertiaryContainer: Color(0xFFC9C4B8),
    error: Color(0xFFE57373),
    onError: Color(0xFF2B0A0A),
    errorContainer: Color(0xFF3A1D1D),
    onErrorContainer: Color(0xFFF3C6C6),
    surface: surface,
    onSurface: ink,
    surfaceContainerLowest: bg,
    surfaceContainerLow: Color(0xFF101014),
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: Color(0xFF212127),
    onSurfaceVariant: muted,
    outline: hairline,
    outlineVariant: hairline,
    shadow: Colors.transparent,
    scrim: Colors.black,
    inverseSurface: ink,
    onInverseSurface: bg,
    inversePrimary: amber,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  return base.copyWith(
    textTheme: _arabicTextTheme(
      base.textTheme,
      displayWeight: FontWeight.w700,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: hairline),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      hintStyle: const TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: amber, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: kFontFamily,
          fontSize: 10.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? amber : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? amber : muted,
          size: 23,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: hairline,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: hairline),
      backgroundColor: surface,
      labelStyle: const TextStyle(fontFamily: kFontFamily),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: amber,
        foregroundColor: const Color(0xFF1A1208),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceHigh,
        foregroundColor: ink,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: hairline),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: hairline),
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaceHigh,
      contentTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: hairline),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: muted,
      textColor: ink,
    ),
  );
}

/// Applies the app type family on top of the theme's text styles.
///
/// Display styles ([TextTheme.headline*] / [TextTheme.title*]) get a heavier
/// weight for hierarchy; body and data styles stay regular.
TextTheme _arabicTextTheme(
  TextTheme base, {
  required FontWeight displayWeight,
}) {
  TextStyle display(TextStyle style) => style.copyWith(
        fontFamily: kFontFamily,
        fontWeight: displayWeight,
      );
  TextStyle body(TextStyle style) => style.copyWith(
        fontFamily: kFontFamily,
      );

  return base.copyWith(
    displayLarge: display(base.displayLarge ?? const TextStyle()),
    displayMedium: display(base.displayMedium ?? const TextStyle()),
    displaySmall: display(base.displaySmall ?? const TextStyle()),
    headlineLarge: display(base.headlineLarge ?? const TextStyle()),
    headlineMedium: display(base.headlineMedium ?? const TextStyle()),
    headlineSmall: display(base.headlineSmall ?? const TextStyle()),
    titleLarge: display(base.titleLarge ?? const TextStyle()),
    titleMedium: display(base.titleMedium ?? const TextStyle()),
    titleSmall: display(base.titleSmall ?? const TextStyle()),
    bodyLarge: body(base.bodyLarge ?? const TextStyle()),
    bodyMedium: body(base.bodyMedium ?? const TextStyle()),
    bodySmall: body(base.bodySmall ?? const TextStyle()),
    labelLarge: body(base.labelLarge ?? const TextStyle()),
    labelMedium: body(base.labelMedium ?? const TextStyle()),
    labelSmall: body(base.labelSmall ?? const TextStyle()),
  );
}