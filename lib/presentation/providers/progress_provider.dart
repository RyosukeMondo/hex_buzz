import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/progress_state.dart';
import '../../domain/models/user.dart';
import '../../domain/services/progress_repository.dart';
import '../../domain/services/star_calculator.dart';
import 'auth_provider.dart';

/// Provider for the progress repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., LocalProgressRepository).
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  throw UnimplementedError(
    'progressRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// AsyncNotifier for managing player progress state.
///
/// Handles level completion, star calculation, and progress persistence.
/// Integrates with [ProgressRepository] for storage, [StarCalculator]
/// for computing star ratings, and [AuthProvider] for user-specific progress.
///
/// Progress is stored per-user:
/// - Logged-in users: Progress keyed by user ID
/// - Guest users: Progress keyed by "guest" (local-only, persists on device)
class ProgressNotifier extends AsyncNotifier<ProgressState> {
  late ProgressRepository _repository;
  String? _currentUserId;

  @override
  Future<ProgressState> build() async {
    _repository = ref.watch(progressRepositoryProvider);

    // Watch auth state and react to user changes
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) => _loadProgressForUser(user),
      loading: () => const ProgressState.empty(),
      error: (_, __) => const ProgressState.empty(),
    );
  }

  /// Loads progress for the given user.
  ///
  /// Updates [_currentUserId] and loads user-specific progress.
  /// For guest users (isGuest=true), uses "guest" as the storage key.
  /// For null user (logged out), returns empty state without loading.
  Future<ProgressState> _loadProgressForUser(User? user) async {
    if (user == null) {
      _currentUserId = null;
      return const ProgressState.empty();
    }

    // Use "guest" key for guest users, otherwise use actual user ID
    _currentUserId = user.isGuest ? 'guest' : user.id;
    return _repository.loadForUser(_currentUserId!);
  }

  /// Completes a level with the given time.
  ///
  /// Calculates stars based on completion time, updates the progress state,
  /// and persists the result. Only updates if the new result is better
  /// (more stars or faster time).
  ///
  /// Returns the number of stars earned for this completion.
  /// Returns 0 if no user is logged in.
  Future<int> completeLevel(int levelIndex, Duration completionTime) async {
    if (_currentUserId == null) {
      return 0;
    }

    final stars = StarCalculator.calculateStars(completionTime);

    state = await AsyncValue.guard(() async {
      final currentState = state.valueOrNull ?? const ProgressState.empty();
      final newState = currentState.withLevelCompleted(
        levelIndex,
        stars: stars,
        time: completionTime,
      );
      await _repository.saveForUser(_currentUserId!, newState);
      return newState;
    });

    return stars;
  }

  /// Resets all progress for the current user.
  ///
  /// Clears all level progress and persists the empty state.
  /// Does nothing if no user is logged in.
  Future<void> resetProgress() async {
    if (_currentUserId == null) {
      return;
    }

    state = await AsyncValue.guard(() async {
      const emptyState = ProgressState.empty();
      await _repository.resetForUser(_currentUserId!);
      return emptyState;
    });
  }
}

/// Provider for progress state management.
final progressProvider = AsyncNotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);
