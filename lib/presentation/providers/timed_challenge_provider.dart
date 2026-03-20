import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/timed_challenge_state.dart';
import '../../domain/services/timed_challenge_repository.dart';
import '../../domain/services/timed_challenge_service.dart';
import 'game_provider.dart';

/// Provider for the timed challenge repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation.
final timedChallengeRepositoryProvider =
    Provider<TimedChallengeRepository>((ref) {
  throw UnimplementedError(
    'timedChallengeRepositoryProvider must be overridden '
    'with a concrete implementation',
  );
});

/// Provider for the timed challenge service (stateless logic).
final timedChallengeServiceProvider = Provider<TimedChallengeService>((ref) {
  return const TimedChallengeService();
});

/// Notifier that manages timed challenge state with a countdown timer.
///
/// Handles starting/ending challenges, tracking puzzle solves and skips,
/// and maintaining the countdown timer that ticks every 100ms.
class TimedChallengeNotifier extends StateNotifier<TimedChallengeState> {
  final TimedChallengeService _service;
  final TimedChallengeRepository _repository;
  final Ref _ref;
  Timer? _countdownTimer;
  TimedChallengeConfig? _activeConfig;

  TimedChallengeNotifier({
    required TimedChallengeService service,
    required TimedChallengeRepository repository,
    required Ref ref,
  })  : _service = service,
        _repository = repository,
        _ref = ref,
        super(const TimedChallengeState.initial());

  /// The currently active challenge configuration.
  TimedChallengeConfig? get activeConfig => _activeConfig;

  /// Starts a new timed challenge with the given configuration.
  ///
  /// Resets all state, sets the countdown timer, and generates the
  /// first puzzle at the starting edge size.
  void startChallenge(TimedChallengeConfig config) {
    _stopTimer();
    _activeConfig = config;

    state = TimedChallengeState(
      timeRemainingMs: config.timeLimit.inMilliseconds,
      isActive: true,
    );

    // Generate first puzzle
    final gameNotifier = _ref.read(gameProvider.notifier);
    gameNotifier.generateNewLevel(
      newEdgeSize: config.startingEdgeSize,
    );

    _startTimer();
  }

  /// Called when the player successfully solves the current puzzle.
  ///
  /// Awards bonus time, updates streak and stats, generates the next puzzle.
  void onPuzzleSolved(Duration solveTime) {
    if (!state.isActive || state.isGameOver) return;

    final config = _activeConfig;
    if (config == null) return;

    final newStreak = state.currentStreak + 1;
    final newBestStreak =
        newStreak > state.bestStreak ? newStreak : state.bestStreak;
    final newSolveTimes = [...state.solveTimes, solveTime.inMilliseconds];
    final newPuzzlesSolved = state.puzzlesSolved + 1;

    // Calculate bonus time
    final bonus = _service.getBonusTime(config, state.puzzlesSolved);
    final newTimeRemaining = state.timeRemainingMs + bonus.inMilliseconds;

    state = state.copyWith(
      puzzlesSolved: newPuzzlesSolved,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      solveTimes: newSolveTimes,
      timeRemainingMs: newTimeRemaining,
      totalTimeMs: state.totalTimeMs + solveTime.inMilliseconds,
    );

    // Update score
    state = state.copyWith(score: _service.calculateScore(state));

    // Generate next puzzle with progressive difficulty
    final nextEdgeSize = _service.getNextEdgeSize(newPuzzlesSolved);
    final gameNotifier = _ref.read(gameProvider.notifier);
    gameNotifier.generateNewLevel(newEdgeSize: nextEdgeSize);
  }

  /// Called when the player skips the current puzzle.
  ///
  /// No bonus time, streak resets. Generates a new puzzle at the same
  /// difficulty level.
  void onPuzzleSkipped() {
    if (!state.isActive || state.isGameOver) return;

    state = state.copyWith(currentStreak: 0);

    // Generate new puzzle at current difficulty (no increase)
    final nextEdgeSize = _service.getNextEdgeSize(state.puzzlesSolved);
    final gameNotifier = _ref.read(gameProvider.notifier);
    gameNotifier.generateNewLevel(newEdgeSize: nextEdgeSize);
  }

  /// Ends the challenge manually or when time runs out.
  ///
  /// Stops the timer, marks as game over, and persists the best score.
  void endChallenge() {
    _stopTimer();

    final finalScore = _service.calculateScore(state);
    state = state.copyWith(
      isActive: false,
      isGameOver: true,
      score: finalScore,
    );

    _persistBestScore(finalScore);
  }

  /// Timer tick handler, called every 100ms for smooth countdown display.
  void _tick() {
    if (!state.isActive || state.isGameOver) {
      _stopTimer();
      return;
    }

    final newTimeRemaining = state.timeRemainingMs - 100;
    if (newTimeRemaining <= 0) {
      // Time's up
      state = state.copyWith(timeRemainingMs: 0);
      endChallenge();
      return;
    }

    state = state.copyWith(timeRemainingMs: newTimeRemaining);
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _tick(),
    );
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _persistBestScore(int score) async {
    final config = _activeConfig;
    if (config == null) return;

    try {
      await _repository.saveBestScore(config.id, score);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save timed challenge best score: $e');
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Provider for timed challenge state management.
final timedChallengeProvider =
    StateNotifierProvider.autoDispose<TimedChallengeNotifier,
        TimedChallengeState>((ref) {
  final service = ref.watch(timedChallengeServiceProvider);
  final repository = ref.watch(timedChallengeRepositoryProvider);
  return TimedChallengeNotifier(
    service: service,
    repository: repository,
    ref: ref,
  );
});

/// Provider for loading best scores for all preset configurations.
final timedChallengeBestScoresProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(timedChallengeRepositoryProvider);
  final configIds =
      TimedChallengeConfig.presets.map((c) => c.id).toList();
  return repository.getAllBestScores(configIds);
});
