import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logging/diagnostic_logger.dart';
import '../../core/logging/logger.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/daily_challenge_completion.dart';
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
      DiagnosticLogger.logEvent(
        'getTodaysChallenge called',
        data: {'date': today},
        level: LogLevel.info,
      );

      // Check cache first
      if (_cachedChallenge != null && _cachedChallengeDate == today) {
        DiagnosticLogger.logEvent(
          'Returning cached challenge',
          data: {'date': today},
          level: LogLevel.info,
        );
        return _cachedChallenge;
      }

      // Query Firestore
      DiagnosticLogger.logEvent(
        'Fetching from Firestore',
        data: {'path': 'dailyChallenges/$today'},
        level: LogLevel.info,
      );
      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(today)
          .get();

      DiagnosticLogger.logEvent(
        'Document query result',
        data: {'exists': doc.exists},
        level: LogLevel.info,
      );
      if (!doc.exists) {
        DiagnosticLogger.logEvent(
          'No daily challenge found',
          data: {'date': today},
          level: LogLevel.warn,
        );
        return null;
      }

      final data = doc.data()!;
      DiagnosticLogger.logEvent(
        'Raw data retrieved',
        data: {'keys': data.keys.toList()},
        level: LogLevel.info,
      );

      // Parse the level data
      final levelData = data['level'] as Map<String, dynamic>?;
      DiagnosticLogger.logEvent(
        'Level data check',
        data: {'present': levelData != null},
        level: LogLevel.info,
      );
      if (levelData == null) {
        DiagnosticLogger.logError(
          'Level data is null',
          error: Exception('Level data is null'),
          data: {'date': today},
        );
        return null;
      }

      DiagnosticLogger.logEvent(
        'Level data structure',
        data: {'keys': levelData.keys.toList()},
        level: LogLevel.info,
      );
      DiagnosticLogger.logEvent(
        'Parsing level from JSON',
        level: LogLevel.info,
      );
      final level = Level.fromJson(levelData);
      DiagnosticLogger.logEvent(
        'Level parsed successfully',
        data: {'id': level.id, 'size': level.size, 'cells': level.cells.length},
        level: LogLevel.info,
      );

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

      DiagnosticLogger.logEvent(
        'Daily challenge created successfully',
        data: {'id': today},
        level: LogLevel.info,
      );

      // Cache the result
      _cachedChallenge = challenge;
      _cachedChallengeDate = today;

      return challenge;
    } catch (e, stackTrace) {
      DiagnosticLogger.logError(
        'Error in getTodaysChallenge',
        error: e,
        stackTrace: stackTrace,
      );
      // On error, return cached data if available for today
      final today = _getTodayDateString();
      if (_cachedChallenge != null && _cachedChallengeDate == today) {
        DiagnosticLogger.logEvent(
          'Returning cached challenge after error',
          level: LogLevel.warn,
        );
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
      DiagnosticLogger.logEvent(
        'submitting_challenge_completion',
        data: {
          'date': today,
          'userId': userId,
          'stars': stars,
          'completionTimeMs': completionTimeMs,
        },
        level: LogLevel.info,
      );

      final entryRef = _firestore
          .collection('dailyChallenges')
          .doc(today)
          .collection('entries')
          .doc(userId);

      // Check if user has already completed this challenge
      final existingEntry = await entryRef.get();
      final isFirstCompletion = !existingEntry.exists;

      // If entry exists, check if this is an improvement
      if (existingEntry.exists) {
        final existingData = existingEntry.data()!;
        final existingStars = existingData['stars'] as int? ?? 0;
        final existingTime = existingData['completionTime'] as int? ?? 0;

        // Only update if this is a better score
        final isBetterStars = stars > existingStars;
        final isBetterTime =
            stars == existingStars && completionTimeMs < existingTime;

        if (!isBetterStars && !isBetterTime) {
          DiagnosticLogger.logEvent(
            'challenge_completion_not_improved',
            data: {
              'userId': userId,
              'existingStars': existingStars,
              'newStars': stars,
            },
            level: LogLevel.debug,
          );
          // Not an improvement, don't update
          return true;
        }
      }

      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        DiagnosticLogger.logEvent(
          'user_not_found_for_challenge',
          data: {'userId': userId},
          level: LogLevel.warn,
        );
        return false;
      }

      final userData = userDoc.data()!;
      final username = userData['displayName'] as String? ?? 'Unknown';
      final avatarUrl = userData['photoURL'] as String?;
      final totalStars = userData['totalStars'] as int? ?? 0;

      // Submit to daily challenge entries
      DiagnosticLogger.logEvent(
        'writing_challenge_entry',
        data: {
          'path': 'dailyChallenges/$today/entries/$userId',
          'username': username,
        },
        level: LogLevel.debug,
      );
      await entryRef.set({
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'totalStars': totalStars,
        'stars': stars,
        'completionTime': completionTimeMs,
        'completedAt': FieldValue.serverTimestamp(),
      });
      DiagnosticLogger.logEvent(
        'challenge_entry_written',
        data: {'userId': userId},
        level: LogLevel.debug,
      );

      // Only increment completion count if this is the first completion
      if (isFirstCompletion) {
        DiagnosticLogger.logEvent(
          'incrementing_completion_count',
          data: {'date': today, 'isFirstCompletion': true},
          level: LogLevel.debug,
        );
        await _firestore.collection('dailyChallenges').doc(today).update({
          'completionCount': FieldValue.increment(1),
        });
        DiagnosticLogger.logEvent(
          'completion_count_incremented',
          data: {'date': today},
          level: LogLevel.debug,
        );
      } else {
        DiagnosticLogger.logEvent(
          'skipping_completion_count',
          data: {'date': today, 'isFirstCompletion': false},
          level: LogLevel.debug,
        );
      }

      // Invalidate cache
      _cachedChallenge = null;
      _cachedChallengeDate = null;

      DiagnosticLogger.logEvent(
        'challenge_completion_submitted_successfully',
        data: {'userId': userId, 'date': today, 'stars': stars},
        level: LogLevel.info,
      );
      return true;
    } catch (e) {
      DiagnosticLogger.logError(
        'challenge_completion_submission_failed',
        error: e,
        data: {'userId': userId},
      );
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

  @override
  Future<DailyChallengeCompletion?> getCompletion({
    required String userId,
    required String dateId,
  }) async {
    try {
      DiagnosticLogger.logEvent(
        'getCompletion called',
        data: {'userId': userId, 'dateId': dateId},
        level: LogLevel.info,
      );

      final doc = await _firestore
          .collection('dailyChallenges')
          .doc(dateId)
          .collection('entries')
          .doc(userId)
          .get();

      if (!doc.exists) {
        DiagnosticLogger.logEvent(
          'No completion found',
          data: {'userId': userId, 'dateId': dateId},
          level: LogLevel.debug,
        );
        return null;
      }

      final data = doc.data()!;
      final completion = DailyChallengeCompletion(
        userId: userId,
        dateId: dateId,
        stars: data['stars'] as int? ?? 0,
        completionTimeMs: data['completionTime'] as int? ?? 0,
        completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        rank: data['rank'] as int?,
      );

      DiagnosticLogger.logEvent(
        'Completion found',
        data: {
          'userId': userId,
          'dateId': dateId,
          'stars': completion.stars,
          'time': completion.completionTimeMs,
        },
        level: LogLevel.info,
      );

      return completion;
    } catch (e, stackTrace) {
      DiagnosticLogger.logError(
        'Error in getCompletion',
        error: e,
        stackTrace: stackTrace,
        data: {'userId': userId, 'dateId': dateId},
      );
      return null;
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
