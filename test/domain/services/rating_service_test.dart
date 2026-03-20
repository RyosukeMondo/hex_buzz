import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/services/rating_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  /// Sets up SharedPreferences with a first launch date [daysAgo] days in
  /// the past so that the minimum-days check passes by default.
  Future<SharedPreferences> createPrefs({int daysAgo = 10}) async {
    final firstLaunchDate =
        DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      'rating_first_launch_date': firstLaunchDate,
    });
    return SharedPreferences.getInstance();
  }

  group('RatingService', () {
    group('shouldPromptForRating', () {
      test('does not prompt before minimum levels completed', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        expect(
          service.shouldPromptForRating(
            levelsCompleted: RatingConfig.minLevelsBeforePrompt - 1,
            totalStars: 10,
          ),
          isFalse,
        );
      });

      test('does not prompt before minimum days elapsed', () async {
        prefs = await createPrefs(daysAgo: 0);
        final service = RatingService(prefs);

        expect(
          service.shouldPromptForRating(
            levelsCompleted: RatingConfig.minLevelsBeforePrompt,
            totalStars: 10,
          ),
          isFalse,
        );
      });

      test('prompts when all conditions are met', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        expect(
          service.shouldPromptForRating(
            levelsCompleted: RatingConfig.minLevelsBeforePrompt,
            totalStars: 15,
          ),
          isTrue,
        );
      });

      test('does not prompt after user has rated', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markRated();

        expect(
          service.shouldPromptForRating(
            levelsCompleted: 20,
            totalStars: 50,
          ),
          isFalse,
        );
      });

      test('does not prompt after user has declined', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markDeclined();

        expect(
          service.shouldPromptForRating(
            levelsCompleted: 20,
            totalStars: 50,
          ),
          isFalse,
        );
      });

      test('does not prompt after max prompts reached', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        // Simulate reaching max prompts via "later" selections
        for (var i = 0; i < RatingConfig.maxPrompts; i++) {
          await service.markLater();
        }

        expect(
          service.shouldPromptForRating(
            levelsCompleted: 20,
            totalStars: 50,
          ),
          isFalse,
        );
      });

      test('cooldown works after choosing later', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        // First prompt should work
        expect(
          service.shouldPromptForRating(
            levelsCompleted: RatingConfig.minLevelsBeforePrompt,
            totalStars: 15,
          ),
          isTrue,
        );

        // After choosing "later", cooldown applies
        await service.markLater();

        expect(
          service.shouldPromptForRating(
            levelsCompleted: 20,
            totalStars: 50,
          ),
          isFalse,
        );
      });

      test('cooldown allows prompt after enough days pass', () async {
        // Set up prefs with a first launch date far in the past
        final oldDate = DateTime.now()
            .subtract(const Duration(days: 100))
            .toIso8601String();
        final lastPromptDate = DateTime.now()
            .subtract(Duration(days: RatingConfig.promptCooldownDays))
            .toIso8601String();
        SharedPreferences.setMockInitialValues({
          'rating_first_launch_date': oldDate,
          'rating_last_prompt_date': lastPromptDate,
          'rating_prompt_count': 1,
        });
        prefs = await SharedPreferences.getInstance();
        final service = RatingService(prefs);

        expect(
          service.shouldPromptForRating(
            levelsCompleted: 20,
            totalStars: 50,
          ),
          isTrue,
        );
      });
    });

    group('markRated', () {
      test('persists rated flag', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markRated();

        expect(prefs.getBool('rating_has_rated'), isTrue);
      });
    });

    group('markDeclined', () {
      test('persists declined flag and increments prompt count', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markDeclined();

        expect(prefs.getBool('rating_declined'), isTrue);
        expect(prefs.getInt('rating_prompt_count'), 1);
      });
    });

    group('markLater', () {
      test('increments prompt count', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markLater();
        expect(prefs.getInt('rating_prompt_count'), 1);

        await service.markLater();
        expect(prefs.getInt('rating_prompt_count'), 2);
      });

      test('records last prompt date', () async {
        prefs = await createPrefs();
        final service = RatingService(prefs);

        await service.markLater();

        final lastPromptStr = prefs.getString('rating_last_prompt_date');
        expect(lastPromptStr, isNotNull);

        final lastPrompt = DateTime.parse(lastPromptStr!);
        final now = DateTime.now();
        // Should be within the last second
        expect(now.difference(lastPrompt).inSeconds, lessThan(2));
      });
    });

    group('first launch date', () {
      test('sets first launch date on construction if not set', () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        RatingService(prefs);

        final firstLaunchStr = prefs.getString('rating_first_launch_date');
        expect(firstLaunchStr, isNotNull);
      });

      test('does not overwrite existing first launch date', () async {
        final existingDate = '2025-01-01T00:00:00.000';
        SharedPreferences.setMockInitialValues({
          'rating_first_launch_date': existingDate,
        });
        prefs = await SharedPreferences.getInstance();
        RatingService(prefs);

        expect(
          prefs.getString('rating_first_launch_date'),
          existingDate,
        );
      });
    });
  });
}
