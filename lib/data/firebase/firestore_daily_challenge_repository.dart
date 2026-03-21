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

      final cached = _getCachedChallenge(today);
      if (cached != null) return cached;

      final data = await _fetchChallengeDoc(today);
      if (data == null) return null;

      final challenge = _parseChallengeData(today, data);
      if (challenge == null) return null;

      _cacheChallenge(challenge, today);
      return challenge;
    } catch (e, stackTrace) {
      DiagnosticLogger.logError(
        'Error in getTodaysChallenge',
        error: e,
        stackTrace: stackTrace,
      );
      return _fallbackToCachedChallenge();
    }
  }

  DailyChallenge? _getCachedChallenge(String today) {
    if (_cachedChallenge != null && _cachedChallengeDate == today) {
      DiagnosticLogger.logEvent(
        'Returning cached challenge',
        data: {'date': today},
        level: LogLevel.info,
      );
      return _cachedChallenge;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchChallengeDoc(String today) async {
    DiagnosticLogger.logEvent(
      'Fetching from Firestore',
      data: {'path': 'dailyChallenges/$today'},
      level: LogLevel.info,
    );
    final doc = await _firestore
        .collection('dailyChallenges')
        .doc(today)
        .get()
        .timeout(const Duration(seconds: 10));

    if (!doc.exists) {
      DiagnosticLogger.logEvent(
        'No daily challenge found',
        data: {'date': today},
        level: LogLevel.warn,
      );
      return null;
    }
    return doc.data()!;
  }

  DailyChallenge? _parseChallengeData(String today, Map<String, dynamic> data) {
    final levelData = data['level'] as Map<String, dynamic>?;
    if (levelData == null) {
      DiagnosticLogger.logError(
        'Level data is null',
        error: Exception('Level data is null'),
        data: {'date': today},
      );
      return null;
    }

    final level = Level.fromJson(levelData);
    DiagnosticLogger.logEvent(
      'Level parsed successfully',
      data: {'id': level.id, 'size': level.size, 'cells': level.cells.length},
      level: LogLevel.info,
    );

    return DailyChallenge(
      id: today,
      date: DateTime.parse(today),
      level: level,
      completionCount: data['completionCount'] as int? ?? 0,
      userBestTime: data['userBestTime'] as int?,
      userStars: data['userStars'] as int?,
      userRank: data['userRank'] as int?,
    );
  }

  void _cacheChallenge(DailyChallenge challenge, String today) {
    _cachedChallenge = challenge;
    _cachedChallengeDate = today;
    DiagnosticLogger.logEvent(
      'Daily challenge created successfully',
      data: {'id': today},
      level: LogLevel.info,
    );
  }

  DailyChallenge? _fallbackToCachedChallenge() {
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
        data: {'date': today, 'userId': userId, 'stars': stars},
        level: LogLevel.info,
      );

      final entryRef = _challengeEntryRef(today, userId);
      final existingEntry = await entryRef.get().timeout(const Duration(seconds: 10));

      // One-attempt-per-day: if entry exists, return success without writing.
      // Firestore security rules block updates to preserve completion integrity.
      if (existingEntry.exists) {
        DiagnosticLogger.logEvent(
          'challenge_entry_already_exists',
          data: {'userId': userId, 'date': today},
          level: LogLevel.info,
        );
        return true;
      }

      final userData = await _fetchUserData(userId);
      if (userData == null) return false;

      await _writeEntry(entryRef, userId, userData, stars, completionTimeMs);
      await _updateCompletionCount(today, isFirst: true);
      _invalidateCache();

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

  DocumentReference<Map<String, dynamic>> _challengeEntryRef(
    String dateStr,
    String userId,
  ) {
    return _firestore
        .collection('dailyChallenges')
        .doc(dateStr)
        .collection('entries')
        .doc(userId);
  }

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get().timeout(const Duration(seconds: 10));
    if (!doc.exists) {
      DiagnosticLogger.logEvent(
        'user_not_found_for_challenge',
        data: {'userId': userId},
        level: LogLevel.warn,
      );
      return null;
    }
    return doc.data();
  }

  Future<void> _writeEntry(
    DocumentReference<Map<String, dynamic>> ref,
    String userId,
    Map<String, dynamic> userData,
    int stars,
    int completionTimeMs,
  ) async {
    await ref.set({
      'userId': userId,
      'username': userData['displayName'] as String? ?? 'Unknown',
      'avatarUrl': userData['photoURL'] as String?,
      'totalStars': userData['totalStars'] as int? ?? 0,
      'stars': stars,
      'completionTime': completionTimeMs,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateCompletionCount(
    String dateStr, {
    required bool isFirst,
  }) async {
    if (!isFirst) return;
    await _firestore.collection('dailyChallenges').doc(dateStr).update({
      'completionCount': FieldValue.increment(1),
    });
  }

  void _invalidateCache() {
    _cachedChallenge = null;
    _cachedChallengeDate = null;
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

      final snapshot = await query.get().timeout(const Duration(seconds: 10));

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
          .get().timeout(const Duration(seconds: 10));

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
          .get().timeout(const Duration(seconds: 10));

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
        completedAt:
            (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
