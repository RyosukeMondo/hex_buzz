import '../models/level_pack.dart';

/// Abstract interface for level pack persistence and retrieval.
///
/// Provides methods to load packs, access individual packs, and
/// manage pack-specific progress. Implementations can use different
/// storage backends while consumers depend only on this interface.
abstract class LevelPackRepository {
  /// Gets all available level packs.
  ///
  /// Returns built-in packs with their generated levels.
  /// Packs are returned in difficulty order.
  Future<List<LevelPack>> getAvailablePacks();

  /// Gets a specific pack by ID.
  ///
  /// Returns null if the pack ID is not recognized.
  Future<LevelPack?> getPack(String packId);

  /// Gets the progress for a specific pack.
  ///
  /// Returns empty progress if no progress has been saved.
  /// Uses the current user context for user-specific progress.
  Future<LevelPackProgress> getPackProgress(String packId);

  /// Saves progress for a specific pack.
  ///
  /// Persists the progress data for later retrieval.
  Future<void> savePackProgress(String packId, LevelPackProgress progress);
}
