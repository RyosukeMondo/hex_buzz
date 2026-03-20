import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_provider.dart';

/// User's preferred theme mode.
///
/// Maps directly to [ThemeMode] for MaterialApp:
/// - [system]: follows platform brightness
/// - [light]: forces light theme
/// - [dark]: forces dark theme
enum ThemePreference { system, light, dark }

/// Converts a [ThemePreference] to the corresponding [ThemeMode].
ThemeMode themeModeFromPreference(ThemePreference preference) {
  return switch (preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}

/// SharedPreferences key for persisting the theme preference.
const String _themePreferenceKey = 'theme_preference';

/// Notifier that manages the user's theme preference.
///
/// Reads the saved preference from [SharedPreferences] on build,
/// defaults to [ThemePreference.system] if no value is stored.
/// Persists changes immediately when [setTheme] is called.
class ThemeNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_themePreferenceKey);
    if (stored == null) return ThemePreference.system;

    return ThemePreference.values.asNameMap()[stored] ??
        ThemePreference.system;
  }

  /// Updates the theme preference and persists it to SharedPreferences.
  Future<void> setTheme(ThemePreference preference) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themePreferenceKey, preference.name);
    state = preference;
  }
}

/// Provider for the current theme preference.
///
/// Watch this in the MaterialApp to reactively switch themes.
final themeProvider = NotifierProvider<ThemeNotifier, ThemePreference>(
  ThemeNotifier.new,
);
