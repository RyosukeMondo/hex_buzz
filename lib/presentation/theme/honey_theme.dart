import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  static const Color honeyGoldDark = Color(0xFFFFB300);

  // Secondary deep honey/orange colors
  static const Color deepHoney = Color(0xFFFF8F00);
  static const Color deepHoneyLight = Color(0xFFFFA000);
  static const Color deepHoneyDark = Color(0xFFFF6F00);

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

  // Lock icon color
  static const Color lockColor = Color(0xFF9E9E9E);

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
}

/// Custom decorations for honeycomb-style UI elements.
class HoneycombDecorations {
  HoneycombDecorations._();

  /// Decoration for level cells in the selection grid.
  static BoxDecoration levelCell({
    required bool isUnlocked,
    required bool isCompleted,
  }) {
    return BoxDecoration(
      color: isUnlocked
          ? (isCompleted ? HoneyTheme.honeyGoldLight : HoneyTheme.warmCream)
          : HoneyTheme.warmCreamDark.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isUnlocked ? HoneyTheme.honeyGold : HoneyTheme.lockColor,
        width: isUnlocked ? 2 : 1,
      ),
      boxShadow: isUnlocked
          ? [
              BoxShadow(
                color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Decoration for completion overlay card.
  static BoxDecoration completionCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: HoneyTheme.honeyGold, width: 3),
      boxShadow: [
        BoxShadow(
          color: HoneyTheme.brownAccent.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Gradient for honey-drip effect on path.
  static LinearGradient pathGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [HoneyTheme.honeyGoldLight, HoneyTheme.deepHoney],
    );
  }

  /// Decoration for star display container.
  static BoxDecoration starContainer() {
    return BoxDecoration(
      color: HoneyTheme.warmCream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: HoneyTheme.honeyGold.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }
}
