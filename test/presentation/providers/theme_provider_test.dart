import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/providers/notification_provider.dart';
import 'package:hex_buzz/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer({
    Map<String, Object>? initialPrefs,
  }) {
    if (initialPrefs != null) {
      // Re-create prefs with initial values for reading tests
      for (final entry in initialPrefs.entries) {
        if (entry.value is String) {
          prefs.setString(entry.key, entry.value as String);
        }
      }
    }

    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  }

  group('ThemeNotifier', () {
    test('defaults to ThemePreference.system when no saved value', () {
      final container = createContainer();

      final preference = container.read(themeProvider);

      expect(preference, ThemePreference.system);

      container.dispose();
    });

    test('reads saved "dark" value on build', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'dark'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();

      final preference = container.read(themeProvider);

      expect(preference, ThemePreference.dark);

      container.dispose();
    });

    test('reads saved "light" value on build', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'light'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();

      final preference = container.read(themeProvider);

      expect(preference, ThemePreference.light);

      container.dispose();
    });

    test('reads saved "system" value on build', () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'system'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();

      final preference = container.read(themeProvider);

      expect(preference, ThemePreference.system);

      container.dispose();
    });

    test('falls back to system for invalid stored value', () async {
      SharedPreferences.setMockInitialValues(
        {'theme_preference': 'invalid_value'},
      );
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();

      final preference = container.read(themeProvider);

      expect(preference, ThemePreference.system);

      container.dispose();
    });

    test('setTheme(dark) persists to SharedPreferences', () async {
      final container = createContainer();

      await container.read(themeProvider.notifier).setTheme(
        ThemePreference.dark,
      );

      expect(container.read(themeProvider), ThemePreference.dark);
      expect(prefs.getString('theme_preference'), 'dark');

      container.dispose();
    });

    test('setTheme(light) persists to SharedPreferences', () async {
      final container = createContainer();

      await container.read(themeProvider.notifier).setTheme(
        ThemePreference.light,
      );

      expect(container.read(themeProvider), ThemePreference.light);
      expect(prefs.getString('theme_preference'), 'light');

      container.dispose();
    });

    test('setTheme(system) persists to SharedPreferences', () async {
      final container = createContainer();

      // First set to dark, then back to system
      await container.read(themeProvider.notifier).setTheme(
        ThemePreference.dark,
      );
      await container.read(themeProvider.notifier).setTheme(
        ThemePreference.system,
      );

      expect(container.read(themeProvider), ThemePreference.system);
      expect(prefs.getString('theme_preference'), 'system');

      container.dispose();
    });
  });

  group('themeModeFromPreference', () {
    test('system maps to ThemeMode.system', () {
      expect(
        themeModeFromPreference(ThemePreference.system),
        ThemeMode.system,
      );
    });

    test('light maps to ThemeMode.light', () {
      expect(
        themeModeFromPreference(ThemePreference.light),
        ThemeMode.light,
      );
    });

    test('dark maps to ThemeMode.dark', () {
      expect(
        themeModeFromPreference(ThemePreference.dark),
        ThemeMode.dark,
      );
    });
  });
}
