import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';

void main() {
  group('HoneyTheme Color Contrast', () {
    test('textPrimary on warmCream meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.textPrimary,
        HoneyTheme.warmCream,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('textSecondary on warmCream meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.textSecondary,
        HoneyTheme.warmCream,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('textPrimary on honeyGold meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.textPrimary,
        HoneyTheme.honeyGold,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('textOnPrimary on honeyGold meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.textOnPrimary,
        HoneyTheme.honeyGold,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('deepHoney on warmCream meets WCAG AA large text', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.deepHoney,
        HoneyTheme.warmCream,
      );
      // Deep honey is used for large text (titles), so 3:1 is sufficient
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('honeyGoldDark on warmCream meets WCAG AA large text', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.honeyGoldDark,
        HoneyTheme.warmCream,
      );
      // Used for large titles, so 3:1 is sufficient
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('brownAccent on white meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.brownAccent,
        Colors.white,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('starEmptyOutline on warmCream meets WCAG AA large', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.starEmptyOutline,
        HoneyTheme.warmCream,
      );
      // Stars are graphical objects, 3:1 is required
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('lockColor on warmCreamDark meets WCAG AA large', () {
      final ratio = HoneyTheme.contrastRatio(
        HoneyTheme.lockColor,
        HoneyTheme.warmCreamDark,
      );
      // Lock icon is a graphical object, 3:1 is required
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('error red on white meets WCAG AA', () {
      final ratio = HoneyTheme.contrastRatio(Colors.red.shade700, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('HoneyTheme Contrast Utilities', () {
    test('meetsContrastAA returns true for high contrast', () {
      expect(
        HoneyTheme.meetsContrastAA(HoneyTheme.textPrimary, Colors.white),
        isTrue,
      );
    });

    test('meetsContrastAA returns false for low contrast', () {
      expect(
        HoneyTheme.meetsContrastAA(HoneyTheme.honeyGoldLight, Colors.white),
        isFalse,
      );
    });

    test('contrastingTextColor returns dark on light background', () {
      final color = HoneyTheme.contrastingTextColor(HoneyTheme.warmCream);
      expect(color, equals(HoneyTheme.textPrimary));
    });

    test('contrastingTextColor returns white on dark background', () {
      final color = HoneyTheme.contrastingTextColor(HoneyTheme.brownAccentDark);
      expect(color, equals(Colors.white));
    });
  });
}
