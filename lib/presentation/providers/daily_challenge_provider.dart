import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/daily_challenge.dart';
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

/// State class for daily challenge data.
class DailyChallengeState {
  final DailyChallenge? challenge;
  final bool isLoading;
  final String? error;
  final bool hasCompleted;

  const DailyChallengeState({
    this.challenge,
    this.isLoading = false,
    this.error,
    this.hasCompleted = false,
  });

  DailyChallengeState copyWith({
    DailyChallenge? challenge,
    bool? isLoading,
    String? error,
    bool? hasCompleted,
    bool clearChallenge = false,
    bool clearError = false,
  }) {
    return DailyChallengeState(
      challenge: clearChallenge ? null : (challenge ?? this.challenge),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasCompleted: hasCompleted ?? this.hasCompleted,
    );
  }
}

/// AsyncNotifier for managing daily challenge state.
///
/// Handles fetching today's challenge, submitting completions, and tracking
/// completion status. Integrates with [DailyChallengeRepository] for challenge operations.
class DailyChallengeNotifier
    extends AutoDisposeAsyncNotifier<DailyChallengeState> {
  late DailyChallengeRepository _repository;

  @override
  Future<DailyChallengeState> build() async {
    _repository = ref.watch(dailyChallengeRepositoryProvider);

    try {
      final challenge = await _repository.getTodaysChallenge();
      return DailyChallengeState(
        challenge: challenge,
        hasCompleted: challenge?.hasUserCompleted ?? false,
      );
    } catch (e) {
      return DailyChallengeState(error: e.toString());
    }
  }

  /// Refreshes the daily challenge data.
  ///
  /// Fetches the latest challenge for today.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final challenge = await _repository.getTodaysChallenge();
      state = AsyncValue.data(
        DailyChallengeState(
          challenge: challenge,
          hasCompleted: challenge?.hasUserCompleted ?? false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(DailyChallengeState(error: e.toString()));
    }
  }

  /// Checks if the user has completed today's challenge.
  ///
  /// Updates the state with the completion status.
  Future<void> checkCompletionStatus(String userId) async {
    final currentState = state.valueOrNull ?? const DailyChallengeState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final hasCompleted = await _repository.hasCompletedToday(userId);
      state = AsyncValue.data(
        currentState.copyWith(
          hasCompleted: hasCompleted,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  /// Submits a completion for today's daily challenge.
  ///
  /// Returns true if submission succeeded, false otherwise.
  /// Automatically refreshes the challenge data on success to show updated stats.
  Future<bool> submitCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  }) async {
    final currentState = state.valueOrNull ?? const DailyChallengeState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final success = await _repository.submitChallengeCompletion(
        userId: userId,
        stars: stars,
        completionTimeMs: completionTimeMs,
      );

      if (success) {
        await refresh();
      } else {
        state = AsyncValue.data(
          currentState.copyWith(
            isLoading: false,
            error: 'Failed to submit challenge completion',
          ),
        );
      }

      return success;
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoading: false, error: e.toString()),
      );
      return false;
    }
  }
}

/// Provider for daily challenge state management.
final dailyChallengeProvider =
    AutoDisposeAsyncNotifierProvider<
      DailyChallengeNotifier,
      DailyChallengeState
    >(DailyChallengeNotifier.new);
