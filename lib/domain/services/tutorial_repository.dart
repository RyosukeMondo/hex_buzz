/// Abstract interface for tutorial completion persistence.
///
/// Provides methods to check, mark, and reset tutorial completion state.
/// Implementations can use different storage backends (local storage, cloud, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class TutorialRepository {
  /// Returns true if the user has already completed the tutorial.
  bool hasCompletedTutorial();

  /// Marks the tutorial as completed so it won't show again.
  Future<void> markCompleted();

  /// Resets the tutorial state so it will show again on next launch.
  Future<void> reset();
}
