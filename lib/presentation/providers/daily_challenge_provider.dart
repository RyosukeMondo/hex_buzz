import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/diagnostic_logger.dart';
import '../../core/logging/logger.dart';
import '../../domain/models/daily_challenge_completion.dart';
import '../../domain/models/daily_challenge_state.dart' as domain;
import '../../domain/models/hex_cell.dart';
import '../../domain/services/daily_challenge_repository.dart';

/// Provider for the daily challenge repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., FirebaseDailyChallengeRepository).
final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((
  ref,
) {
  throw UnimplementedError(
    'dailyChallengeRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// StateNotifier for managing daily challenge state with one-attempt-per-day enforcement.
///
/// This provider implements the state machine with sealed union states to enforce:
/// - One attempt per day (no retries after completion)
/// - Timer cannot be reset (startTime preserved across suspend/resume)
/// - Type-safe state transitions
class DailyChallengeNotifier extends StateNotifier<domain.DailyChallengeState> {
  final DailyChallengeRepository _repository;
  final String _userId;

  DailyChallengeNotifier({
    required DailyChallengeRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(const domain.DailyChallengeStateLoading());

  /// Loads today's challenge and checks for existing completion.
  ///
  /// Sets state to:
  /// - NotStarted if challenge exists and user hasn't completed it
  /// - AlreadyCompleted if user has already completed it today
  /// - Error if loading fails
  Future<void> loadChallenge() async {
    try {
      DiagnosticLogger.logEvent(
        'Loading daily challenge',
        data: {'userId': _userId},
        level: LogLevel.info,
      );

      state = const domain.DailyChallengeStateLoading();

      final challenge = await _repository.getTodaysChallenge();
      if (challenge == null) {
        state = const domain.DailyChallengeStateError(
          'No daily challenge available for today',
        );
        return;
      }

      // Check for existing completion
      final completion = await _repository.getCompletion(
        userId: _userId,
        dateId: challenge.id,
      );

      if (completion != null) {
        DiagnosticLogger.logEvent(
          'User has already completed challenge',
          data: {'userId': _userId, 'dateId': challenge.id},
          level: LogLevel.info,
        );
        state = domain.DailyChallengeStateAlreadyCompleted(completion);
      } else {
        DiagnosticLogger.logEvent(
          'Challenge ready to start',
          data: {'userId': _userId, 'dateId': challenge.id},
          level: LogLevel.info,
        );
        state = domain.DailyChallengeStateNotStarted(challenge);
      }
    } catch (e, stackTrace) {
      DiagnosticLogger.logError(
        'Error loading challenge',
        error: e,
        stackTrace: stackTrace,
      );
      state = domain.DailyChallengeStateError(e.toString());
    }
  }

  /// Starts the challenge.
  ///
  /// Only allowed from NotStarted state.
  /// Records startTime to prevent timer resets.
  void startChallenge() {
    final currentState = state;
    if (currentState is! domain.DailyChallengeStateNotStarted) {
      DiagnosticLogger.logEvent(
        'Cannot start challenge from current state',
        data: {'state': currentState.runtimeType.toString()},
        level: LogLevel.warn,
      );
      return;
    }

    final startTime = DateTime.now();
    DiagnosticLogger.logEvent(
      'Challenge started',
      data: {
        'userId': _userId,
        'challengeId': currentState.challenge.id,
        'startTime': startTime.toIso8601String(),
      },
      level: LogLevel.info,
    );

    state = domain.DailyChallengeStatePlaying(
      challenge: currentState.challenge,
      startTime: startTime,
      currentPath: const [],
    );
  }

  /// Suspends the challenge.
  ///
  /// Timer keeps running (startTime is preserved).
  /// Only allowed from Playing state.
  void suspend() {
    final currentState = state;
    if (currentState is! domain.DailyChallengeStatePlaying) {
      DiagnosticLogger.logEvent(
        'Cannot suspend from current state',
        data: {'state': currentState.runtimeType.toString()},
        level: LogLevel.warn,
      );
      return;
    }

    final suspendedTime = DateTime.now();
    DiagnosticLogger.logEvent(
      'Challenge suspended',
      data: {
        'userId': _userId,
        'startTime': currentState.startTime.toIso8601String(),
        'suspendedTime': suspendedTime.toIso8601String(),
      },
      level: LogLevel.info,
    );

    state = domain.DailyChallengeStateSuspended(
      challenge: currentState.challenge,
      startTime: currentState.startTime, // Preserved - timer keeps running
      suspendedTime: suspendedTime,
      currentPath: currentState.currentPath,
    );
  }

  /// Resumes the challenge.
  ///
  /// Returns to Playing state with same startTime (no timer restart).
  /// Only allowed from Suspended state.
  void resume() {
    final currentState = state;
    if (currentState is! domain.DailyChallengeStateSuspended) {
      DiagnosticLogger.logEvent(
        'Cannot resume from current state',
        data: {'state': currentState.runtimeType.toString()},
        level: LogLevel.warn,
      );
      return;
    }

    DiagnosticLogger.logEvent(
      'Challenge resumed',
      data: {
        'userId': _userId,
        'startTime': currentState.startTime.toIso8601String(),
      },
      level: LogLevel.info,
    );

    state = domain.DailyChallengeStatePlaying(
      challenge: currentState.challenge,
      startTime: currentState.startTime, // Same startTime - no restart
      currentPath: currentState.currentPath,
    );
  }

  /// Updates the current path during gameplay.
  void updatePath(List<HexCell> path) {
    final currentState = state;
    if (currentState is domain.DailyChallengeStatePlaying) {
      state = currentState.copyWith(currentPath: path);
    }
  }

  /// Completes the challenge.
  ///
  /// Submits completion to backend and transitions to Completed state.
  /// Only allowed from Playing state.
  Future<void> complete(int stars) async {
    final currentState = state;
    if (currentState is! domain.DailyChallengeStatePlaying) {
      DiagnosticLogger.logEvent(
        'Cannot complete from current state',
        data: {'state': currentState.runtimeType.toString()},
        level: LogLevel.warn,
      );
      return;
    }

    final completionTimeMs = DateTime.now()
        .difference(currentState.startTime)
        .inMilliseconds;

    DiagnosticLogger.logEvent(
      'Submitting challenge completion',
      data: {
        'userId': _userId,
        'stars': stars,
        'completionTimeMs': completionTimeMs,
      },
      level: LogLevel.info,
    );

    try {
      final success = await _repository.submitChallengeCompletion(
        userId: _userId,
        stars: stars,
        completionTimeMs: completionTimeMs,
      );

      if (success) {
        // Get the completion data with rank
        final completion = await _repository.getCompletion(
          userId: _userId,
          dateId: currentState.challenge.id,
        );

        if (completion != null) {
          DiagnosticLogger.logEvent(
            'Challenge completed successfully',
            data: {'userId': _userId, 'stars': stars, 'rank': completion.rank},
            level: LogLevel.info,
          );
          state = domain.DailyChallengeStateCompleted(completion);
        } else {
          // Fallback if we can't get completion data
          state = domain.DailyChallengeStateCompleted(
            DailyChallengeCompletion(
              userId: _userId,
              dateId: currentState.challenge.id,
              stars: stars,
              completionTimeMs: completionTimeMs,
              completedAt: DateTime.now(),
            ),
          );
        }
      } else {
        state = const domain.DailyChallengeStateError(
          'Failed to submit completion',
        );
      }
    } catch (e, stackTrace) {
      DiagnosticLogger.logError(
        'Error completing challenge',
        error: e,
        stackTrace: stackTrace,
      );
      state = domain.DailyChallengeStateError(e.toString());
    }
  }
}

/// Provider for daily challenge state management.
///
/// Requires userId to be provided via parameter.
final dailyChallengeProvider = StateNotifierProvider.autoDispose
    .family<DailyChallengeNotifier, domain.DailyChallengeState, String>((
      ref,
      userId,
    ) {
      final repository = ref.watch(dailyChallengeRepositoryProvider);
      final notifier = DailyChallengeNotifier(
        repository: repository,
        userId: userId,
      );
      // Auto-load challenge when provider is created
      notifier.loadChallenge();
      return notifier;
    });
