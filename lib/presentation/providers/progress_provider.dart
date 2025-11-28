import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';
import '../../domain/services/star_calculator.dart';

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
/// Integrates with [ProgressRepository] for storage and [StarCalculator]
/// for computing star ratings.
class ProgressNotifier extends AsyncNotifier<ProgressState> {
  late ProgressRepository _repository;

  @override
  Future<ProgressState> build() async {
    _repository = ref.watch(progressRepositoryProvider);
    return _repository.load();
  }

  /// Completes a level with the given time.
  ///
  /// Calculates stars based on completion time, updates the progress state,
  /// and persists the result. Only updates if the new result is better
  /// (more stars or faster time).
  ///
  /// Returns the number of stars earned for this completion.
  Future<int> completeLevel(int levelIndex, Duration completionTime) async {
    final stars = StarCalculator.calculateStars(completionTime);

    state = await AsyncValue.guard(() async {
      final currentState = state.valueOrNull ?? const ProgressState.empty();
      final newState = currentState.withLevelCompleted(
        levelIndex,
        stars: stars,
        time: completionTime,
      );
      await _repository.save(newState);
      return newState;
    });

    return stars;
  }

  /// Resets all progress to initial state.
  ///
  /// Clears all level progress and persists the empty state.
  Future<void> resetProgress() async {
    state = await AsyncValue.guard(() async {
      const emptyState = ProgressState.empty();
      await _repository.reset();
      return emptyState;
    });
  }
}

/// Provider for progress state management.
final progressProvider = AsyncNotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);
