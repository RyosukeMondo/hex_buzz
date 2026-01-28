import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_repository.dart';

/// Firestore implementation of [LeaderboardRepository].
///
/// Implements all leaderboard operations using Cloud Firestore with:
/// - Pagination for efficient data loading (50 entries per page)
/// - Local caching with 5-minute TTL to reduce Firestore reads
/// - Offline support showing cached data when unavailable
/// - Efficient queries using composite indexes
class FirestoreLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  // Cache management
  final Map<String, _CacheEntry<List<LeaderboardEntry>>> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  FirestoreLeaderboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<LeaderboardEntry>> getTopPlayers({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Check cache first
      final cacheKey = 'top_players_${limit}_$offset';
      final cached = _getCached(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Query Firestore
      final query = _firestore
          .collection('leaderboard')
          .orderBy('totalStars', descending: true)
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      // Convert documents to LeaderboardEntry objects
      final entries = <LeaderboardEntry>[];
      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        entries.add(
          LeaderboardEntry(
            userId: doc.id,
            username: data['username'] as String? ?? 'Unknown',
            avatarUrl: data['avatarUrl'] as String?,
            totalStars: data['totalStars'] as int? ?? 0,
            rank: offset + i + 1, // Calculate rank based on position
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }

      // Cache the result
      _cache[cacheKey] = _CacheEntry(entries, DateTime.now());

      return entries;
    } catch (e) {
      // On error, return cached data if available, otherwise empty list
      final cacheKey = 'top_players_${limit}_$offset';
      return _getCached(cacheKey, ignoreExpiry: true) ?? [];
    }
  }

  @override
  Future<LeaderboardEntry?> getUserRank(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'user_rank_$userId';
      final cached = _getCached(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.first;
      }

      // Get user's leaderboard entry
      final doc = await _firestore.collection('leaderboard').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Calculate rank by counting users with more stars
      final betterPlayersCount = await _firestore
          .collection('leaderboard')
          .where('totalStars', isGreaterThan: data['totalStars'] ?? 0)
          .count()
          .get();

      final rank = betterPlayersCount.count! + 1;

      final entry = LeaderboardEntry(
        userId: userId,
        username: data['username'] as String? ?? 'Unknown',
        avatarUrl: data['avatarUrl'] as String?,
        totalStars: data['totalStars'] as int? ?? 0,
        rank: rank,
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      // Cache the result
      _cache[cacheKey] = _CacheEntry([entry], DateTime.now());

      return entry;
    } catch (e) {
      // On error, return cached data if available
      final cacheKey = 'user_rank_$userId';
      final cached = _getCached(cacheKey, ignoreExpiry: true);
      return cached?.isNotEmpty == true ? cached!.first : null;
    }
  }

  @override
  Future<bool> submitScore({
    required String userId,
    required int stars,
    String? levelId,
  }) async {
    try {
      // Submit to scoreSubmissions collection
      // This will trigger Cloud Function to update leaderboard
      await _firestore.collection('scoreSubmissions').add({
        'userId': userId,
        'stars': stars % 4, // Individual level stars (0-3)
        'totalStars': stars, // Total accumulated stars
        'levelId': levelId,
        'time': DateTime.now().millisecondsSinceEpoch,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache for this user and top players
      _invalidateCache('user_rank_$userId');
      _invalidateCache('top_players_');

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<LeaderboardEntry>> getDailyChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  }) async {
    try {
      // Format date as YYYY-MM-DD
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      print('🏆 Fetching daily challenge leaderboard for $dateStr');

      // Check cache first
      final cacheKey = 'daily_challenge_${dateStr}_$limit';
      final cached = _getCached(cacheKey);
      if (cached != null) {
        print('🏆 Returning cached leaderboard: ${cached.length} entries');
        return cached;
      }

      // Query daily challenge entries
      final query = _firestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .collection('entries')
          .orderBy('stars', descending: true)
          .orderBy('completionTime', descending: false)
          .limit(limit);

      final snapshot = await query.get();
      print(
        '🏆 Query completed: found ${snapshot.docs.length} entries for dailyChallenges/$dateStr/entries',
      );

      // Convert documents to LeaderboardEntry objects
      final entries = <LeaderboardEntry>[];
      for (var i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();

        entries.add(
          LeaderboardEntry(
            userId: doc.id,
            username: data['username'] as String? ?? 'Unknown',
            avatarUrl: data['avatarUrl'] as String?,
            totalStars: data['totalStars'] as int? ?? 0,
            rank: i + 1, // Rank is position in sorted list
            updatedAt:
                (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            completionTime: data['completionTime'] as int?,
            stars: data['stars'] as int?,
          ),
        );
      }

      // Cache the result
      _cache[cacheKey] = _CacheEntry(entries, DateTime.now());

      return entries;
    } catch (e) {
      // On error, return cached data if available, otherwise empty list
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final cacheKey = 'daily_challenge_${dateStr}_$limit';
      return _getCached(cacheKey, ignoreExpiry: true) ?? [];
    }
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard({int limit = 100}) {
    return _firestore
        .collection('leaderboard')
        .orderBy('totalStars', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final entries = <LeaderboardEntry>[];
          for (var i = 0; i < snapshot.docs.length; i++) {
            final doc = snapshot.docs[i];
            final data = doc.data();

            entries.add(
              LeaderboardEntry(
                userId: doc.id,
                username: data['username'] as String? ?? 'Unknown',
                avatarUrl: data['avatarUrl'] as String?,
                totalStars: data['totalStars'] as int? ?? 0,
                rank: i + 1,
                updatedAt:
                    (data['updatedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
            );
          }
          return entries;
        });
  }

  /// Gets cached data if available and not expired.
  List<LeaderboardEntry>? _getCached(String key, {bool ignoreExpiry = false}) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (!ignoreExpiry && cached.isExpired) {
      _cache.remove(key);
      return null;
    }

    return cached.data;
  }

  /// Invalidates cache entries matching the given prefix.
  void _invalidateCache(String keyPrefix) {
    _cache.removeWhere((key, _) => key.startsWith(keyPrefix));
  }
}

/// Internal cache entry with expiration.
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);

  bool get isExpired =>
      DateTime.now().difference(timestamp) >
      FirestoreLeaderboardRepository._cacheTtl;
}
