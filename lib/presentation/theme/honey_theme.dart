import 'package:flutter/material.dart';

/// Centralized honey/bee theme styling for Honeycomb One Pass.
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

  // Star colors
  static const Color starFilled = Color(0xFFFFD700);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF3E2723);
  static const Color textSecondary = Color(0xFF5D4037);
  static const Color textOnPrimary = Color(0xFF3E2723);

  // Lock icon color
  static const Color lockColor = Color(0xFF9E9E9E);

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
