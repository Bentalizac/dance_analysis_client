import 'package:flutter/material.dart';

/// Central design-system for the app.
///
/// **Usage rule:** widget code must never reference [AppDesignSystem] color or
/// text-style constants directly. Always consume them through
/// `Theme.of(context).colorScheme` or `Theme.of(context).textTheme`.
///
/// Spacing and radius constants are layout-only and remain safe to use
/// directly anywhere in the widget tree.
///
/// To change a color or type style, edit the token constant here and it
/// propagates everywhere automatically via [AppDesignSystem.theme].
class AppDesignSystem {
  AppDesignSystem._();

  // =========================================================================
  // COLORS — the palette
  //
  // These constants define every colour in the app. They are mapped to
  // semantic Material [ColorScheme] roles in [theme] below. Add new tokens
  // here when the design calls for a new colour; map them in [theme].
  // =========================================================================

  // -- Branding (identity only, not for interactive chrome) -----------------
  static const Color brandPurple = Color(0xFF5F2E8F);
  static const Color brandCyan = Color(0xFF2FF9FA);

  // -- Backgrounds ----------------------------------------------------------
  /// Warm cream — scaffold / page background.
  static const Color backgroundLight = Color(0xFFFAF1EC);

  /// Pure white — cards, sheets, dialogs.
  static const Color backgroundMedium = Color(0xFFFFFFFF);

  /// Slightly tinted — chip fills, input fills, subtle containers.
  static const Color backgroundSubtle = Color(0xFFEDE5DE);

  /// Near-black — dark overlays, snackbars, future dark mode.
  static const Color backgroundDark = Color(0xFF1A1A1A);

  // -- Interactive ----------------------------------------------------------
  static const Color mainAccent = Color(0xFF9060C8);
  static const Color mainAccentHover = Color(0xFFA878D8);

  // -- Semantic -------------------------------------------------------------
  static const Color errorRed = Color(0xFFDE3737);
  static const Color warning = Color(0xFFE07B2A);
  static const Color success = Color(0xFF2E8B57);

  // -- Text -----------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF626262);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnDark = Colors.white;

  // -- Borders --------------------------------------------------------------
  static const Color dividerLight = Color(0xFFE0D8D2);

  /// Dynamic — cannot be const due to withValues().
  static Color get dividerError => errorRed.withValues(alpha: 0.20);

  // =========================================================================
  // TYPOGRAPHY
  //
  // These named styles are mapped to [TextTheme] slots in [theme]. Prefer
  // `Theme.of(context).textTheme.bodyMedium` etc. over referencing these
  // constants directly in widget code.
  //
  // Aliases are provided so existing callers continue to compile during the
  // migration to Theme.of. Remove aliases once migration is complete.
  // =========================================================================

  /// → titleMedium
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.13,
    letterSpacing: -0.08,
  );

  /// → bodyMedium
  static const TextStyle feedbackStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.29,
    letterSpacing: -0.08,
  );

  /// → labelLarge
  static const TextStyle tabStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.08,
  );

  /// → bodySmall
  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // =========================================================================
  // SPACING  (layout constants — always fine to use directly)
  // =========================================================================

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 22.0;
  static const double spacingXl = 31.0;

  // =========================================================================
  // BORDER RADIUS  (layout constants — always fine to use directly)
  // =========================================================================

  static const double radiusXs = 7.0;
  static const double radiusSm = 18.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 50.0;
  static const double radiusXl = 60.0;
  static const double radiusPill = 100.0;

  // =========================================================================
  // SHADOWS
  // =========================================================================

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 2)),
  ];

  // =========================================================================
  // THEME
  //
  // Single entry-point consumed by MaterialApp.theme. Every colour and text
  // style below traces back to a token constant above — change the token,
  // the whole app updates.
  // =========================================================================

  static ThemeData get theme {
    return ThemeData.light().copyWith(
      // -- Scaffold -----------------------------------------------------------
      scaffoldBackgroundColor: backgroundLight,

      // -- Colour scheme ------------------------------------------------------
      colorScheme: ColorScheme.light(
        // Primary
        primary: mainAccent,
        onPrimary: Colors.white,
        primaryContainer: Color(0x269060C8), // mainAccent @ ~15 % opacity
        onPrimaryContainer: mainAccent,

        // Secondary (same as primary for now — revisit when design diverges)
        secondary: mainAccent,
        onSecondary: Colors.white,
        secondaryContainer: Color(0x269060C8),
        onSecondaryContainer: mainAccent,

        // Error / warning
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0x26DE3737), // errorRed @ ~15 % opacity
        onErrorContainer: errorRed,

        // Surfaces
        surface: backgroundMedium,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerLowest: backgroundLight,
        surfaceContainerLow: backgroundLight,
        surfaceContainer: backgroundSubtle,
        surfaceContainerHigh: backgroundSubtle,
        surfaceContainerHighest: backgroundSubtle,

        // Borders
        outline: dividerLight,
        outlineVariant: dividerLight,

        // Inverse / overlays
        inverseSurface: backgroundDark,
        onInverseSurface: Colors.white,
        inversePrimary: mainAccentHover,
      ),

      // -- Text theme ---------------------------------------------------------
      // Every slot carries a colour so callers need only reference the slot,
      // not combine a slot with a manual color override.
      textTheme: const TextTheme(
        // Headlines — large section titles
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),

        // Titles — app-bar, card headers, list section headings
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          // ← timestampStyle
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.13,
          letterSpacing: -0.08,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),

        // Body — paragraph / detail text
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
        ),
        bodyMedium: TextStyle(
          // ← feedbackStyle
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.29,
          letterSpacing: -0.08,
        ),
        bodySmall: TextStyle(
          // ← smallTextStyle
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),

        // Labels — buttons, chips, tabs, captions
        labelLarge: TextStyle(
          // ← tabStyle
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.29,
          letterSpacing: -0.08,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // -- App bar ------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // -- Cards --------------------------------------------------------------
      cardTheme: CardThemeData(
        color: backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      // -- Dialogs ------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 4,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // -- Bottom navigation --------------------------------------------------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundMedium,
        selectedItemColor: mainAccent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // -- Tab bar ------------------------------------------------------------
      tabBarTheme: const TabBarThemeData(
        indicatorColor: mainAccent,
        labelColor: mainAccent,
        unselectedLabelColor: textSecondary,
        dividerColor: dividerLight,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.08,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.08,
        ),
      ),

      // -- Chips --------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSubtle,
        selectedColor: mainAccent,
        disabledColor: backgroundSubtle,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: dividerLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        showCheckmark: false,
      ),

      // -- Input decoration ---------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSubtle,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textDisabled),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: mainAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),

      // -- Buttons ------------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: mainAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: backgroundSubtle,
          disabledForegroundColor: textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: backgroundSubtle,
          disabledForegroundColor: textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mainAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mainAccent,
          side: const BorderSide(color: mainAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),

      // -- Floating action button ---------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: mainAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 6,
        shape: CircleBorder(),
      ),

      // -- Snack bar ----------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // -- Divider ------------------------------------------------------------
      dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1),

      // -- List tile ----------------------------------------------------------
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingXs,
        ),
        iconColor: textSecondary,
      ),

      // -- Progress indicator -------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: mainAccent,
        linearTrackColor: Color(0x269060C8), // mainAccent @ ~15 %
      ),

      // -- Icon ---------------------------------------------------------------
      iconTheme: const IconThemeData(color: textPrimary),
    );
  }

  // Deprecated alias — remove once all call-sites are migrated to [theme].
  @Deprecated('Use AppDesignSystem.theme')
  static ThemeData get darkTheme => theme;
}
