import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/timed_challenge_state.dart';

void main() {
  group('TimedChallengeState', () {
    group('constructor', () {
      test('default values', () {
        const state = TimedChallengeState();
        expect(state.puzzlesSolved, 0);
        expect(state.totalTimeMs, 0);
        expect(state.timeRemainingMs, 0);
        expect(state.currentStreak, 0);
        expect(state.isActive, false);
        expect(state.isGameOver, false);
        expect(state.solveTimes, isEmpty);
        expect(state.bestStreak, 0);
        expect(state.score, 0);
      });

      test('initial() factory', () {
        const state = TimedChallengeState.initial();
        expect(state.puzzlesSolved, 0);
        expect(state.isActive, false);
        expect(state.isGameOver, false);
      });
    });

    group('averageSolveTime', () {
      test('returns 0 for no solve times', () {
        const state = TimedChallengeState();
        expect(state.averageSolveTime, 0);
      });

      test('returns correct average for single solve', () {
        const state = TimedChallengeState(solveTimes: [5000]);
        expect(state.averageSolveTime, 5000);
      });

      test('returns correct average for multiple solves', () {
        const state = TimedChallengeState(
          solveTimes: [3000, 5000, 7000],
        );
        expect(state.averageSolveTime, 5000);
      });

      test('returns correct average with uneven division', () {
        const state = TimedChallengeState(
          solveTimes: [1000, 2000],
        );
        expect(state.averageSolveTime, 1500);
      });
    });

    group('copyWith', () {
      test('creates copy with updated field', () {
        const original = TimedChallengeState(puzzlesSolved: 5);
        final copy = original.copyWith(puzzlesSolved: 10);
        expect(copy.puzzlesSolved, 10);
        expect(original.puzzlesSolved, 5);
      });

      test('preserves unchanged fields', () {
        const original = TimedChallengeState(
          puzzlesSolved: 5,
          score: 500,
          isActive: true,
        );
        final copy = original.copyWith(puzzlesSolved: 10);
        expect(copy.score, 500);
        expect(copy.isActive, true);
      });

      test('copies all fields', () {
        final copy = const TimedChallengeState().copyWith(
          puzzlesSolved: 1,
          totalTimeMs: 2,
          timeRemainingMs: 3,
          currentStreak: 4,
          isActive: true,
          isGameOver: false,
          solveTimes: [100],
          bestStreak: 5,
          score: 600,
        );
        expect(copy.puzzlesSolved, 1);
        expect(copy.totalTimeMs, 2);
        expect(copy.timeRemainingMs, 3);
        expect(copy.currentStreak, 4);
        expect(copy.isActive, true);
        expect(copy.isGameOver, false);
        expect(copy.solveTimes, [100]);
        expect(copy.bestStreak, 5);
        expect(copy.score, 600);
      });
    });

    group('serialization', () {
      test('toJson produces valid map', () {
        const state = TimedChallengeState(
          puzzlesSolved: 3,
          totalTimeMs: 15000,
          timeRemainingMs: 45000,
          currentStreak: 2,
          isActive: true,
          isGameOver: false,
          solveTimes: [5000, 4000, 6000],
          bestStreak: 3,
          score: 400,
        );
        final json = state.toJson();
        expect(json['puzzlesSolved'], 3);
        expect(json['totalTimeMs'], 15000);
        expect(json['timeRemainingMs'], 45000);
        expect(json['currentStreak'], 2);
        expect(json['isActive'], true);
        expect(json['isGameOver'], false);
        expect(json['solveTimes'], [5000, 4000, 6000]);
        expect(json['bestStreak'], 3);
        expect(json['score'], 400);
      });

      test('fromJson restores state', () {
        final json = {
          'puzzlesSolved': 5,
          'totalTimeMs': 25000,
          'timeRemainingMs': 35000,
          'currentStreak': 3,
          'isActive': false,
          'isGameOver': true,
          'solveTimes': [3000, 4000, 5000, 6000, 7000],
          'bestStreak': 4,
          'score': 800,
        };
        final state = TimedChallengeState.fromJson(json);
        expect(state.puzzlesSolved, 5);
        expect(state.totalTimeMs, 25000);
        expect(state.timeRemainingMs, 35000);
        expect(state.currentStreak, 3);
        expect(state.isActive, false);
        expect(state.isGameOver, true);
        expect(state.solveTimes, [3000, 4000, 5000, 6000, 7000]);
        expect(state.bestStreak, 4);
        expect(state.score, 800);
      });

      test('roundtrip toJson/fromJson preserves state', () {
        const original = TimedChallengeState(
          puzzlesSolved: 7,
          totalTimeMs: 42000,
          timeRemainingMs: 18000,
          currentStreak: 5,
          isActive: true,
          isGameOver: false,
          solveTimes: [6000, 5500, 5000, 6500, 7000, 4500, 8000],
          bestStreak: 5,
          score: 1200,
        );

        final restored = TimedChallengeState.fromJson(original.toJson());
        expect(restored.puzzlesSolved, original.puzzlesSolved);
        expect(restored.totalTimeMs, original.totalTimeMs);
        expect(restored.timeRemainingMs, original.timeRemainingMs);
        expect(restored.currentStreak, original.currentStreak);
        expect(restored.isActive, original.isActive);
        expect(restored.isGameOver, original.isGameOver);
        expect(restored.solveTimes, original.solveTimes);
        expect(restored.bestStreak, original.bestStreak);
        expect(restored.score, original.score);
      });

      test('fromJson handles missing fields with defaults', () {
        final state = TimedChallengeState.fromJson({});
        expect(state.puzzlesSolved, 0);
        expect(state.totalTimeMs, 0);
        expect(state.timeRemainingMs, 0);
        expect(state.currentStreak, 0);
        expect(state.isActive, false);
        expect(state.isGameOver, false);
        expect(state.solveTimes, isEmpty);
        expect(state.bestStreak, 0);
        expect(state.score, 0);
      });
    });

    group('toString', () {
      test('shows active status', () {
        const state = TimedChallengeState(isActive: true);
        expect(state.toString(), contains('active'));
      });

      test('shows game-over status', () {
        const state = TimedChallengeState(isGameOver: true);
        expect(state.toString(), contains('game-over'));
      });

      test('shows inactive status', () {
        const state = TimedChallengeState();
        expect(state.toString(), contains('inactive'));
      });
    });
  });
}
