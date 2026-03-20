import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'honeycomb_decorations.dart';

/// Centralized honey/bee theme styling for HexBuzz.
///
/// Color palette based on requirements:
/// - Primary: Amber/honey gold (#FFC107, #FFB300)
/// - Secondary: Deep honey/orange (#FF8F00, #FF6F00)
/// - Background: Warm cream (#FFF8E1, #FFECB3)
/// - Accents: Brown (#795548) for contrast
class HoneyTheme {
  HoneyTheme._();

  // Primary honey gold colors
  static const Color honeyGold = Color(0xFFFFC107);
  static const Color honeyGoldLight = Color(0xFFFFD54F);
  // Darker for better contrast on light backgrounds (used for large text)
  static const Color honeyGoldDark = Color(
    0xFFE65100,
  ); // Deep orange for 3:1+ contrast

  // Secondary deep honey/orange colors
  // Using darker shades for better contrast on light backgrounds
  static const Color deepHoney = Color(
    0xFFE65100,
  ); // Darker orange for 3:1+ contrast
  static const Color deepHoneyLight = Color(0xFFF57C00);
  static const Color deepHoneyDark = Color(
    0xFFBF360C,
  ); // Even darker for emphasis

  // Background warm cream colors
  static const Color warmCream = Color(0xFFFFF8E1);
  static const Color warmCreamDark = Color(0xFFFFECB3);

  // Accent brown colors
  static const Color brownAccent = Color(0xFF795548);
  static const Color brownAccentLight = Color(0xFF8D6E63);
  static const Color brownAccentDark = Color(0xFF5D4037);

  // Honeycomb cell colors
  static const Color cellUnvisited = Color(0xFFFFF3E0);
  static const Color cellVisited = Color(0xFFFFB300);
  static const Color cellBorder = Color(0xFFFFCC80);
  static const Color cellBorderStart = Color(0xFF4CAF50);
  static const Color cellBorderEnd = Color(0xFFF44336);

  // Star colors (WCAG AA compliant)
  static const Color starFilled = Color(0xFFFFD700);
  static const Color starEmpty = Color(0xFFBDBDBD);
  static const Color starEmptyOutline = Color(0xFF757575);

  // Text colors
  static const Color textPrimary = Color(0xFF3E2723);
  static const Color textSecondary = Color(0xFF5D4037);
  static const Color textOnPrimary = Color(0xFF3E2723);

  // Lock icon color - darkened for better contrast on cream backgrounds
  static const Color lockColor = Color(0xFF757575);

  // ============================================
  // Dark Mode Colors
  // ============================================
  // Warm dark palette - avoids cold/blue tones to match honey aesthetic.

  /// Dark background with a warm undertone.
  static const Color darkBackground = Color(0xFF1A1410);

  /// Slightly lighter surface for cards/containers in dark mode.
  static const Color darkSurface = Color(0xFF241E18);

  /// Elevated surface for cards in dark mode.
  static const Color darkSurfaceContainer = Color(0xFF2E2620);

  /// Primary text on dark backgrounds.
  static const Color darkTextPrimary = Color(0xFFFFF3E0);

  /// Secondary text on dark backgrounds.
  static const Color darkTextSecondary = Color(0xFFD7CCC8);

  /// Honeycomb cell unvisited color in dark mode.
  static const Color darkCellUnvisited = Color(0xFF2E2620);

  /// Honeycomb cell border in dark mode.
  static const Color darkCellBorder = Color(0xFF5D4037);

  // ============================================
  // Spacing Constants
  // ============================================

  /// Extra small spacing (4.0)
  static const double spacingXs = 4.0;

  /// Small spacing (8.0)
  static const double spacingSm = 8.0;

  /// Medium spacing (12.0)
  static const double spacingMd = 12.0;

  /// Large spacing (16.0)
  static const double spacingLg = 16.0;

  /// Extra large spacing (24.0)
  static const double spacingXl = 24.0;

  /// Extra extra large spacing (32.0)
  static const double spacingXxl = 32.0;

  // ============================================
  // Sizing Constants
  // ============================================

  /// Default level cell size
  static const double levelCellSize = 80.0;

  /// Default icon size small
  static const double iconSizeSm = 16.0;

  /// Default icon size medium
  static const double iconSizeMd = 24.0;

  /// Default icon size large
  static const double iconSizeLg = 48.0;

  /// Default icon size extra large
  static const double iconSizeXl = 64.0;

  // ============================================
  // Border Radius Constants
  // ============================================

  /// Small border radius (8.0)
  static const double radiusSm = 8.0;

  /// Medium border radius (12.0)
  static const double radiusMd = 12.0;

  /// Large border radius (16.0)
  static const double radiusLg = 16.0;

  /// Extra large border radius (20.0)
  static const double radiusXl = 20.0;

  /// Circular border radius (24.0)
  static const double radiusCircular = 24.0;

  // ============================================
  // Contrast Utilities
  // ============================================

  /// Calculates the relative luminance of a color per WCAG 2.1.
  ///
  /// Returns a value between 0.0 (black) and 1.0 (white).
  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates the contrast ratio between two colors per WCAG 2.1.
  ///
  /// Returns a value between 1:1 and 21:1.
  /// WCAG AA requires 4.5:1 for normal text, 3:1 for large text.
  /// WCAG AAA requires 7:1 for normal text, 4.5:1 for large text.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns true if the contrast ratio meets WCAG AA for normal text (4.5:1).
  static bool meetsContrastAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Returns true if the contrast ratio meets WCAG AA for large text (3:1).
  static bool meetsContrastAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  /// Returns the best contrasting text color (dark or light) for a background.
  ///
  /// Uses the luminance of the background to determine if dark or light
  /// text provides better contrast.
  static Color contrastingTextColor(Color background) {
    final luminance = relativeLuminance(background);
    return luminance > 0.5 ? textPrimary : Colors.white;
  }

  // ============================================
  // Border Width Constants
  // ============================================

  /// Thin border width (1.0)
  static const double borderThin = 1.0;

  /// Normal border width (2.0)
  static const double borderNormal = 2.0;

  /// Thick border width (3.0)
  static const double borderThick = 3.0;

  // ============================================
  // Grid Constants
  // ============================================

  /// Number of columns in level selection grid
  static const int gridColumns = 3;

  /// Grid spacing between cells
  static const double gridSpacing = 16.0;

  /// Light theme for the app.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: honeyGold,
        brightness: Brightness.light,
        primary: honeyGold,
        onPrimary: textOnPrimary,
        primaryContainer: honeyGoldLight,
        onPrimaryContainer: brownAccentDark,
        secondary: deepHoney,
        onSecondary: Colors.white,
        secondaryContainer: deepHoneyLight,
        onSecondaryContainer: brownAccentDark,
        tertiary: brownAccent,
        onTertiary: Colors.white,
        tertiaryContainer: brownAccentLight,
        onTertiaryContainer: Colors.white,
        surface: warmCream,
        onSurface: textPrimary,
        surfaceContainerHighest: warmCreamDark,
        error: Colors.red.shade700,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: warmCream,
      appBarTheme: const AppBarTheme(
        backgroundColor: honeyGold,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: honeyGold,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brownAccent,
          side: const BorderSide(color: brownAccent, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: deepHoney),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: brownAccent),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: textPrimary),
        labelSmall: TextStyle(color: textSecondary),
      ),
    );
  }

  /// Dark theme for the app.
  ///
  /// Uses a warm, honeyed dark palette. Retains honey gold as primary
  /// to keep brand identity while providing comfortable dark-mode contrast.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: honeyGold,
        brightness: Brightness.dark,
        primary: honeyGold,
        onPrimary: textOnPrimary,
        primaryContainer: brownAccentDark,
        onPrimaryContainer: honeyGoldLight,
        secondary: deepHoneyLight,
        onSecondary: Colors.white,
        secondaryContainer: brownAccent,
        onSecondaryContainer: honeyGoldLight,
        tertiary: brownAccentLight,
        onTertiary: Colors.white,
        tertiaryContainer: brownAccentDark,
        onTertiaryContainer: warmCreamDark,
        surface: darkBackground,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceContainer,
        error: Colors.red.shade400,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: honeyGold,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: honeyGold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: honeyGold,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: honeyGoldLight,
          side: const BorderSide(color: honeyGold, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: honeyGoldLight),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: honeyGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: honeyGold),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return honeyGold;
          return darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return honeyGold.withValues(alpha: 0.4);
          }
          return darkSurfaceContainer;
        }),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: darkTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: darkTextPrimary),
        labelSmall: TextStyle(color: darkTextSecondary),
      ),
    );
  }

  /// Returns whether the current context is in dark mode.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Returns the appropriate card/surface background color for the theme.
  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkSurface : Colors.white;
  }

  /// Returns the appropriate scaffold background color for the theme.
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Returns the appropriate primary text color for the theme.
  static Color primaryTextColor(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  /// Returns the appropriate secondary text color for the theme.
  static Color secondaryTextColor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  /// Returns the appropriate cell unvisited color for the theme.
  static Color cellUnvisitedColor(BuildContext context) {
    return isDark(context) ? darkCellUnvisited : cellUnvisited;
  }

  /// Returns the appropriate cell border color for the theme.
  static Color cellBorderColor(BuildContext context) {
    return isDark(context) ? darkCellBorder : cellBorder;
  }
}
