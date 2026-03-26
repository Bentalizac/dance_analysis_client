import 'package:flutter/material.dart';

/// Design tokens extracted from the Figma design
/// Provides consistent colors, typography, and spacing throughout the app
class AppDesignSystem {
  // Private constructor to prevent instantiation
  AppDesignSystem._();

  // ===== COLORS =====

  // Branding palette (not for direct UI use as interactive colors)
  //
  // Main Accent: 0xFF5F2E8F
  // Contrast Accent: 0xFF2FF9FA — NOT the hover/interactive color for the main accent
  // Light Background: 0xFFFaf1ec
  // Mid Grey: 0xFF626262

  /// Brand colors — use for logo, illustration, identity; not raw UI chrome
  static const Color brandPurple = Color(0xFF5F2E8F);
  static const Color brandCyan = Color(0xFF2FF9FA);

  /// Background colors
  static const Color backgroundLight = Color(0xFFFAF1EC); // warm cream — primary scaffold
  static const Color backgroundMedium = Color(0xFFFFFFFF); // white — cards / surfaces
  static const Color backgroundDark = Color(0xFF1A1A1A);  // reserved for dark overlays / future dark mode

  /// Accent and interactive colors
  static const Color mainAccent = Color(0xFF9060C8);
  static const Color mainAccentHover = Color(0xFFA878D8);
  static const Color errorRed = Color(0xFFDE3737);

  /// Text colors (tuned for light backgrounds)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF626262);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnDark = Colors.white;

  /// Border and divider colors
  static const Color dividerLight = Color(0xFFE0D8D2); // visible on cream/white
  static Color dividerError = const Color(0xFFDE3737).withValues(alpha: 0.20);

  // ===== TYPOGRAPHY =====

  /// Timestamp text style (16pt, medium weight)
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.13,
    letterSpacing: -0.08,
  );

  /// Feedback text style (14pt, medium weight)
  static const TextStyle feedbackStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.29,
    letterSpacing: -0.08,
  );

  /// Tab/button text style (14pt, semi-bold)
  static const TextStyle tabStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.08,
  );

  /// Small text style (12pt)
  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ===== SPACING =====

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 22.0;
  static const double spacingXl = 31.0;

  // ===== BORDER RADIUS =====

  static const double radiusXs = 7.0;
  static const double radiusSm = 18.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 50.0;
  static const double radiusXl = 60.0;
  static const double radiusPill = 100.0;

  // ===== SHADOWS =====

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ===== THEME =====

  /// Returns a complete Material ThemeData based on the design system
  static ThemeData get darkTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: mainAccent,
        secondary: mainAccent,
        error: errorRed,
        surface: backgroundMedium,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textDisabled),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}
