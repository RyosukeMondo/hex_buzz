import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/level_pack.dart';
import '../../domain/services/level_pack_repository.dart';
import '../../domain/services/star_calculator.dart';

/// Provider for the level pack repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., LocalLevelPackRepository).
final levelPackRepositoryProvider = Provider<LevelPackRepository>((ref) {
  throw UnimplementedError(
    'levelPackRepositoryProvider must be overridden '
    'with a concrete implementation',
  );
});

/// AsyncNotifier for managing level packs and their progress.
///
/// Handles loading packs, tracking pack-specific progress, and
/// recording level completions within packs.
class LevelPackNotifier extends AsyncNotifier<List<LevelPack>> {
  late LevelPackRepository _repository;

  @override
  Future<List<LevelPack>> build() async {
    _repository = ref.watch(levelPackRepositoryProvider);
    return _repository.getAvailablePacks();
  }

  /// Reloads all packs from the repository.
  Future<void> loadPacks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAvailablePacks());
  }

  /// Gets progress for a specific pack.
  Future<LevelPackProgress> getProgress(String packId) {
    return _repository.getPackProgress(packId);
  }

  /// Records completion of a level within a pack.
  ///
  /// Calculates stars from completion time, updates pack progress,
  /// and persists the result. Only updates if the new result is better.
  Future<void> completePackLevel(
    String packId,
    int levelIndex,
    Duration time,
  ) async {
    final stars = StarCalculator.calculateStars(time);
    final currentProgress = await _repository.getPackProgress(packId);

    final updatedProgress = currentProgress.withLevelCompleted(
      levelIndex,
      stars: stars,
      time: time,
    );

    await _repository.savePackProgress(packId, updatedProgress);

    if (kDebugMode) {
      debugPrint(
        'Pack "$packId" level $levelIndex completed: '
        '$stars stars, ${time.inMilliseconds}ms',
      );
    }
  }
}

/// Provider for level pack state management.
final levelPackProvider =
    AsyncNotifierProvider<LevelPackNotifier, List<LevelPack>>(
  LevelPackNotifier.new,
);

/// Provider for pack progress, parameterized by pack ID.
///
/// Returns the progress for a specific pack. Auto-disposes when
/// the pack screen is left.
final packProgressProvider = FutureProvider.autoDispose
    .family<LevelPackProgress, String>((ref, packId) {
  final repository = ref.watch(levelPackRepositoryProvider);
  return repository.getPackProgress(packId);
});
