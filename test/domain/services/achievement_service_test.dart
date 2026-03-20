import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/achievement.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/services/achievement_definitions.dart';
import 'package:hex_buzz/domain/services/achievement_service.dart';

void main() {
  late AchievementService service;

  setUp(() {
    service = const AchievementService();
  });

  group('AchievementService', () {
    group('initial state', () {
      test('no achievements unlocked with empty progress', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
          ),
        );

        expect(result.newlyUnlocked, isEmpty);
        expect(result.updatedState.unlockedCount, 0);
      });

      test('all achievements tracked in updated state', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
          ),
        );

        expect(
          result.updatedState.totalCount,
          AchievementDefinitions.all.length,
        );
      });
    });

    group('gameplay achievements', () {
      test('completing first level unlocks First Steps', () {
        final progress = const ProgressState.empty().withLevelCompleted(
          0,
          stars: 1,
          time: const Duration(seconds: 30),
        );

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        final unlocked = result.newlyUnlocked;
        expect(unlocked.any((a) => a.id == 'gameplay_first_steps'), isTrue);
      });

      test('completing 10 levels unlocks Pathfinder', () {
        var progress = const ProgressState.empty();
        for (var i = 0; i < 10; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 1,
            time: const Duration(seconds: 30),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        final unlocked = result.newlyUnlocked;
        expect(unlocked.any((a) => a.id == 'gameplay_pathfinder'), isTrue);
      });

      test('completing 50 levels unlocks Master Explorer', () {
        var progress = const ProgressState.empty();
        for (var i = 0; i < 50; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 1,
            time: const Duration(seconds: 30),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        final unlocked = result.newlyUnlocked;
        expect(
          unlocked.any((a) => a.id == 'gameplay_master_explorer'),
          isTrue,
        );
      });
    });

    group('mastery achievements', () {
      test('earning 10 stars unlocks Star Collector', () {
        var progress = const ProgressState.empty();
        // 4 levels with 3 stars = 12 stars total
        for (var i = 0; i < 4; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 3,
            time: const Duration(seconds: 5),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'mastery_star_collector'),
          isTrue,
        );
      });

      test('earning 50 stars unlocks Star Hoarder', () {
        var progress = const ProgressState.empty();
        // 17 levels with 3 stars = 51 stars
        for (var i = 0; i < 17; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 3,
            time: const Duration(seconds: 5),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'mastery_star_hoarder'),
          isTrue,
        );
      });

      test('3-starring 10 levels unlocks Perfectionist', () {
        var progress = const ProgressState.empty();
        for (var i = 0; i < 10; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 3,
            time: const Duration(seconds: 5),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'mastery_perfectionist'),
          isTrue,
        );
      });

      test('2-star levels do not count toward Perfectionist', () {
        var progress = const ProgressState.empty();
        for (var i = 0; i < 10; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 2,
            time: const Duration(seconds: 15),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'mastery_perfectionist'),
          isFalse,
        );
      });
    });

    group('daily achievements', () {
      test('completing a daily challenge unlocks Daily Player', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            dailyChallengesCompleted: 1,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'daily_player'),
          isTrue,
        );
      });

      test('3-day streak unlocks Streak Starter', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            dailyChallengeStreak: 3,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'daily_streak_starter'),
          isTrue,
        );
      });

      test('7-day streak unlocks Weekly Warrior', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            dailyChallengeStreak: 7,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'daily_weekly_warrior'),
          isTrue,
        );
      });
    });

    group('speed achievements', () {
      test('completing a level under 5s unlocks Quick Thinker', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            hasCompletedUnder5s: true,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'speed_quick_thinker'),
          isTrue,
        );
      });

      test('5 fast completions unlocks Speed Demon', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            fastCompletionsUnder10s: 5,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'speed_speed_demon'),
          isTrue,
        );
      });
    });

    group('social achievements', () {
      test('sharing a result unlocks Social Butterfly', () {
        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: const AchievementContext(
            progress: ProgressState.empty(),
            shareCount: 1,
          ),
        );

        expect(
          result.newlyUnlocked.any((a) => a.id == 'social_butterfly'),
          isTrue,
        );
      });
    });

    group('already unlocked achievements', () {
      test('already-unlocked achievements are not returned again', () {
        final progress = const ProgressState.empty().withLevelCompleted(
          0,
          stars: 1,
          time: const Duration(seconds: 30),
        );

        // First check - should unlock First Steps
        final firstResult = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        expect(
          firstResult.newlyUnlocked.any(
            (a) => a.id == 'gameplay_first_steps',
          ),
          isTrue,
        );

        // Second check with updated state - should NOT return First Steps
        final secondResult = service.checkForNewUnlocks(
          currentState: firstResult.updatedState,
          context: AchievementContext(progress: progress),
        );

        expect(
          secondResult.newlyUnlocked.any(
            (a) => a.id == 'gameplay_first_steps',
          ),
          isFalse,
        );
      });

      test('preserves unlockedAt timestamp from first unlock', () {
        final progress = const ProgressState.empty().withLevelCompleted(
          0,
          stars: 1,
          time: const Duration(seconds: 30),
        );

        final firstResult = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        final firstUnlockedAt = firstResult.updatedState
            .getProgress('gameplay_first_steps')
            ?.unlockedAt;
        expect(firstUnlockedAt, isNotNull);

        // Check again - timestamp should be preserved
        final secondResult = service.checkForNewUnlocks(
          currentState: firstResult.updatedState,
          context: AchievementContext(progress: progress),
        );

        final secondUnlockedAt = secondResult.updatedState
            .getProgress('gameplay_first_steps')
            ?.unlockedAt;
        expect(secondUnlockedAt, equals(firstUnlockedAt));
      });
    });

    group('progress tracking', () {
      test('tracks current values even when not yet unlocked', () {
        var progress = const ProgressState.empty();
        for (var i = 0; i < 5; i++) {
          progress = progress.withLevelCompleted(
            i,
            stars: 1,
            time: const Duration(seconds: 30),
          );
        }

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(progress: progress),
        );

        // Pathfinder requires 10, we have 5
        final pathfinderProgress =
            result.updatedState.getProgress('gameplay_pathfinder');
        expect(pathfinderProgress, isNotNull);
        expect(pathfinderProgress!.currentValue, 5);
        expect(pathfinderProgress.unlocked, isFalse);
      });

      test('multiple achievements can unlock simultaneously', () {
        // 1 level completed with 3 stars under 5s should unlock:
        // - First Steps (1 level completed)
        // - Quick Thinker (under 5s)
        final progress = const ProgressState.empty().withLevelCompleted(
          0,
          stars: 3,
          time: const Duration(seconds: 4),
        );

        final result = service.checkForNewUnlocks(
          currentState: const AchievementState.empty(),
          context: AchievementContext(
            progress: progress,
            hasCompletedUnder5s: true,
          ),
        );

        expect(
          result.newlyUnlocked.any(
            (a) => a.id == 'gameplay_first_steps',
          ),
          isTrue,
        );
        expect(
          result.newlyUnlocked.any(
            (a) => a.id == 'speed_quick_thinker',
          ),
          isTrue,
        );
      });
    });
  });

  group('AchievementDefinitions', () {
    test('all achievements have unique IDs', () {
      final ids = AchievementDefinitions.all.map((a) => a.id).toSet();
      expect(ids.length, AchievementDefinitions.all.length);
    });

    test('byCategory returns correct achievements', () {
      final gameplay =
          AchievementDefinitions.byCategory(AchievementCategory.gameplay);
      expect(gameplay.length, 3);
      expect(gameplay.every((a) => a.category == AchievementCategory.gameplay),
          isTrue);
    });

    test('byId returns correct achievement', () {
      final achievement =
          AchievementDefinitions.byId('gameplay_first_steps');
      expect(achievement, isNotNull);
      expect(achievement!.name, 'First Steps');
    });

    test('byId returns null for unknown ID', () {
      final achievement = AchievementDefinitions.byId('nonexistent');
      expect(achievement, isNull);
    });
  });

  group('AchievementState', () {
    test('empty state has zero counts', () {
      const state = AchievementState.empty();
      expect(state.unlockedCount, 0);
      expect(state.totalCount, 0);
      expect(state.recentlyUnlocked, isEmpty);
    });

    test('recentlyUnlocked sorted by unlock time descending', () {
      final now = DateTime.now();
      final state = AchievementState(
        progress: {
          'a': AchievementProgress(
            achievementId: 'a',
            unlocked: true,
            unlockedAt: now.subtract(const Duration(hours: 2)),
          ),
          'b': AchievementProgress(
            achievementId: 'b',
            unlocked: true,
            unlockedAt: now,
          ),
          'c': AchievementProgress(
            achievementId: 'c',
            unlocked: true,
            unlockedAt: now.subtract(const Duration(hours: 1)),
          ),
        },
      );

      final recent = state.recentlyUnlocked;
      expect(recent.length, 3);
      expect(recent[0].achievementId, 'b');
      expect(recent[1].achievementId, 'c');
      expect(recent[2].achievementId, 'a');
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime.parse('2026-01-01T12:00:00.000');
      final state = AchievementState(
        progress: {
          'test': AchievementProgress(
            achievementId: 'test',
            currentValue: 5,
            unlocked: true,
            unlockedAt: now,
          ),
        },
      );

      final json = state.toJson();
      final restored = AchievementState.fromJson(json);

      expect(restored.totalCount, 1);
      expect(restored.getProgress('test')?.currentValue, 5);
      expect(restored.getProgress('test')?.unlocked, isTrue);
      expect(restored.getProgress('test')?.unlockedAt, now);
    });
  });

  group('AchievementProgress', () {
    test('copyWith preserves unchanged fields', () {
      final progress = AchievementProgress(
        achievementId: 'test',
        currentValue: 5,
        unlocked: true,
        unlockedAt: DateTime.now(),
      );

      final updated = progress.copyWith(currentValue: 10);
      expect(updated.achievementId, 'test');
      expect(updated.currentValue, 10);
      expect(updated.unlocked, isTrue);
      expect(updated.unlockedAt, progress.unlockedAt);
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime.parse('2026-01-01T12:00:00.000');
      final progress = AchievementProgress(
        achievementId: 'test',
        currentValue: 5,
        unlocked: true,
        unlockedAt: now,
      );

      final json = progress.toJson();
      final restored = AchievementProgress.fromJson(json);

      expect(restored.achievementId, 'test');
      expect(restored.currentValue, 5);
      expect(restored.unlocked, isTrue);
      expect(restored.unlockedAt, now);
    });
  });
}
