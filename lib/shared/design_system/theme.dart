import 'package:flutter/material.dart';

/// Design tokens extracted from the Figma design
/// Provides consistent colors, typography, and spacing throughout the app
class AppDesignSystem {
  // Private constructor to prevent instantiation
  AppDesignSystem._();

  // ===== COLORS =====

  /// Main background colors
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color backgroundMedium = Color(0xFF232323);
  static const Color backgroundLight = Colors.white;

  /// Accent and interactive colors
  static const Color accentBlue = Color(0xFFA5D0F7);
  static const Color errorRed = Color(0xFFDE3737);

  /// Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textDisabled = Color(0xFF404040);
  static const Color textOnLight = Colors.black;

  /// Border and divider colors
  static Color dividerLight = Colors.white.withValues(alpha: 0.14);
  static Color dividerError = const Color(0xFFDE3737).withValues(alpha: 0.14);

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
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: accentBlue,
        secondary: accentBlue,
        error: errorRed,
        surface: backgroundMedium,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: dividerLight, thickness: 1),
    );
  }
}
