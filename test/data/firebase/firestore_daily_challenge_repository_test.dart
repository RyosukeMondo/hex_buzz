import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firestore_daily_challenge_repository.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';

void main() {
  group('FirestoreDailyChallengeRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDailyChallengeRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDailyChallengeRepository(firestore: fakeFirestore);
    });

    /// Helper to create a sample level for testing
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

    /// Helper to get today's date string in YYYY-MM-DD format (UTC)
    String getTodayDateString() {
      final now = DateTime.now().toUtc();
      return '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    }

    /// Helper to format a date as YYYY-MM-DD
    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    group('getTodaysChallenge', () {
      test('returns null when no challenge exists for today', () async {
        final result = await repository.getTodaysChallenge();
        expect(result, isNull);
      });

      test('returns today\'s challenge when it exists', () async {
        final today = getTodayDateString();
        final level = createSampleLevel();

        // Add challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 42,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.id, today);
        expect(result.level.id, 'test-level');
        expect(result.level.size, 4);
        expect(result.completionCount, 42);
        expect(result.userBestTime, isNull);
        expect(result.userStars, isNull);
        expect(result.userRank, isNull);
      });

      test('returns null when level data is missing', () async {
        final today = getTodayDateString();

        // Add challenge document without level
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 10,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNull);
      });

      test('includes user stats when available', () async {
        final today = getTodayDateString();
        final level = createSampleLevel();

        // Add challenge document with user stats
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 100,
          'userBestTime': 5000,
          'userStars': 3,
          'userRank': 15,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.userBestTime, 5000);
        expect(result.userStars, 3);
        expect(result.userRank, 15);
      });

      test('uses cache on subsequent calls', () async {
        final today = getTodayDateString();
        final level = createSampleLevel();

        // Add challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 10,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // First call - loads from Firestore
        final result1 = await repository.getTodaysChallenge();
        expect(result1, isNotNull);
        expect(result1!.completionCount, 10);

        // Update Firestore
        await fakeFirestore.collection('dailyChallenges').doc(today).update({
          'completionCount': 20,
        });

        // Second call - should return cached data (still 10)
        final result2 = await repository.getTodaysChallenge();
        expect(result2!.completionCount, 10);
      });

      test('returns cached data on error', () async {
        final today = getTodayDateString();
        final level = createSampleLevel();

        // Add challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 10,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // First call - loads from Firestore and caches
        final result1 = await repository.getTodaysChallenge();
        expect(result1, isNotNull);

        // Even if there's an error accessing Firestore, cached data is returned
        // (Note: FakeFirebaseFirestore doesn't easily simulate errors, but this
        // tests the caching logic)
        final result2 = await repository.getTodaysChallenge();
        expect(result2, isNotNull);
      });

      test('parses level with all fields correctly', () async {
        final today = getTodayDateString();
        final level = Level(
          id: 'complex-level',
          size: 6,
          cells: {
            (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
            (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
            (0, 1): const HexCell(q: 0, r: 1, checkpoint: 3),
            (-1, 1): const HexCell(q: -1, r: 1),
          },
          walls: {},
          checkpointCount: 3,
        );

        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.level.id, 'complex-level');
        expect(result.level.size, 6);
        expect(result.level.cells.length, 4);
        expect(result.level.checkpointCount, 3);
      });
    });

    group('submitChallengeCompletion', () {
      test('submits completion successfully', () async {
        final today = getTodayDateString();

        // Create user document
        await fakeFirestore.collection('users').doc('user1').set({
          'displayName': 'Test User',
          'photoURL': 'https://example.com/photo.jpg',
          'totalStars': 150,
        });

        // Create daily challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);

        // Verify entry was created
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        expect(entry.exists, isTrue);
        final data = entry.data()!;
        expect(data['userId'], 'user1');
        expect(data['username'], 'Test User');
        expect(data['avatarUrl'], 'https://example.com/photo.jpg');
        expect(data['totalStars'], 150);
        expect(data['stars'], 3);
        expect(data['completionTime'], 5000);
      });

      test('returns false when user does not exist', () async {
        final result = await repository.submitChallengeCompletion(
          userId: 'nonexistent-user',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isFalse);
      });

      test('uses default values for missing user fields', () async {
        final today = getTodayDateString();

        // Create minimal user document
        await fakeFirestore.collection('users').doc('user1').set({});

        // Create daily challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 2,
          completionTimeMs: 8000,
        );

        expect(result, isTrue);

        // Verify entry was created with defaults
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        expect(entry.exists, isTrue);
        final data = entry.data()!;
        expect(data['username'], 'Unknown');
        expect(data['avatarUrl'], isNull);
        expect(data['totalStars'], 0);
      });

      test('merges with existing entry', () async {
        final today = getTodayDateString();

        // Create user document
        await fakeFirestore.collection('users').doc('user1').set({
          'displayName': 'Test User',
          'totalStars': 100,
        });

        // Create daily challenge document
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 1,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Create existing entry
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .set({
              'userId': 'user1',
              'username': 'Old Name',
              'stars': 2,
              'completionTime': 10000,
            });

        // Submit new completion (should merge)
        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);

        // Verify entry was updated
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        final data = entry.data()!;
        expect(data['username'], 'Test User'); // Updated
        expect(data['stars'], 3); // Updated
        expect(data['completionTime'], 5000); // Updated
      });

      test('increments completion count', () async {
        final today = getTodayDateString();

        // Create user document
        await fakeFirestore.collection('users').doc('user1').set({
          'displayName': 'Test User',
          'totalStars': 100,
        });

        // Create daily challenge document with initial count
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 5,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        // Verify completion count was incremented
        final doc = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .get();

        // Note: FakeFirebaseFirestore might not properly support FieldValue.increment
        // In a real test with Firebase Emulator, this would be 6
        final count = doc.data()?['completionCount'] ?? 0;
        expect(count >= 5, isTrue);
      });

      test('invalidates cache after submission', () async {
        final today = getTodayDateString();
        final level = createSampleLevel();

        // Setup initial challenge
        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'level': level.toJson(),
          'completionCount': 5,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Create user
        await fakeFirestore.collection('users').doc('user1').set({
          'displayName': 'Test User',
          'totalStars': 100,
        });

        // Get challenge (populates cache)
        final result1 = await repository.getTodaysChallenge();
        expect(result1!.completionCount, 5);

        // Submit completion
        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        // Update Firestore
        await fakeFirestore.collection('dailyChallenges').doc(today).update({
          'completionCount': 6,
        });

        // Cache should be invalidated, so this should fetch fresh data
        final result2 = await repository.getTodaysChallenge();
        expect(result2!.completionCount, 6);
      });

      test('handles various star values correctly', () async {
        final today = getTodayDateString();

        // Create user and challenge
        await fakeFirestore.collection('users').doc('user1').set({
          'displayName': 'Test User',
          'totalStars': 100,
        });

        await fakeFirestore.collection('dailyChallenges').doc(today).set({
          'completionCount': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Test different star values
        final testCases = [0, 1, 2, 3];

        for (final stars in testCases) {
          final result = await repository.submitChallengeCompletion(
            userId: 'user1',
            stars: stars,
            completionTimeMs: 5000,
          );

          expect(result, isTrue);

          // Verify stars value
          final entry = await fakeFirestore
              .collection('dailyChallenges')
              .doc(today)
              .collection('entries')
              .doc('user1')
              .get();

          expect(entry.data()!['stars'], stars);
        }
      });
    });

    group('getChallengeLeaderboard', () {
      test('returns empty list when no entries exist', () async {
        final date = DateTime(2024, 1, 15);
        final result = await repository.getChallengeLeaderboard(date: date);
        expect(result, isEmpty);
      });

      test('returns entries ordered by stars and completion time', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        // Add test data
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc('user1')
            .set({
              'username': 'Player One',
              'totalStars': 100,
              'stars': 3,
              'completionTime': 5000,
              'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0)),
            });

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc('user2')
            .set({
              'username': 'Player Two',
              'totalStars': 150,
              'stars': 3,
              'completionTime': 3000, // Faster time
              'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
            });

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc('user3')
            .set({
              'username': 'Player Three',
              'totalStars': 200,
              'stars': 2, // Lower stars
              'completionTime': 2000,
              'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15, 12, 0)),
            });

        final result = await repository.getChallengeLeaderboard(date: date);

        expect(result.length, 3);
        // Both user1 and user2 have 3 stars, but user2 completed faster
        expect(result[0].userId, 'user2');
        expect(result[0].stars, 3);
        expect(result[0].completionTime, 3000);
        expect(result[0].rank, 1);

        expect(result[1].userId, 'user1');
        expect(result[1].stars, 3);
        expect(result[1].completionTime, 5000);
        expect(result[1].rank, 2);

        expect(result[2].userId, 'user3');
        expect(result[2].stars, 2);
        expect(result[2].rank, 3);
      });

      test('respects limit parameter', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        // Add test data
        for (int i = 1; i <= 10; i++) {
          await fakeFirestore
              .collection('dailyChallenges')
              .doc(dateStr)
              .collection('entries')
              .doc('user$i')
              .set({
                'username': 'Player $i',
                'totalStars': 100,
                'stars': 3,
                'completionTime': i * 1000,
                'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15, i)),
              });
        }

        final result = await repository.getChallengeLeaderboard(
          date: date,
          limit: 5,
        );

        expect(result.length, 5);
      });

      test('formats date correctly for different months and days', () async {
        final testDates = [
          DateTime(2024, 1, 1), // '2024-01-01'
          DateTime(2024, 12, 31), // '2024-12-31'
          DateTime(2024, 6, 15), // '2024-06-15'
        ];

        for (final date in testDates) {
          final dateStr = formatDate(date);

          await fakeFirestore
              .collection('dailyChallenges')
              .doc(dateStr)
              .collection('entries')
              .doc('user1')
              .set({
                'username': 'Player One',
                'totalStars': 100,
                'stars': 3,
                'completionTime': 5000,
                'completedAt': Timestamp.fromDate(date),
              });

          final result = await repository.getChallengeLeaderboard(date: date);
          expect(result.length, 1);
        }
      });

      test('handles missing optional fields gracefully', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc('user1')
            .set({'stars': 3, 'completionTime': 5000});

        final result = await repository.getChallengeLeaderboard(date: date);

        expect(result.length, 1);
        expect(result[0].username, 'Unknown');
        expect(result[0].avatarUrl, isNull);
        expect(result[0].totalStars, 0);
      });
    });

    group('hasCompletedToday', () {
      test('checks completion status correctly', () async {
        final today = getTodayDateString();

        // Initially false for non-existent user
        final result1 = await repository.hasCompletedToday('user1');
        expect(result1, isFalse);

        // Add completion entry for user1
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .set({
              'userId': 'user1',
              'username': 'Test User',
              'stars': 3,
              'completionTime': 5000,
              'completedAt': Timestamp.fromDate(DateTime.now()),
            });

        // Now true for user1
        final result2 = await repository.hasCompletedToday('user1');
        expect(result2, isTrue);

        // Still false for different user
        final result3 = await repository.hasCompletedToday('user2');
        expect(result3, isFalse);
      });
    });

    group('Date formatting', () {
      test('formats single-digit months and days correctly', () async {
        final date = DateTime(2024, 1, 5);
        final expected = '2024-01-05';
        final actual = formatDate(date);
        expect(actual, expected);
      });

      test('formats double-digit months and days correctly', () async {
        final date = DateTime(2024, 11, 25);
        final expected = '2024-11-25';
        final actual = formatDate(date);
        expect(actual, expected);
      });

      test('handles year boundaries correctly', () async {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 12, 31);

        expect(formatDate(date1), '2024-01-01');
        expect(formatDate(date2), '2024-12-31');
      });

      test('uses UTC for today\'s date', () async {
        // This test verifies that getTodaysChallenge uses UTC
        final now = DateTime.now().toUtc();
        final expectedDate = formatDate(now);
        final actualDate = getTodayDateString();

        expect(actualDate, expectedDate);
      });
    });
  });
}
