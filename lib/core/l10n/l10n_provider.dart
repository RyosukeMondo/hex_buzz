import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/notification_provider.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_ja.dart';

/// Supported application locales.
enum AppLocale {
  en('English'),
  ja('日本語');

  /// Human-readable display name for locale selection UI.
  final String displayName;

  const AppLocale(this.displayName);
}

/// SharedPreferences key for persisted locale selection.
const _localePrefsKey = 'app_locale';

/// Notifier that manages the active locale with system detection
/// and user override persistence.
class L10nNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_localePrefsKey);
    if (saved != null) {
      return AppLocale.values.where((l) => l.name == saved).firstOrNull ??
          _detectSystemLocale();
    }
    return _detectSystemLocale();
  }

  /// Persists the selected locale and updates state.
  Future<void> setLocale(AppLocale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localePrefsKey, locale.name);
    state = locale;
  }

  /// Detects locale from the platform's primary locale.
  static AppLocale _detectSystemLocale() {
    final platformLocale = ui.PlatformDispatcher.instance.locale;
    if (platformLocale.languageCode == 'ja') {
      return AppLocale.ja;
    }
    return AppLocale.en;
  }
}

/// Provider for the active locale.
final l10nProvider = NotifierProvider<L10nNotifier, AppLocale>(
  L10nNotifier.new,
);

/// Returns the [AppStrings] for the given [locale].
AppStrings stringsFor(AppLocale locale) {
  return switch (locale) {
    AppLocale.ja => stringsJa,
    AppLocale.en => stringsEn,
  };
}

/// Convenience extension to access localized strings from a [WidgetRef].
extension L10nExtension on WidgetRef {
  /// Returns the [AppStrings] for the currently active locale.
  AppStrings get strings {
    final locale = watch(l10nProvider);
    return stringsFor(locale);
  }
}

/// Convenience extension to access localized strings from a [Ref].
extension L10nRefExtension on Ref {
  /// Returns the [AppStrings] for the currently active locale.
  AppStrings get strings {
    final locale = watch(l10nProvider);
    return stringsFor(locale);
  }
}

/// Test helper: detects system locale without Riverpod dependency.
///
/// Exposed for unit testing of the detection logic.
AppLocale detectSystemLocale() => L10nNotifier._detectSystemLocale();
