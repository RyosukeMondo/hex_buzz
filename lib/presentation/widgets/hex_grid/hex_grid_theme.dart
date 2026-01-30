import 'package:flutter/material.dart';

import '../../theme/honey_theme.dart';

/// Theme configuration for hex grid styling.
///
/// Encapsulates all color and styling decisions for the hex grid,
/// making it easy to customize appearance and test visual changes.
@immutable
class HexGridTheme {
  final Color honeyGold;
  final Color honeyGoldDark;
  final Color deepHoney;

  const HexGridTheme({
    required this.honeyGold,
    required this.honeyGoldDark,
    required this.deepHoney,
  });

  /// Creates theme from app's HoneyTheme.
  factory HexGridTheme.fromHoneyTheme() {
    return const HexGridTheme(
      honeyGold: HoneyTheme.honeyGold,
      honeyGoldDark: HoneyTheme.honeyGoldDark,
      deepHoney: HoneyTheme.deepHoney,
    );
  }

  /// Calculates the gradient color for a cell based on path progress.
  ///
  /// Progress ranges from 0.0 (start) to 1.0 (end).
  /// Returns a color interpolated through the honey gradient.
  Color colorForProgress(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    if (clampedProgress < 0.5) {
      final t = clampedProgress * 2;
      return Color.lerp(honeyGold, honeyGoldDark, t)!;
    } else {
      final t = (clampedProgress - 0.5) * 2;
      return Color.lerp(honeyGoldDark, deepHoney, t)!;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HexGridTheme &&
        other.honeyGold == honeyGold &&
        other.honeyGoldDark == honeyGoldDark &&
        other.deepHoney == deepHoney;
  }

  @override
  int get hashCode => Object.hash(honeyGold, honeyGoldDark, deepHoney);
}
