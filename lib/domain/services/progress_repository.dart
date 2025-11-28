import '../models/progress_state.dart';

/// Abstract interface for progress persistence.
///
/// Provides methods to load, save, and reset player progress.
/// Implementations can use different storage backends (local storage, cloud, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class ProgressRepository {
  /// Loads the current progress state from storage.
  ///
  /// Returns [ProgressState.empty()] if no saved progress exists.
  /// Implementations should handle corrupted data gracefully by returning
  /// an empty state rather than throwing exceptions.
  Future<ProgressState> load();

  /// Saves the progress state to storage.
  ///
  /// Throws an exception if the save operation fails.
  Future<void> save(ProgressState state);

  /// Resets all progress, removing saved data.
  ///
  /// After calling this method, [load] should return [ProgressState.empty()].
  Future<void> reset();
}
