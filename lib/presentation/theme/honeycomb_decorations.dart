import 'package:flutter/material.dart';

import 'honey_theme.dart';

/// Custom decorations for honeycomb-style UI elements.
///
/// Methods accept an optional [BuildContext] for theme-aware colors.
/// When context is null, light-mode colors are used as a fallback.
class HoneycombDecorations {
  HoneycombDecorations._();

  /// Decoration for level cells in the selection grid.
  static BoxDecoration levelCell({
    required bool isUnlocked,
    required bool isCompleted,
    BuildContext? context,
  }) {
    final dark = context != null && HoneyTheme.isDark(context);
    final unvisitedColor = dark
        ? HoneyTheme.darkCellUnvisited
        : HoneyTheme.warmCream;
    final completedColor = dark
        ? HoneyTheme.honeyGold.withValues(alpha: 0.3)
        : HoneyTheme.honeyGoldLight;
    final lockedColor = dark
        ? HoneyTheme.darkSurfaceContainer.withValues(alpha: 0.5)
        : HoneyTheme.warmCreamDark.withValues(alpha: 0.5);

    return BoxDecoration(
      color: isUnlocked
          ? (isCompleted ? completedColor : unvisitedColor)
          : lockedColor,
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
  static BoxDecoration completionCard({BuildContext? context}) {
    final dark = context != null && HoneyTheme.isDark(context);
    return BoxDecoration(
      color: dark ? HoneyTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: HoneyTheme.honeyGold, width: 3),
      boxShadow: [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.4)
              : HoneyTheme.brownAccent.withValues(alpha: 0.2),
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
  static BoxDecoration starContainer({BuildContext? context}) {
    final dark = context != null && HoneyTheme.isDark(context);
    return BoxDecoration(
      color: dark ? HoneyTheme.darkSurfaceContainer : HoneyTheme.warmCream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: HoneyTheme.honeyGold.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }
}
