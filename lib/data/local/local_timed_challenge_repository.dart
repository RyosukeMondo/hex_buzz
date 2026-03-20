import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/timed_challenge_repository.dart';

/// Repository for persisting timed challenge best scores.
///
/// Uses SharedPreferences for local storage, keyed by challenge config ID.
class LocalTimedChallengeRepository implements TimedChallengeRepository {
  static const String _keyPrefix = 'timed_challenge_best_';

  final SharedPreferences _prefs;

  LocalTimedChallengeRepository(this._prefs);

  /// Retrieves the best score for a given challenge configuration.
  ///
  /// Returns 0 if no score has been recorded.
  @override
  Future<int> getBestScore(String configId) async {
    return _prefs.getInt('$_keyPrefix$configId') ?? 0;
  }

  /// Saves a new best score for a given challenge configuration.
  ///
  /// Only saves if the new score is higher than the existing best.
  @override
  Future<void> saveBestScore(String configId, int score) async {
    final currentBest = await getBestScore(configId);
    if (score > currentBest) {
      await _prefs.setInt('$_keyPrefix$configId', score);
    }
  }

  /// Retrieves best scores for all known config IDs.
  @override
  Future<Map<String, int>> getAllBestScores(List<String> configIds) async {
    final scores = <String, int>{};
    for (final id in configIds) {
      scores[id] = await getBestScore(id);
    }
    return scores;
  }

  /// Clears all timed challenge scores.
  @override
  Future<void> clearAll(List<String> configIds) async {
    for (final id in configIds) {
      await _prefs.remove('$_keyPrefix$id');
    }
  }
}
