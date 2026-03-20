import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/l10n/app_strings.dart';
import 'package:hex_buzz/core/l10n/l10n_provider.dart';
import 'package:hex_buzz/core/l10n/strings_en.dart';
import 'package:hex_buzz/core/l10n/strings_ja.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hex_buzz/presentation/providers/notification_provider.dart';

void main() {
  group('AppStrings completeness', () {
    /// All string fields extracted via reflection-like manual listing.
    /// This ensures every key has a non-empty value in both locales.
    final fields = _extractStringValues;

    test('all English strings are non-empty', () {
      for (final entry in fields(stringsEn).entries) {
        expect(
          entry.value.isNotEmpty,
          isTrue,
          reason: 'English string "${entry.key}" must not be empty',
        );
      }
    });

    test('all Japanese strings are non-empty', () {
      for (final entry in fields(stringsJa).entries) {
        expect(
          entry.value.isNotEmpty,
          isTrue,
          reason: 'Japanese string "${entry.key}" must not be empty',
        );
      }
    });

    test('English and Japanese have the same number of fields', () {
      final enFields = fields(stringsEn);
      final jaFields = fields(stringsJa);
      expect(enFields.length, equals(jaFields.length));
    });

    test('stringsFor returns correct locale strings', () {
      expect(stringsFor(AppLocale.en), same(stringsEn));
      expect(stringsFor(AppLocale.ja), same(stringsJa));
    });
  });

  group('AppLocale', () {
    test('has displayName for each locale', () {
      expect(AppLocale.en.displayName, 'English');
      expect(AppLocale.ja.displayName, '日本語');
    });

    test('values contains en and ja', () {
      expect(AppLocale.values, containsAll([AppLocale.en, AppLocale.ja]));
      expect(AppLocale.values.length, 2);
    });
  });

  group('L10nNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to system locale detection when no preference saved', () {
      final locale = container.read(l10nProvider);
      // System locale in test environment defaults to English
      expect(locale, isA<AppLocale>());
    });

    test('persists locale to SharedPreferences', () async {
      final notifier = container.read(l10nProvider.notifier);

      await notifier.setLocale(AppLocale.ja);

      expect(container.read(l10nProvider), AppLocale.ja);

      // Verify persistence
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('app_locale'), 'ja');
    });

    test('reads saved locale from SharedPreferences', () async {
      // Pre-set a saved locale
      SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
      final prefs = await SharedPreferences.getInstance();

      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container2.dispose);

      expect(container2.read(l10nProvider), AppLocale.ja);
    });

    test('falls back to system detection for invalid saved locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'invalid'});
      final prefs = await SharedPreferences.getInstance();

      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container2.dispose);

      // Should fall back to system detection (en in test env)
      expect(container2.read(l10nProvider), isA<AppLocale>());
    });

    test('switching locale updates state', () async {
      final notifier = container.read(l10nProvider.notifier);

      expect(container.read(l10nProvider), isNot(AppLocale.ja));

      await notifier.setLocale(AppLocale.ja);
      expect(container.read(l10nProvider), AppLocale.ja);

      await notifier.setLocale(AppLocale.en);
      expect(container.read(l10nProvider), AppLocale.en);
    });
  });

  group('detectSystemLocale', () {
    test('returns a valid AppLocale', () {
      final locale = detectSystemLocale();
      expect(AppLocale.values, contains(locale));
    });
  });

  group('String content validation', () {
    test('Japanese strings differ from English where expected', () {
      // These should definitely be different in Japanese
      expect(stringsJa.tapToStart, isNot(stringsEn.tapToStart));
      expect(stringsJa.onePathChallenge, isNot(stringsEn.onePathChallenge));
      expect(stringsJa.playAsGuest, isNot(stringsEn.playAsGuest));
      expect(stringsJa.levelComplete, isNot(stringsEn.levelComplete));
      expect(stringsJa.settings, isNot(stringsEn.settings));
      expect(stringsJa.cancel, isNot(stringsEn.cancel));
    });

    test('appTitle is same in both locales', () {
      // Brand name should not be translated
      expect(stringsEn.appTitle, 'HexBuzz');
      expect(stringsJa.appTitle, 'HexBuzz');
    });
  });
}

/// Extracts all string field values from an [AppStrings] instance as a map.
///
/// This serves as a manual "reflection" to verify completeness since Dart
/// does not support runtime reflection in Flutter.
Map<String, String> Function(AppStrings) get _extractStringValues {
  return (AppStrings s) => {
        'appTitle': s.appTitle,
        'tapToStart': s.tapToStart,
        'onePathChallenge': s.onePathChallenge,
        'playAsGuest': s.playAsGuest,
        'signInWithGoogle': s.signInWithGoogle,
        'loginTitle': s.loginTitle,
        'dailyChallenge': s.dailyChallenge,
        'levelPacks': s.levelPacks,
        'timedChallenge': s.timedChallenge,
        'achievements': s.achievements,
        'friends': s.friends,
        'create': s.create,
        'store': s.store,
        'settings': s.settings,
        'levelComplete': s.levelComplete,
        'nextLevel': s.nextLevel,
        'replay': s.replay,
        'levels': s.levels,
        'progress': s.progress,
        'retry': s.retry,
        'hint': s.hint,
        'noHintsRemaining': s.noHintsRemaining,
        'viewLeaderboard': s.viewLeaderboard,
        'time': s.time,
        'timesUp': s.timesUp,
        'puzzlesSolved': s.puzzlesSolved,
        'bestStreak': s.bestStreak,
        'averageTime': s.averageTime,
        'playAgain': s.playAgain,
        'backToMenu': s.backToMenu,
        'sprint': s.sprint,
        'marathon': s.marathon,
        'blitz': s.blitz,
        'soundEffects': s.soundEffects,
        'visualEffects': s.visualEffects,
        'notifications': s.notifications,
        'theme': s.theme,
        'aboutApp': s.aboutApp,
        'whatsNew': s.whatsNew,
        'rateApp': s.rateApp,
        'privacyPolicy': s.privacyPolicy,
        'termsOfService': s.termsOfService,
        'language': s.language,
        'ok': s.ok,
        'cancel': s.cancel,
        'save': s.save,
        'delete': s.delete,
        'share': s.share,
        'back': s.back,
        'loading': s.loading,
        'error': s.error,
      };
}
