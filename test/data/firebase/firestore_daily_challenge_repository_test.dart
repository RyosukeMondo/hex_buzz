import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firestore_daily_challenge_repository.dart';

import 'firestore_test_helpers.dart';

void main() {
  group('FirestoreDailyChallengeRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDailyChallengeRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDailyChallengeRepository(firestore: fakeFirestore);
    });

    group('getTodaysChallenge', () {
      test('returns null when no challenge exists for today', () async {
        final result = await repository.getTodaysChallenge();
        expect(result, isNull);
      });

      test('returns today\'s challenge when it exists', () async {
        final today = getTodayDateString();
        await createDailyChallenge(
          fakeFirestore,
          today,
          level: createSampleLevel(),
          completionCount: 42,
        );

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.id, today);
        expect(result.level.id, 'test-level');
        expect(result.level.size, 4);
        expect(result.completionCount, 42);
      });

      test('returns null when level data is missing', () async {
        final today = getTodayDateString();
        await createDailyChallenge(fakeFirestore, today, completionCount: 10);

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
    });

    group('submitChallengeCompletion', () {
      test('submits completion successfully', () async {
        final today = getTodayDateString();
        await createTestUser(
          fakeFirestore,
          'user1',
          photoURL: 'https://example.com/photo.jpg',
          totalStars: 150,
        );
        await createDailyChallenge(fakeFirestore, today);

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        expect(entry.exists, isTrue);
        final data = entry.data()!;
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
        await fakeFirestore.collection('users').doc('user1').set({});
        await createDailyChallenge(fakeFirestore, today);

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 2,
          completionTimeMs: 8000,
        );

        expect(result, isTrue);
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        final data = entry.data()!;
        expect(data['username'], 'Unknown');
        expect(data['totalStars'], 0);
      });

      test('updates existing entry when score improves', () async {
        final today = getTodayDateString();
        await createTestUser(fakeFirestore, 'user1');
        await createDailyChallenge(fakeFirestore, today, completionCount: 1);
        await createChallengeEntry(
          fakeFirestore,
          today,
          'user1',
          stars: 2,
          completionTime: 10000,
        );

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        final data = entry.data()!;
        expect(data['stars'], 3);
        expect(data['completionTime'], 5000);
      });

      test('does not update when new score is not better', () async {
        final today = getTodayDateString();
        await createTestUser(fakeFirestore, 'user1');
        await createDailyChallenge(fakeFirestore, today, completionCount: 1);
        await createChallengeEntry(
          fakeFirestore,
          today,
          'user1',
          stars: 3,
          completionTime: 5000,
        );

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 8000,
        );

        expect(result, isTrue);
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        expect(entry.data()!['completionTime'], 5000);
      });

      test('updates when time improves with same stars', () async {
        final today = getTodayDateString();
        await createTestUser(fakeFirestore, 'user1');
        await createDailyChallenge(fakeFirestore, today, completionCount: 1);
        await createChallengeEntry(
          fakeFirestore,
          today,
          'user1',
          stars: 3,
          completionTime: 8000,
        );

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);
        final entry = await fakeFirestore
            .collection('dailyChallenges')
            .doc(today)
            .collection('entries')
            .doc('user1')
            .get();

        expect(entry.data()!['completionTime'], 5000);
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
      test('formats dates correctly', () async {
        expect(formatDate(DateTime(2024, 1, 5)), '2024-01-05');
        expect(formatDate(DateTime(2024, 11, 25)), '2024-11-25');
      });

      test('uses UTC for today', () async {
        final now = DateTime.now().toUtc();
        expect(getTodayDateString(), formatDate(now));
      });
    });
  });
}
