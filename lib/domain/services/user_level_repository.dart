import '../models/user_level.dart';

/// Repository interface for managing user-created levels.
///
/// Provides CRUD operations for user levels with support for
/// share code-based retrieval.
abstract class UserLevelRepository {
  /// Returns all levels created by the given user.
  Future<List<UserLevel>> getMyLevels(String userId);

  /// Persists a user level (creates or updates).
  Future<void> saveLevel(UserLevel level);

  /// Deletes a user level by its ID.
  Future<void> deleteLevel(String levelId);

  /// Retrieves a user level by its share code.
  ///
  /// Returns null if no level matches the given code.
  Future<UserLevel?> getLevelByShareCode(String code);
}
