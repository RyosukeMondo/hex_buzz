/// Abstract interface for timed challenge best score persistence.
///
/// Provides methods to load, save, and clear timed challenge best scores.
/// Implementations can use different storage backends (local storage, cloud, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class TimedChallengeRepository {
  /// Retrieves the best score for a given challenge configuration.
  ///
  /// Returns 0 if no score has been recorded.
  Future<int> getBestScore(String configId);

  /// Saves a new best score for a given challenge configuration.
  ///
  /// Only saves if the new score is higher than the existing best.
  Future<void> saveBestScore(String configId, int score);

  /// Retrieves best scores for all known config IDs.
  Future<Map<String, int>> getAllBestScores(List<String> configIds);

  /// Clears all timed challenge scores.
  Future<void> clearAll(List<String> configIds);
}
