import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_repository.dart';

/// Provider for the leaderboard repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., FirebaseLeaderboardRepository).
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  throw UnimplementedError(
    'leaderboardRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// State class for global leaderboard data.
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? userEntry;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.entries = const [],
    this.userEntry,
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? userEntry,
    bool? isLoading,
    String? error,
    bool clearUserEntry = false,
    bool clearError = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      userEntry: clearUserEntry ? null : (userEntry ?? this.userEntry),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// AsyncNotifier for managing global leaderboard state.
///
/// Handles fetching top players, user rank, and submitting scores.
/// Integrates with [LeaderboardRepository] for leaderboard operations.
class LeaderboardNotifier extends AutoDisposeAsyncNotifier<LeaderboardState> {
  late LeaderboardRepository _repository;

  @override
  Future<LeaderboardState> build() async {
    _repository = ref.watch(leaderboardRepositoryProvider);

    try {
      final entries = await _repository.getTopPlayers(limit: 100);
      return LeaderboardState(entries: entries);
    } catch (e) {
      return LeaderboardState(error: e.toString());
    }
  }

  /// Refreshes the leaderboard data.
  ///
  /// Fetches the latest top players and updates the state.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final entries = await _repository.getTopPlayers(limit: 100);
      state = AsyncValue.data(LeaderboardState(entries: entries));
    } catch (e) {
      state = AsyncValue.data(LeaderboardState(error: e.toString()));
    }
  }

  /// Fetches the current user's rank.
  ///
  /// Updates the state with the user's leaderboard entry.
  Future<void> fetchUserRank(String userId) async {
    final currentState = state.valueOrNull ?? const LeaderboardState();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final userEntry = await _repository.getUserRank(userId);
      state = AsyncValue.data(
        currentState.copyWith(
          userEntry: userEntry,
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

  /// Submits a score for the current user.
  ///
  /// Returns true if submission succeeded, false otherwise.
  /// Automatically refreshes the leaderboard on success.
  Future<bool> submitScore({
    required String userId,
    required int stars,
    String? levelId,
  }) async {
    try {
      final success = await _repository.submitScore(
        userId: userId,
        stars: stars,
        levelId: levelId,
      );

      if (success) {
        await refresh();
      }

      return success;
    } catch (e) {
      final currentState = state.valueOrNull ?? const LeaderboardState();
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Loads more entries for pagination.
  ///
  /// Fetches additional entries starting from the current offset.
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoading) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final newEntries = await _repository.getTopPlayers(
        limit: 50,
        offset: currentState.entries.length,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          entries: [...currentState.entries, ...newEntries],
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
}

/// Provider for global leaderboard state management.
final leaderboardProvider =
    AutoDisposeAsyncNotifierProvider<LeaderboardNotifier, LeaderboardState>(
      LeaderboardNotifier.new,
    );

/// State class for daily challenge leaderboard data.
class DailyChallengeLeaderboardState {
  final List<LeaderboardEntry> entries;
  final DateTime date;
  final bool isLoading;
  final String? error;

  const DailyChallengeLeaderboardState({
    this.entries = const [],
    required this.date,
    this.isLoading = false,
    this.error,
  });

  DailyChallengeLeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    DateTime? date,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DailyChallengeLeaderboardState(
      entries: entries ?? this.entries,
      date: date ?? this.date,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// AsyncNotifier for managing daily challenge leaderboard state.
///
/// Handles fetching daily challenge rankings for a specific date.
class DailyChallengeLeaderboardNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          DailyChallengeLeaderboardState,
          DateTime
        > {
  late LeaderboardRepository _repository;

  @override
  Future<DailyChallengeLeaderboardState> build(DateTime arg) async {
    _repository = ref.watch(leaderboardRepositoryProvider);

    try {
      final entries = await _repository.getDailyChallengeLeaderboard(
        date: arg,
        limit: 100,
      );
      return DailyChallengeLeaderboardState(entries: entries, date: arg);
    } catch (e) {
      return DailyChallengeLeaderboardState(date: arg, error: e.toString());
    }
  }

  /// Refreshes the daily challenge leaderboard data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final entries = await _repository.getDailyChallengeLeaderboard(
        date: arg,
        limit: 100,
      );
      state = AsyncValue.data(
        DailyChallengeLeaderboardState(entries: entries, date: arg),
      );
    } catch (e) {
      state = AsyncValue.data(
        DailyChallengeLeaderboardState(date: arg, error: e.toString()),
      );
    }
  }
}

/// Provider for daily challenge leaderboard state management.
///
/// Takes a [DateTime] parameter to fetch leaderboard for a specific date.
final dailyChallengeLeaderboardProvider =
    AutoDisposeAsyncNotifierProvider.family<
      DailyChallengeLeaderboardNotifier,
      DailyChallengeLeaderboardState,
      DateTime
    >(DailyChallengeLeaderboardNotifier.new);
