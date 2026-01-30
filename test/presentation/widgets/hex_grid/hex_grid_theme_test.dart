import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_theme.dart';

void main() {
  group('HexGridTheme', () {
    test('creates from HoneyTheme', () {
      final theme = HexGridTheme.fromHoneyTheme();

      expect(theme.honeyGold, equals(HoneyTheme.honeyGold));
      expect(theme.honeyGoldDark, equals(HoneyTheme.honeyGoldDark));
      expect(theme.deepHoney, equals(HoneyTheme.deepHoney));
    });

    test('calculates color for progress 0.0', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(0.0);

      expect(color, equals(HoneyTheme.honeyGold));
    });

    test('calculates color for progress 0.5', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(0.5);

      // Should be honeyGoldDark at midpoint
      expect(color, equals(HoneyTheme.honeyGoldDark));
    });

    test('calculates color for progress 1.0', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(1.0);

      expect(color, equals(HoneyTheme.deepHoney));
    });

    test('clamps progress below 0.0', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(-0.5);

      expect(color, equals(HoneyTheme.honeyGold));
    });

    test('clamps progress above 1.0', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(1.5);

      expect(color, equals(HoneyTheme.deepHoney));
    });

    test('interpolates color in first half', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(0.25);

      // Should be between honeyGold and honeyGoldDark
      final expected = Color.lerp(
        HoneyTheme.honeyGold,
        HoneyTheme.honeyGoldDark,
        0.5,
      );
      expect(color, equals(expected));
    });

    test('interpolates color in second half', () {
      final theme = HexGridTheme.fromHoneyTheme();
      final color = theme.colorForProgress(0.75);

      // Should be between honeyGoldDark and deepHoney
      final expected = Color.lerp(
        HoneyTheme.honeyGoldDark,
        HoneyTheme.deepHoney,
        0.5,
      );
      expect(color, equals(expected));
    });

    test('equality works correctly', () {
      final theme1 = HexGridTheme.fromHoneyTheme();
      final theme2 = HexGridTheme.fromHoneyTheme();
      final theme3 = const HexGridTheme(
        honeyGold: Colors.red,
        honeyGoldDark: Colors.green,
        deepHoney: Colors.blue,
      );

      expect(theme1, equals(theme2));
      expect(theme1, isNot(equals(theme3)));
    });

    test('hashCode works correctly', () {
      final theme1 = HexGridTheme.fromHoneyTheme();
      final theme2 = HexGridTheme.fromHoneyTheme();

      expect(theme1.hashCode, equals(theme2.hashCode));
    });
  });
}
