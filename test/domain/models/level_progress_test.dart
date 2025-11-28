import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';

void main() {
  group('LevelProgress', () {
    group('construction', () {
      test('creates with default values', () {
        const progress = LevelProgress();

        expect(progress.completed, false);
        expect(progress.stars, 0);
        expect(progress.bestTime, isNull);
      });

      test('creates with custom values', () {
        final progress = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: const Duration(seconds: 5),
        );

        expect(progress.completed, true);
        expect(progress.stars, 3);
        expect(progress.bestTime, const Duration(seconds: 5));
      });

      test('empty factory creates default progress', () {
        const progress = LevelProgress.empty();

        expect(progress.completed, false);
        expect(progress.stars, 0);
        expect(progress.bestTime, isNull);
      });
    });

    group('copyWith', () {
      test('copies with updated completed', () {
        const original = LevelProgress(completed: false, stars: 2);
        final copy = original.copyWith(completed: true);

        expect(copy.completed, true);
        expect(copy.stars, 2);
      });

      test('copies with updated stars', () {
        const original = LevelProgress(completed: true, stars: 1);
        final copy = original.copyWith(stars: 3);

        expect(copy.stars, 3);
        expect(copy.completed, true);
      });

      test('copies with updated bestTime', () {
        const original = LevelProgress(
          completed: true,
          bestTime: Duration(seconds: 20),
        );
        final copy = original.copyWith(bestTime: const Duration(seconds: 10));

        expect(copy.bestTime, const Duration(seconds: 10));
      });

      test('clears bestTime when clearBestTime is true', () {
        const original = LevelProgress(
          completed: true,
          stars: 2,
          bestTime: Duration(seconds: 20),
        );
        final copy = original.copyWith(clearBestTime: true);

        expect(copy.bestTime, isNull);
        expect(copy.completed, true);
        expect(copy.stars, 2);
      });

      test('preserves all fields when no changes specified', () {
        const original = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 8),
        );
        final copy = original.copyWith();

        expect(copy.completed, true);
        expect(copy.stars, 3);
        expect(copy.bestTime, const Duration(seconds: 8));
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        const progress = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 5, milliseconds: 500),
        );
        final json = progress.toJson();

        expect(json['completed'], true);
        expect(json['stars'], 3);
        expect(json['bestTimeMs'], 5500);
      });

      test('toJson excludes null bestTime', () {
        const progress = LevelProgress(completed: true, stars: 2);
        final json = progress.toJson();

        expect(json.containsKey('bestTimeMs'), false);
        expect(json['completed'], true);
        expect(json['stars'], 2);
      });

      test('fromJson creates correct progress', () {
        final json = {'completed': true, 'stars': 3, 'bestTimeMs': 12500};
        final progress = LevelProgress.fromJson(json);

        expect(progress.completed, true);
        expect(progress.stars, 3);
        expect(progress.bestTime, const Duration(milliseconds: 12500));
      });

      test('fromJson handles missing optional fields', () {
        final json = <String, dynamic>{};
        final progress = LevelProgress.fromJson(json);

        expect(progress.completed, false);
        expect(progress.stars, 0);
        expect(progress.bestTime, isNull);
      });

      test('fromJson handles absent bestTimeMs', () {
        final json = {'completed': true, 'stars': 2};
        final progress = LevelProgress.fromJson(json);

        expect(progress.completed, true);
        expect(progress.stars, 2);
        expect(progress.bestTime, isNull);
      });

      test('JSON round-trip preserves data', () {
        const original = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 9, milliseconds: 999),
        );
        final json = original.toJson();
        final restored = LevelProgress.fromJson(json);

        expect(restored, original);
      });

      test('JSON round-trip preserves data without bestTime', () {
        const original = LevelProgress(completed: true, stars: 1);
        final json = original.toJson();
        final restored = LevelProgress.fromJson(json);

        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal progress instances are equal', () {
        const progress1 = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 5),
        );
        const progress2 = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 5),
        );

        expect(progress1, progress2);
        expect(progress1.hashCode, progress2.hashCode);
      });

      test('different completed values are not equal', () {
        const progress1 = LevelProgress(completed: true, stars: 2);
        const progress2 = LevelProgress(completed: false, stars: 2);

        expect(progress1, isNot(progress2));
      });

      test('different stars values are not equal', () {
        const progress1 = LevelProgress(completed: true, stars: 2);
        const progress2 = LevelProgress(completed: true, stars: 3);

        expect(progress1, isNot(progress2));
      });

      test('different bestTime values are not equal', () {
        const progress1 = LevelProgress(
          completed: true,
          bestTime: Duration(seconds: 5),
        );
        const progress2 = LevelProgress(
          completed: true,
          bestTime: Duration(seconds: 10),
        );

        expect(progress1, isNot(progress2));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const progress = LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 5),
        );
        final str = progress.toString();

        expect(str, contains('completed: true'));
        expect(str, contains('stars: 3'));
        expect(str, contains('bestTime'));
      });
    });
  });
}
