import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/progress_state.dart';

void main() {
  group('ProgressState', () {
    group('construction', () {
      test('creates with default empty levels', () {
        const state = ProgressState();
        expect(state.levels, isEmpty);
      });

      test('creates with provided levels', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        expect(state.levels.length, 2);
        expect(state.levels[0]?.stars, 3);
      });

      test('empty factory creates default state', () {
        const state = ProgressState.empty();
        expect(state.levels, isEmpty);
      });
    });

    group('getProgress', () {
      test('returns progress for existing level', () {
        const levels = {0: LevelProgress(completed: true, stars: 3)};
        const state = ProgressState(levels: levels);
        final progress = state.getProgress(0);
        expect(progress.completed, true);
        expect(progress.stars, 3);
      });

      test('returns empty progress for non-existing level', () {
        const state = ProgressState();
        final progress = state.getProgress(5);
        expect(progress.completed, false);
        expect(progress.stars, 0);
        expect(progress.bestTime, isNull);
      });
    });

    group('isUnlocked', () {
      test('level 0 is always unlocked', () {
        const state = ProgressState.empty();
        expect(state.isUnlocked(0), true);
      });

      test('negative level indices are unlocked', () {
        const state = ProgressState.empty();
        expect(state.isUnlocked(-1), true);
        expect(state.isUnlocked(-5), true);
      });

      test('level 1 is locked when level 0 is incomplete', () {
        const state = ProgressState.empty();
        expect(state.isUnlocked(1), false);
      });

      test('level 1 is unlocked when level 0 is completed', () {
        const levels = {0: LevelProgress(completed: true, stars: 1)};
        const state = ProgressState(levels: levels);
        expect(state.isUnlocked(1), true);
      });

      test('level 2 is locked when level 1 is incomplete', () {
        const levels = {0: LevelProgress(completed: true, stars: 3)};
        const state = ProgressState(levels: levels);
        expect(state.isUnlocked(2), false);
      });

      test('level 2 is unlocked when level 1 is completed', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        expect(state.isUnlocked(2), true);
      });

      test('high level is locked when previous is incomplete', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
          2: LevelProgress(completed: true, stars: 1),
          3: LevelProgress(completed: false, stars: 0),
        };
        const state = ProgressState(levels: levels);
        expect(state.isUnlocked(4), false);
      });
    });

    group('computed properties', () {
      test('totalStars returns sum of all stars', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
          2: LevelProgress(completed: true, stars: 1),
        };
        const state = ProgressState(levels: levels);
        expect(state.totalStars, 6);
      });

      test('totalStars returns 0 for empty state', () {
        const state = ProgressState.empty();
        expect(state.totalStars, 0);
      });

      test('completedLevels returns count of completed levels', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
          2: LevelProgress(completed: false, stars: 0),
        };
        const state = ProgressState(levels: levels);
        expect(state.completedLevels, 2);
      });

      test('completedLevels returns 0 for empty state', () {
        const state = ProgressState.empty();
        expect(state.completedLevels, 0);
      });

      test('highestUnlockedLevel returns 0 for empty state', () {
        const state = ProgressState.empty();
        expect(state.highestUnlockedLevel, 0);
      });

      test('highestUnlockedLevel returns next level after last completed', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        expect(state.highestUnlockedLevel, 2);
      });

      test('highestUnlockedLevel handles non-sequential completion', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          2: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        expect(state.highestUnlockedLevel, 3);
      });
    });

    group('withLevelProgress', () {
      test('adds progress for new level', () {
        const state = ProgressState.empty();
        const progress = LevelProgress(completed: true, stars: 3);
        final newState = state.withLevelProgress(0, progress);
        expect(newState.levels[0], progress);
        expect(state.levels, isEmpty);
      });

      test('updates progress for existing level', () {
        const levels = {0: LevelProgress(completed: true, stars: 1)};
        const state = ProgressState(levels: levels);
        const newProgress = LevelProgress(completed: true, stars: 3);
        final newState = state.withLevelProgress(0, newProgress);
        expect(newState.levels[0], newProgress);
        expect(state.levels[0]?.stars, 1);
      });
    });

    group('withLevelCompleted', () {
      test('completes new level with given stars and time', () {
        const state = ProgressState.empty();
        final newState = state.withLevelCompleted(
          0,
          stars: 3,
          time: const Duration(seconds: 8),
        );
        expect(newState.getProgress(0).completed, true);
        expect(newState.getProgress(0).stars, 3);
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 8));
      });

      test('keeps better star count when replaying', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 8),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 2,
          time: const Duration(seconds: 15),
        );
        expect(newState.getProgress(0).stars, 3);
      });

      test('updates star count when improving', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 1,
            bestTime: Duration(seconds: 45),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 3,
          time: const Duration(seconds: 8),
        );
        expect(newState.getProgress(0).stars, 3);
      });

      test('updates best time when faster with same or better stars', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 25),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 2,
          time: const Duration(seconds: 20),
        );
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 20));
      });

      test('keeps best time when slower with same stars', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 20),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 2,
          time: const Duration(seconds: 25),
        );
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 20));
      });

      test('keeps best time when achieving worse stars', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 8),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 1,
          time: const Duration(seconds: 50),
        );
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 8));
        expect(newState.getProgress(0).stars, 3);
      });

      test('sets best time when none exists', () {
        const state = ProgressState.empty();
        final newState = state.withLevelCompleted(
          0,
          stars: 2,
          time: const Duration(seconds: 15),
        );
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 15));
      });

      test('updates best time when improving stars', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 1,
            bestTime: Duration(seconds: 45),
          ),
        };
        const state = ProgressState(levels: levels);
        final newState = state.withLevelCompleted(
          0,
          stars: 3,
          time: const Duration(seconds: 8),
        );
        expect(newState.getProgress(0).bestTime, const Duration(seconds: 8));
      });
    });

    group('copyWith', () {
      test('copies with new levels', () {
        const state = ProgressState.empty();
        const newLevels = {0: LevelProgress(completed: true, stars: 3)};
        final copy = state.copyWith(levels: newLevels);
        expect(copy.levels, newLevels);
        expect(state.levels, isEmpty);
      });

      test('preserves levels when no changes specified', () {
        const levels = {0: LevelProgress(completed: true, stars: 3)};
        const state = ProgressState(levels: levels);
        final copy = state.copyWith();
        expect(copy.levels, levels);
      });
    });

    group('JSON serialization', () {
      test('toJson serializes all levels', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        final json = state.toJson();
        expect(json['levels'], isA<Map>());
        expect((json['levels'] as Map).length, 2);
        expect((json['levels'] as Map)['0']['stars'], 3);
        expect((json['levels'] as Map)['1']['stars'], 2);
      });

      test('toJson handles empty state', () {
        const state = ProgressState.empty();
        final json = state.toJson();
        expect(json['levels'], isA<Map>());
        expect((json['levels'] as Map).length, 0);
      });

      test('fromJson creates correct state', () {
        final json = {
          'levels': {
            '0': {'completed': true, 'stars': 3, 'bestTimeMs': 8000},
            '1': {'completed': true, 'stars': 2, 'bestTimeMs': 15000},
          },
        };
        final state = ProgressState.fromJson(json);
        expect(state.levels.length, 2);
        expect(state.getProgress(0).stars, 3);
        expect(state.getProgress(0).bestTime, const Duration(seconds: 8));
        expect(state.getProgress(1).stars, 2);
      });

      test('fromJson handles missing levels key', () {
        final json = <String, dynamic>{};
        final state = ProgressState.fromJson(json);
        expect(state.levels, isEmpty);
      });

      test('fromJson handles empty levels', () {
        final json = {'levels': <String, dynamic>{}};
        final state = ProgressState.fromJson(json);
        expect(state.levels, isEmpty);
      });

      test('JSON round-trip preserves data', () {
        const levels = {
          0: LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 8),
          ),
          1: LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 15),
          ),
          2: LevelProgress(completed: false, stars: 0),
        };
        const original = ProgressState(levels: levels);
        final json = original.toJson();
        final restored = ProgressState.fromJson(json);
        expect(restored, original);
      });

      test('JSON round-trip preserves empty state', () {
        const original = ProgressState.empty();
        final json = original.toJson();
        final restored = ProgressState.fromJson(json);
        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const levels = {0: LevelProgress(completed: true, stars: 3)};
        const state1 = ProgressState(levels: levels);
        const state2 = ProgressState(levels: levels);
        expect(state1, state2);
      });

      test('different level counts are not equal', () {
        const state1 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        const state2 = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );
        expect(state1, isNot(state2));
      });

      test('different level progress are not equal', () {
        const state1 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        const state2 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 2)},
        );
        expect(state1, isNot(state2));
      });

      test('empty states are equal', () {
        const state1 = ProgressState.empty();
        const state2 = ProgressState();
        expect(state1, state2);
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const levels = {
          0: LevelProgress(completed: true, stars: 3),
          1: LevelProgress(completed: true, stars: 2),
        };
        const state = ProgressState(levels: levels);
        final str = state.toString();
        expect(str, contains('levels: 2'));
        expect(str, contains('totalStars: 5'));
        expect(str, contains('completed: 2'));
      });
    });
  });
}
