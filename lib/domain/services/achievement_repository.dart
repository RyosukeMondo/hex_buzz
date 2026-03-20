import '../models/achievement.dart';

/// Abstract interface for achievement persistence.
///
/// Provides methods to load, save, and reset achievement progress.
/// Supports user-specific storage for multi-user authentication.
/// Implementations can use different storage backends (local storage, cloud, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class AchievementRepository {
  /// Loads achievement state for a specific user.
  ///
  /// Returns [AchievementState.empty()] if no saved state exists for the user.
  /// Implementations should handle corrupted data gracefully by returning
  /// an empty state rather than throwing exceptions.
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  Future<AchievementState> loadForUser(String userId);

  /// Saves achievement state for a specific user.
  ///
  /// Throws an exception if the save operation fails.
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  /// [state] The achievement state to save.
  Future<void> saveForUser(String userId, AchievementState state);

  /// Resets achievement state for a specific user, removing saved data.
  ///
  /// After calling this method, [loadForUser] should return
  /// [AchievementState.empty()].
  ///
  /// [userId] The unique identifier of the user. Use "guest" for guest users.
  Future<void> resetForUser(String userId);
}
