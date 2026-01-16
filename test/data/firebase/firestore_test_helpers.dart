import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';

/// Helper functions for Firestore repository tests.

/// Creates a sample level for testing.
Level createSampleLevel() {
  return Level(
    id: 'test-level',
    size: 4,
    cells: {
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
      (0, 1): const HexCell(q: 0, r: 1),
    },
    walls: {},
    checkpointCount: 2,
  );
}

/// Gets today's date string in YYYY-MM-DD format (UTC).
String getTodayDateString() {
  final now = DateTime.now().toUtc();
  return formatDate(now);
}

/// Formats a date as YYYY-MM-DD.
String formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Creates a user document in Firestore for testing.
Future<void> createTestUser(
  FakeFirebaseFirestore firestore,
  String userId, {
  String? displayName,
  String? photoURL,
  int totalStars = 100,
}) async {
  await firestore.collection('users').doc(userId).set({
    'displayName': displayName ?? 'Test User',
    if (photoURL != null) 'photoURL': photoURL,
    'totalStars': totalStars,
  });
}

/// Creates a daily challenge document in Firestore for testing.
Future<void> createDailyChallenge(
  FakeFirebaseFirestore firestore,
  String dateStr, {
  Level? level,
  int completionCount = 0,
}) async {
  final data = <String, dynamic>{
    'completionCount': completionCount,
    'createdAt': Timestamp.fromDate(DateTime.now()),
  };

  if (level != null) {
    data['level'] = level.toJson();
  }

  await firestore.collection('dailyChallenges').doc(dateStr).set(data);
}

/// Creates a daily challenge entry in Firestore for testing.
Future<void> createChallengeEntry(
  FakeFirebaseFirestore firestore,
  String dateStr,
  String userId, {
  required int stars,
  required int completionTime,
  String? username,
  String? avatarUrl,
  int totalStars = 100,
}) async {
  await firestore
      .collection('dailyChallenges')
      .doc(dateStr)
      .collection('entries')
      .doc(userId)
      .set({
        'userId': userId,
        'username': username ?? 'Test User',
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'totalStars': totalStars,
        'stars': stars,
        'completionTime': completionTime,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
}
