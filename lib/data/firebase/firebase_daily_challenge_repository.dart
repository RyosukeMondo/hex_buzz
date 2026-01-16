import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/daily_challenge.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/level.dart';
import '../../domain/services/daily_challenge_repository.dart';

/// Firebase implementation of [DailyChallengeRepository] using Firestore.
///
/// Manages daily challenges in Firestore with automatic challenge generation,
/// completion tracking, and leaderboard integration. Each challenge is stored
/// as a document with a date-based ID and contains level data and completion stats.
class FirebaseDailyChallengeRepository implements DailyChallengeRepository {
  final FirebaseFirestore _firestore;

  FirebaseDailyChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<DailyChallenge?> getTodaysChallenge() async {
    try {
      final today = DateTime.now().toUtc();
      final dateStr = _formatDate(today);

      final docRef = _firestore.collection('dailyChallenges').doc(dateStr);
      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;

      // Extract level data
      final levelData = data['level'] as Map<String, dynamic>?;
      if (levelData == null) {
        return null;
      }

      final level = Level.fromJson(levelData);
      final completionCount = data['completionCount'] as int? ?? 0;

      return DailyChallenge(
        id: dateStr,
        date: today,
        level: level,
        completionCount: completionCount,
      );
    } catch (e) {
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
      final today = DateTime.now().toUtc();
      final dateStr = _formatDate(today);

      final challengeRef = _firestore
          .collection('dailyChallenges')
          .doc(dateStr);
      final completionRef = challengeRef.collection('completions').doc(userId);

      // Use a batch to ensure atomicity
      final batch = _firestore.batch();

      // Check if user already has a completion
      final existingCompletion = await completionRef.get();

      if (existingCompletion.exists) {
        final existingData = existingCompletion.data()!;
        final existingStars = existingData['stars'] as int? ?? 0;
        final existingTime = existingData['completionTimeMs'] as int? ?? 0;

        // Only update if this is a better score (more stars or same stars with faster time)
        if (stars > existingStars ||
            (stars == existingStars && completionTimeMs < existingTime)) {
          batch.update(completionRef, {
            'stars': stars,
            'completionTimeMs': completionTimeMs,
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // First completion for this user
        batch.set(completionRef, {
          'userId': userId,
          'stars': stars,
          'completionTimeMs': completionTimeMs,
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Increment completion count
        batch.update(challengeRef, {
          'completionCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
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

      final snapshot = await _firestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .collection('completions')
          .orderBy('stars', descending: true)
          .orderBy('completionTimeMs', descending: false)
          .limit(limit)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Fetch user data for display name and photo
          final userId = data['userId'] as String;
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          final userData = userDoc.data();

          final entry = LeaderboardEntry(
            rank: rank,
            userId: userId,
            username: userData?['username'] ?? 'Anonymous',
            avatarUrl: userData?['photoURL'],
            totalStars: data['stars'] as int,
            updatedAt:
                (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          entries.add(entry);
          rank++;
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> hasCompletedToday(String userId) async {
    try {
      final today = DateTime.now().toUtc();
      final dateStr = _formatDate(today);

      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .collection('completions')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Formats a DateTime as YYYY-MM-DD for consistent date storage.
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
