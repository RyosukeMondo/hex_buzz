import '../models/progress_state.dart';

/// Abstract interface for progress persistence.
///
/// Provides methods to load, save, and reset player progress.
/// Supports user-specific progress storage for multi-user authentication.
/// Implementations can use different storage backends (local storage, cloud, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class ProgressRepository {
  /// Loads progress state for a specific user.
  ///
  /// Returns [ProgressState.empty()] if no saved progress exists for the user.
  /// Implementations should handle corrupted data gracefully by returning
  /// an empty state rather than throwing exceptions.
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  Future<ProgressState> loadForUser(String userId);

  /// Saves progress state for a specific user.
  ///
  /// Throws an exception if the save operation fails.
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  /// [state] The progress state to save.
  Future<void> saveForUser(String userId, ProgressState state);

  /// Resets progress for a specific user, removing saved data.
  ///
  /// After calling this method, [loadForUser] should return [ProgressState.empty()].
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  Future<void> resetForUser(String userId);
}
