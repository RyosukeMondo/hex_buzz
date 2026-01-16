import '../models/daily_challenge.dart';
import '../models/leaderboard_entry.dart';

/// Abstract interface for daily challenge operations.
///
/// Provides methods for retrieving daily challenges, submitting completions,
/// and checking completion status. Implementations can use different backends
/// (Firestore, local storage, etc.) while consumers depend only on this
/// interface for dependency injection.
abstract class DailyChallengeRepository {
  /// Gets today's daily challenge.
  ///
  /// Returns a [DailyChallenge] object for the current date (UTC).
  /// The challenge includes the puzzle level, completion count, and the user's
  /// best result if they've already completed it today.
  ///
  /// Returns null if today's challenge is not yet available or on error.
  Future<DailyChallenge?> getTodaysChallenge();

  /// Submits a completion for today's daily challenge.
  ///
  /// Records the user's completion with their time and stars earned.
  /// If this is an improvement over their previous attempt, updates their
  /// best score for today's challenge.
  ///
  /// The [userId] identifies the user completing the challenge.
  /// The [stars] is the number of stars earned (1-3).
  /// The [completionTimeMs] is the time taken to complete in milliseconds.
  ///
  /// Returns true if submission succeeded, false otherwise.
  Future<bool> submitChallengeCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  });

  /// Gets the leaderboard for a specific daily challenge.
  ///
  /// Returns a list of [LeaderboardEntry] objects for players who completed
  /// the daily challenge on [date], sorted by stars (descending) and time (ascending).
  /// The [limit] parameter specifies how many entries to fetch (default: 100).
  ///
  /// Returns empty list if no data available or on error.
  Future<List<LeaderboardEntry>> getChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  });

  /// Checks if the current user has completed today's challenge.
  ///
  /// Returns true if the user identified by [userId] has completed today's
  /// daily challenge (UTC date), false otherwise.
  Future<bool> hasCompletedToday(String userId);
}
