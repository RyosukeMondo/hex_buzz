import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/daily_challenge.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/level.dart';
import '../../domain/services/daily_challenge_repository.dart';

/// Firestore implementation of [DailyChallengeRepository].
///
/// Implements daily challenge operations using Cloud Firestore with:
/// - Local caching for current day's challenge
/// - Automatic cache invalidation at midnight UTC
/// - Efficient queries for leaderboard rankings
/// - User completion status tracking
class FirestoreDailyChallengeRepository implements DailyChallengeRepository {
  final FirebaseFirestore _firestore;

  // Cache management
  DailyChallenge? _cachedChallenge;
  String? _cachedChallengeDate;

  FirestoreDailyChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DailyChallenge?> getTodaysChallenge() async {
    try {
      final today = _getTodayDateString();

      // Check cache first
      if (_cachedChallenge != null && _cachedChallengeDate == today) {
        return _cachedChallenge;
      }

      // Query Firestore
      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(today)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Parse the level data
      final levelData = data['level'] as Map<String, dynamic>?;
      if (levelData == null) {
        return null;
      }

      final level = Level.fromJson(levelData);

      // Create challenge object
      final challenge = DailyChallenge(
        id: today,
        date: DateTime.parse(today),
        level: level,
        completionCount: data['completionCount'] as int? ?? 0,
        userBestTime: data['userBestTime'] as int?,
        userStars: data['userStars'] as int?,
        userRank: data['userRank'] as int?,
      );

      // Cache the result
      _cachedChallenge = challenge;
      _cachedChallengeDate = today;

      return challenge;
    } catch (e) {
      // On error, return cached data if available for today
      final today = _getTodayDateString();
      if (_cachedChallenge != null && _cachedChallengeDate == today) {
        return _cachedChallenge;
      }
      return null;
    }
  }

  @override
  Future<bool> submitChallengeCompletion({
    required String userId,
    required int stars,
    required int completionTimeMs,
  }) async {
    try {
      final today = _getTodayDateString();

      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      final username = userData['displayName'] as String? ?? 'Unknown';
      final avatarUrl = userData['photoURL'] as String?;
      final totalStars = userData['totalStars'] as int? ?? 0;

      // Submit to daily challenge entries
      await _firestore
          .collection('dailyChallenges')
          .doc(today)
          .collection('entries')
          .doc(userId)
          .set({
            'userId': userId,
            'username': username,
            'avatarUrl': avatarUrl,
            'totalStars': totalStars,
            'stars': stars,
            'completionTime': completionTimeMs,
            'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Increment completion count
      await _firestore.collection('dailyChallenges').doc(today).update({
        'completionCount': FieldValue.increment(1),
      });

      // Invalidate cache
      _cachedChallenge = null;
      _cachedChallengeDate = null;

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<LeaderboardEntry>> getChallengeLeaderboard({
    required DateTime date,
    int limit = 100,
  }) async {
    try {
      final dateStr = _formatDate(date);

      // Query daily challenge entries
      final query = _firestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .collection('entries')
          .orderBy('stars', descending: true)
          .orderBy('completionTime', descending: false)
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
            rank: i + 1, // Rank is position in sorted list
            updatedAt:
                (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            completionTime: data['completionTime'] as int?,
            stars: data['stars'] as int?,
          ),
        );
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> hasCompletedToday(String userId) async {
    try {
      final today = _getTodayDateString();

      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(today)
          .collection('entries')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Gets today's date as a string in YYYY-MM-DD format (UTC).
  String _getTodayDateString() {
    final now = DateTime.now().toUtc();
    return _formatDate(now);
  }

  /// Formats a date as YYYY-MM-DD.
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
