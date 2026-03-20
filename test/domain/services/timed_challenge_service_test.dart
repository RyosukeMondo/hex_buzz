import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/timed_challenge_state.dart';
import 'package:hex_buzz/domain/services/timed_challenge_service.dart';

void main() {
  late TimedChallengeService service;

  setUp(() {
    service = const TimedChallengeService();
  });

  group('TimedChallengeConfig', () {
    test('blitz has correct values', () {
      expect(TimedChallengeConfig.blitz.id, 'blitz');
      expect(TimedChallengeConfig.blitz.name, 'Blitz');
      expect(
        TimedChallengeConfig.blitz.timeLimit,
        const Duration(seconds: 60),
      );
      expect(TimedChallengeConfig.blitz.startingEdgeSize, 2);
      expect(
        TimedChallengeConfig.blitz.bonusTimePerSolve,
        const Duration(seconds: 10),
      );
    });

    test('sprint has correct values', () {
      expect(TimedChallengeConfig.sprint.id, 'sprint');
      expect(TimedChallengeConfig.sprint.name, 'Sprint');
      expect(
        TimedChallengeConfig.sprint.timeLimit,
        const Duration(minutes: 2),
      );
      expect(TimedChallengeConfig.sprint.startingEdgeSize, 2);
      expect(
        TimedChallengeConfig.sprint.bonusTimePerSolve,
        const Duration(seconds: 15),
      );
    });

    test('marathon has correct values', () {
      expect(TimedChallengeConfig.marathon.id, 'marathon');
      expect(TimedChallengeConfig.marathon.name, 'Marathon');
      expect(
        TimedChallengeConfig.marathon.timeLimit,
        const Duration(minutes: 5),
      );
      expect(TimedChallengeConfig.marathon.startingEdgeSize, 2);
      expect(
        TimedChallengeConfig.marathon.bonusTimePerSolve,
        const Duration(seconds: 20),
      );
    });

    test('presets contains all three configs', () {
      expect(TimedChallengeConfig.presets.length, 3);
      expect(
        TimedChallengeConfig.presets.map((c) => c.id),
        ['blitz', 'sprint', 'marathon'],
      );
    });
  });

  group('calculateScore', () {
    test('returns 0 for no puzzles solved', () {
      const state = TimedChallengeState(puzzlesSolved: 0);
      expect(service.calculateScore(state), 0);
    });

    test('awards base points of 100 per puzzle', () {
      const state = TimedChallengeState(
        puzzlesSolved: 5,
        solveTimes: [5000, 5000, 5000, 5000, 5000],
        bestStreak: 1,
      );
      final score = service.calculateScore(state);
      // Base: 500, streak bonus: 0, speed + time bonuses vary
      expect(score, greaterThanOrEqualTo(500));
    });

    test('includes streak bonus for best streak > 1', () {
      const stateNoStreak = TimedChallengeState(
        puzzlesSolved: 3,
        solveTimes: [5000, 5000, 5000],
        bestStreak: 1,
      );
      const stateWithStreak = TimedChallengeState(
        puzzlesSolved: 3,
        solveTimes: [5000, 5000, 5000],
        bestStreak: 5,
      );

      final scoreNoStreak = service.calculateScore(stateNoStreak);
      final scoreWithStreak = service.calculateScore(stateWithStreak);

      // Streak bonus: 50 * (5-1) = 200
      expect(scoreWithStreak - scoreNoStreak, 200);
    });

    test('streak bonus is 0 when best streak is 1', () {
      const state = TimedChallengeState(
        puzzlesSolved: 1,
        solveTimes: [10000],
        bestStreak: 1,
      );
      // Base: 100, streak: 0
      final score = service.calculateScore(state);
      expect(score, greaterThanOrEqualTo(100));
    });

    test('includes time bonus from remaining time', () {
      const stateNoTime = TimedChallengeState(
        puzzlesSolved: 1,
        solveTimes: [5000],
        bestStreak: 1,
        timeRemainingMs: 0,
      );
      const stateWithTime = TimedChallengeState(
        puzzlesSolved: 1,
        solveTimes: [5000],
        bestStreak: 1,
        timeRemainingMs: 30000,
      );

      final scoreNoTime = service.calculateScore(stateNoTime);
      final scoreWithTime = service.calculateScore(stateWithTime);

      // Time bonus: 30000 / 1000 = 30
      expect(scoreWithTime - scoreNoTime, 30);
    });

    test('speed bonus increases with faster average solve time', () {
      const fastState = TimedChallengeState(
        puzzlesSolved: 3,
        solveTimes: [1000, 1000, 1000], // 1s avg
        bestStreak: 1,
      );
      const slowState = TimedChallengeState(
        puzzlesSolved: 3,
        solveTimes: [30000, 30000, 30000], // 30s avg
        bestStreak: 1,
      );

      final fastScore = service.calculateScore(fastState);
      final slowScore = service.calculateScore(slowState);

      expect(fastScore, greaterThan(slowScore));
    });

    test('score is deterministic for same state', () {
      const state = TimedChallengeState(
        puzzlesSolved: 5,
        solveTimes: [3000, 4000, 5000, 6000, 7000],
        bestStreak: 3,
        timeRemainingMs: 45000,
      );

      final score1 = service.calculateScore(state);
      final score2 = service.calculateScore(state);
      expect(score1, score2);
    });
  });

  group('getNextEdgeSize', () {
    test('returns starting edge size for 0 puzzles solved', () {
      expect(service.getNextEdgeSize(0), 2);
    });

    test('returns starting edge size for 1 puzzle solved', () {
      expect(service.getNextEdgeSize(1), 2);
    });

    test('returns starting edge size for 2 puzzles solved', () {
      expect(service.getNextEdgeSize(2), 2);
    });

    test('increases edge size after 3 puzzles', () {
      expect(service.getNextEdgeSize(3), 3);
    });

    test('increases edge size after 6 puzzles', () {
      expect(service.getNextEdgeSize(6), 4);
    });

    test('increases edge size after 9 puzzles', () {
      expect(service.getNextEdgeSize(9), 5);
    });

    test('caps at edge size 5', () {
      expect(service.getNextEdgeSize(12), 5);
      expect(service.getNextEdgeSize(15), 5);
      expect(service.getNextEdgeSize(100), 5);
    });

    test('respects custom starting edge size', () {
      expect(service.getNextEdgeSize(0, startingEdgeSize: 3), 3);
      expect(service.getNextEdgeSize(3, startingEdgeSize: 3), 4);
      expect(service.getNextEdgeSize(6, startingEdgeSize: 3), 5);
      // Still caps at 5
      expect(service.getNextEdgeSize(9, startingEdgeSize: 3), 5);
    });

    test('progression is monotonically non-decreasing', () {
      var prevSize = service.getNextEdgeSize(0);
      for (var i = 1; i <= 20; i++) {
        final currentSize = service.getNextEdgeSize(i);
        expect(currentSize, greaterThanOrEqualTo(prevSize));
        prevSize = currentSize;
      }
    });
  });

  group('getBonusTime', () {
    test('returns full bonus for first puzzle', () {
      final bonus = service.getBonusTime(TimedChallengeConfig.sprint, 0);
      expect(bonus.inSeconds, 15);
    });

    test('returns full bonus for blitz first puzzle', () {
      final bonus = service.getBonusTime(TimedChallengeConfig.blitz, 0);
      expect(bonus.inSeconds, 10);
    });

    test('returns full bonus for marathon first puzzle', () {
      final bonus = service.getBonusTime(TimedChallengeConfig.marathon, 0);
      expect(bonus.inSeconds, 20);
    });

    test('decreases bonus as more puzzles are solved', () {
      final bonus0 = service.getBonusTime(TimedChallengeConfig.sprint, 0);
      final bonus5 = service.getBonusTime(TimedChallengeConfig.sprint, 5);
      final bonus10 = service.getBonusTime(TimedChallengeConfig.sprint, 10);

      expect(bonus5.inMilliseconds, lessThan(bonus0.inMilliseconds));
      expect(bonus10.inMilliseconds, lessThanOrEqualTo(bonus5.inMilliseconds));
    });

    test('bonus never drops below 50% of base', () {
      // With 100 puzzles solved, multiplier should be clamped to 0.5
      final bonus = service.getBonusTime(TimedChallengeConfig.sprint, 100);
      final baseMs = TimedChallengeConfig.sprint.bonusTimePerSolve.inMilliseconds;
      final minimumMs = (baseMs * 0.5).round();
      expect(bonus.inMilliseconds, minimumMs);
    });

    test('bonus at exactly 10 puzzles applies 50% reduction', () {
      // multiplier = max(0.5, 1.0 - 10*0.05) = max(0.5, 0.5) = 0.5
      final bonus = service.getBonusTime(TimedChallengeConfig.sprint, 10);
      final baseMs = TimedChallengeConfig.sprint.bonusTimePerSolve.inMilliseconds;
      expect(bonus.inMilliseconds, (baseMs * 0.5).round());
    });

    test('bonus is always positive', () {
      for (var i = 0; i <= 50; i++) {
        final bonus = service.getBonusTime(TimedChallengeConfig.blitz, i);
        expect(bonus.inMilliseconds, greaterThan(0));
      }
    });
  });
}
