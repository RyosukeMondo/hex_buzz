import 'dart:math';

import '../models/timed_challenge_state.dart';

/// Configuration for a timed challenge mode.
///
/// Defines the time limit, starting difficulty, and bonus time per solve.
/// Provides preset configurations for different challenge intensities.
class TimedChallengeConfig {
  final String id;
  final String name;
  final Duration timeLimit;
  final int startingEdgeSize;
  final Duration bonusTimePerSolve;

  const TimedChallengeConfig({
    required this.id,
    required this.name,
    required this.timeLimit,
    required this.startingEdgeSize,
    required this.bonusTimePerSolve,
  });

  /// Blitz mode: 60 seconds, fast-paced with small bonus.
  static const blitz = TimedChallengeConfig(
    id: 'blitz',
    name: 'Blitz',
    timeLimit: Duration(seconds: 60),
    startingEdgeSize: 2,
    bonusTimePerSolve: Duration(seconds: 10),
  );

  /// Sprint mode: 2 minutes, balanced challenge.
  static const sprint = TimedChallengeConfig(
    id: 'sprint',
    name: 'Sprint',
    timeLimit: Duration(minutes: 2),
    startingEdgeSize: 2,
    bonusTimePerSolve: Duration(seconds: 15),
  );

  /// Marathon mode: 5 minutes, longer challenge with larger bonus.
  static const marathon = TimedChallengeConfig(
    id: 'marathon',
    name: 'Marathon',
    timeLimit: Duration(minutes: 5),
    startingEdgeSize: 2,
    bonusTimePerSolve: Duration(seconds: 20),
  );

  /// All available preset configurations.
  static const List<TimedChallengeConfig> presets = [blitz, sprint, marathon];
}

/// Service for timed challenge game logic.
///
/// Handles score calculation, difficulty progression, and bonus time
/// computation. Stateless service that operates on [TimedChallengeState].
class TimedChallengeService {
  const TimedChallengeService();

  /// Calculates the total score based on challenge performance.
  ///
  /// Scoring formula:
  /// - Base points: 100 per puzzle solved
  /// - Streak bonus: 50 * (streak - 1) for each puzzle in a streak
  /// - Speed bonus: max(0, 500 - averageSolveTime/100) for fast solving
  /// - Time bonus: remaining time in seconds
  int calculateScore(TimedChallengeState state) {
    if (state.puzzlesSolved == 0) return 0;

    final basePoints = state.puzzlesSolved * 100;
    final streakBonus = _calculateStreakBonus(state);
    final speedBonus = _calculateSpeedBonus(state);
    final timeBonus = max(0, state.timeRemainingMs ~/ 1000);

    return basePoints + streakBonus + speedBonus + timeBonus;
  }

  int _calculateStreakBonus(TimedChallengeState state) {
    if (state.bestStreak <= 1) return 0;
    // Bonus grows quadratically with streak length
    return 50 * (state.bestStreak - 1);
  }

  int _calculateSpeedBonus(TimedChallengeState state) {
    final avgTime = state.averageSolveTime;
    if (avgTime <= 0) return 0;
    // Faster average solve time gives more bonus (capped)
    return max(0, (500 - avgTime / 100).toInt());
  }

  /// Gets the edge size for the next puzzle based on puzzles solved.
  ///
  /// Difficulty increases every 3 puzzles, starting from [startingEdgeSize].
  /// Caps at edge size 5 to keep puzzles solvable under time pressure.
  int getNextEdgeSize(int puzzlesSolved, {int startingEdgeSize = 2}) {
    final increase = puzzlesSolved ~/ 3;
    return min(5, startingEdgeSize + increase);
  }

  /// Calculates bonus time for solving a puzzle.
  ///
  /// Bonus decreases slightly as more puzzles are solved to increase
  /// difficulty, but never drops below 50% of the base bonus.
  Duration getBonusTime(TimedChallengeConfig config, int puzzlesSolved) {
    final baseMs = config.bonusTimePerSolve.inMilliseconds;
    // Reduce bonus by 5% per puzzle solved, minimum 50% of base
    final multiplier = max(0.5, 1.0 - (puzzlesSolved * 0.05));
    return Duration(milliseconds: (baseMs * multiplier).round());
  }
}
