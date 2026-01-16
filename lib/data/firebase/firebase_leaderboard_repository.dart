import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_repository.dart';

/// Firebase implementation of [LeaderboardRepository] using Firestore.
///
/// Stores leaderboard data in Firestore with automatic ranking computation
/// and real-time updates. Optimized for read-heavy workloads with cached
/// rankings and efficient pagination.
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<LeaderboardEntry>> getTopPlayers({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final query = _firestore
          .collection('leaderboard')
          .orderBy('totalStars', descending: true)
          .orderBy('updatedAt', descending: false)
          .limit(limit);

      QuerySnapshot snapshot;
      if (offset > 0) {
        // For pagination, we need to skip documents
        final skipSnapshot = await _firestore
            .collection('leaderboard')
            .orderBy('totalStars', descending: true)
            .orderBy('lastUpdated', descending: false)
            .limit(offset)
            .get();

        if (skipSnapshot.docs.isEmpty) {
          return [];
        }

        final lastDoc = skipSnapshot.docs.last;
        snapshot = await query.startAfterDocument(lastDoc).get();
      } else {
        snapshot = await query.get();
      }

      final entries = <LeaderboardEntry>[];
      int rank = offset + 1;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final entry = LeaderboardEntry.fromJson({...data, 'rank': rank});
          entries.add(entry);
          rank++;
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      return entries;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  @override
  Future<LeaderboardEntry?> getUserRank(String userId) async {
    try {
      // Get user's leaderboard entry
      final userDoc = await _firestore
          .collection('leaderboard')
          .doc(userId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        return null;
      }

      final userData = userDoc.data()!;
      final userStars = userData['totalStars'] as int? ?? 0;

      // Calculate rank by counting users with more stars
      final higherRankCount = await _firestore
          .collection('leaderboard')
          .where('totalStars', isGreaterThan: userStars)
          .count()
          .get();

      final rank = (higherRankCount.count ?? 0) + 1;

      return LeaderboardEntry.fromJson({...userData, 'rank': rank});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> submitScore({
    required String userId,
    required int stars,
    String? levelId,
  }) async {
    try {
      final docRef = _firestore.collection('leaderboard').doc(userId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        // Update existing entry if new score is higher
        final currentStars = doc.data()!['totalStars'] as int? ?? 0;
        if (stars > currentStars) {
          await docRef.update({
            'totalStars': stars,
            'updatedAt': FieldValue.serverTimestamp(),
            if (levelId != null) 'lastLevel': levelId,
          });
        }
      } else {
        // Create new leaderboard entry
        // Note: We'll need to fetch user data from users collection
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();

        await docRef.set({
          'userId': userId,
          'username': userData?['username'] ?? 'Anonymous',
          'avatarUrl': userData?['photoURL'],
          'totalStars': stars,
          'updatedAt': FieldValue.serverTimestamp(),
          if (levelId != null) 'lastLevel': levelId,
        });
      }

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
      // Format date as YYYY-MM-DD for consistent storage
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
  Stream<List<LeaderboardEntry>> watchLeaderboard({int limit = 100}) {
    return _firestore
        .collection('leaderboard')
        .orderBy('totalStars', descending: true)
        .orderBy('updatedAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final entries = <LeaderboardEntry>[];
          int rank = 1;

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final entry = LeaderboardEntry.fromJson({...data, 'rank': rank});
              entries.add(entry);
              rank++;
            } catch (e) {
              // Skip invalid entries
              continue;
            }
          }

          return entries;
        });
  }

  /// Formats a DateTime as YYYY-MM-DD for consistent date storage.
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
