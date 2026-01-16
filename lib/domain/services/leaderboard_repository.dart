import '../models/leaderboard_entry.dart';

/// Abstract interface for leaderboard operations.
///
/// Provides methods for retrieving rankings, submitting scores, and monitoring
/// leaderboard changes. Implementations can use different backends (Firestore,
/// local cache, etc.) while consumers depend only on this interface for DI.
abstract class LeaderboardRepository {
  /// Gets the top players from the global leaderboard.
  ///
  /// Returns a list of [LeaderboardEntry] objects sorted by total stars (descending).
  /// The [limit] parameter specifies how many players to fetch (default: 100).
  /// The [offset] parameter specifies where to start for pagination (default: 0).
  ///
  /// Returns empty list if no data available or on error.
  Future<List<LeaderboardEntry>> getTopPlayers({
    int limit = 100,
    int offset = 0,
  });

  /// Gets the current user's rank on the global leaderboard.
  ///
  /// Returns the user's [LeaderboardEntry] including their rank and stats.
  /// Returns null if the user is not ranked or not authenticated.
  Future<LeaderboardEntry?> getUserRank(String userId);

  /// Submits a score for the current user.
  ///
  /// Updates the user's total stars in the leaderboard if the new score
  /// is an improvement. The leaderboard rankings are recomputed asynchronously
  /// by the backend.
  ///
  /// The [userId] identifies the user submitting the score.
  /// The [stars] is the total star count to submit.
  /// The [levelId] is optional metadata about which level was completed.
  ///
  /// Returns true if submission succeeded, false otherwise.
  Future<bool> submitScore({
    required String userId,
    required int stars,
    String? levelId,
  });

  /// Gets the leaderboard for a specific daily challenge.
  ///
  /// Returns a list of [LeaderboardEntry] objects for players who completed
  /// the daily challenge on [date], sorted by stars (descending) and time (ascending).
  /// The [limit] parameter specifies how many entries to fetch (default: 100).
  ///
  /// Returns empty list if no data available or on error.
  Future<List<LeaderboardEntry>> getDailyChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  });

  /// A stream that emits leaderboard updates in real-time.
  ///
  /// Emits a new list of [LeaderboardEntry] objects whenever the leaderboard
  /// changes (e.g., new scores submitted, rankings updated).
  /// The [limit] parameter specifies how many top players to watch (default: 100).
  ///
  /// Implementations may throttle updates to reduce load.
  Stream<List<LeaderboardEntry>> watchLeaderboard({int limit = 100});
}
