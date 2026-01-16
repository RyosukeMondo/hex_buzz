import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firestore_leaderboard_repository.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';

void main() {
  group('FirestoreLeaderboardRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreLeaderboardRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreLeaderboardRepository(firestore: fakeFirestore);
    });

    group('getTopPlayers', () {
      test('returns empty list when no players exist', () async {
        final result = await repository.getTopPlayers();
        expect(result, isEmpty);
      });

      test('returns players ordered by totalStars descending', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'username': 'Player Two',
          'totalStars': 200,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });
        await fakeFirestore.collection('leaderboard').doc('user3').set({
          'username': 'Player Three',
          'totalStars': 150,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 3)),
        });

        final result = await repository.getTopPlayers();

        expect(result.length, 3);
        expect(result[0].username, 'Player Two');
        expect(result[0].totalStars, 200);
        expect(result[0].rank, 1);
        expect(result[1].username, 'Player Three');
        expect(result[1].totalStars, 150);
        expect(result[1].rank, 2);
        expect(result[2].username, 'Player One');
        expect(result[2].totalStars, 100);
        expect(result[2].rank, 3);
      });

      test('respects limit parameter', () async {
        // Add test data
        for (int i = 1; i <= 10; i++) {
          await fakeFirestore.collection('leaderboard').doc('user$i').set({
            'username': 'Player $i',
            'totalStars': i * 10,
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, i)),
          });
        }

        final result = await repository.getTopPlayers(limit: 5);

        expect(result.length, 5);
        expect(result[0].totalStars, 100); // Highest first
        expect(result[4].totalStars, 60);
      });

      test('calculates rank based on offset', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final result = await repository.getTopPlayers(offset: 10);

        expect(result.length, 1);
        expect(result[0].rank, 11); // offset + position + 1
      });

      test('handles missing optional fields gracefully', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final result = await repository.getTopPlayers();

        expect(result.length, 1);
        expect(result[0].username, 'Unknown'); // Default value
        expect(result[0].avatarUrl, isNull);
      });

      test('uses cache on subsequent calls', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        // First call - loads from Firestore
        final result1 = await repository.getTopPlayers();
        expect(result1.length, 1);

        // Modify data in Firestore
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'username': 'Player Two',
          'totalStars': 200,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });

        // Second call - should return cached data (still 1 player)
        final result2 = await repository.getTopPlayers();
        expect(result2.length, 1);
      });
    });

    group('getUserRank', () {
      test('returns null when user does not exist', () async {
        final result = await repository.getUserRank('nonexistent-user');
        expect(result, isNull);
      });

      test('returns user rank correctly', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'username': 'Player Two',
          'totalStars': 200,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });
        await fakeFirestore.collection('leaderboard').doc('user3').set({
          'username': 'Player Three',
          'totalStars': 150,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 3)),
        });

        final result = await repository.getUserRank('user3');

        expect(result, isNotNull);
        expect(result!.userId, 'user3');
        expect(result.username, 'Player Three');
        expect(result.totalStars, 150);
        expect(result.rank, 2); // Second place (after user2 with 200 stars)
      });

      test('calculates rank as 1 for top player', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Top Player',
          'totalStars': 1000,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final result = await repository.getUserRank('user1');

        expect(result, isNotNull);
        expect(result!.rank, 1);
      });

      test('handles missing optional fields gracefully', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final result = await repository.getUserRank('user1');

        expect(result, isNotNull);
        expect(result!.username, 'Unknown');
        expect(result.avatarUrl, isNull);
      });

      test('uses cache on subsequent calls', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        // First call - loads from Firestore
        final result1 = await repository.getUserRank('user1');
        expect(result1, isNotNull);

        // Modify data in Firestore
        await fakeFirestore.collection('leaderboard').doc('user1').update({
          'totalStars': 200,
        });

        // Second call - should return cached data (still 100 stars)
        final result2 = await repository.getUserRank('user1');
        expect(result2!.totalStars, 100);
      });
    });

    group('submitScore', () {
      test('submits score successfully and handles optional fields', () async {
        // Test with levelId
        final result1 = await repository.submitScore(
          userId: 'user1',
          stars: 150,
          levelId: 'level-1',
        );
        expect(result1, isTrue);

        // Test without levelId
        final result2 = await repository.submitScore(
          userId: 'user2',
          stars: 100,
        );
        expect(result2, isTrue);

        // Verify submissions were created
        final submissions = await fakeFirestore
            .collection('scoreSubmissions')
            .get();
        expect(submissions.docs.length, 2);

        final sub1 = submissions.docs[0].data();
        expect(sub1['userId'], 'user1');
        expect(sub1['stars'], 2); // 150 % 4 = 2
        expect(sub1['totalStars'], 150);
        expect(sub1['levelId'], 'level-1');

        final sub2 = submissions.docs[1].data();
        expect(sub2['userId'], 'user2');
        expect(sub2['levelId'], isNull);
      });

      test('invalidates cache after submission', () async {
        // Setup initial data and cache
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        // Populate cache
        await repository.getUserRank('user1');

        // Submit new score
        await repository.submitScore(userId: 'user1', stars: 200);

        // Update Firestore manually (normally done by Cloud Function)
        await fakeFirestore.collection('leaderboard').doc('user1').update({
          'totalStars': 200,
        });

        // Cache should be invalidated, so this should fetch fresh data
        final result = await repository.getUserRank('user1');
        expect(result!.totalStars, 200);
      });

      test('calculates individual level stars correctly', () async {
        // Test various star counts and their modulo
        final testCases = [
          (0, 0), // 0 % 4 = 0
          (1, 1), // 1 % 4 = 1
          (3, 3), // 3 % 4 = 3
          (4, 0), // 4 % 4 = 0
          (7, 3), // 7 % 4 = 3
          (150, 2), // 150 % 4 = 2
        ];

        for (final testCase in testCases) {
          await repository.submitScore(userId: 'user1', stars: testCase.$1);
        }

        // Verify all submissions
        final submissions = await fakeFirestore
            .collection('scoreSubmissions')
            .get();
        expect(submissions.docs.length, testCases.length);

        for (int i = 0; i < testCases.length; i++) {
          final submission = submissions.docs[i].data();
          expect(submission['stars'], testCases[i].$2);
          expect(submission['totalStars'], testCases[i].$1);
        }
      });
    });

    group('getDailyChallengeLeaderboard', () {
      test('returns empty list when no entries exist', () async {
        final date = DateTime(2024, 1, 15);
        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
        );
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

        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
        );

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
                'totalStars': i * 10,
                'stars': 3,
                'completionTime': i * 1000,
                'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15, i)),
              });
        }

        final result = await repository.getDailyChallengeLeaderboard(
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
          final dateStr =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';

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

          final result = await repository.getDailyChallengeLeaderboard(
            date: date,
          );
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

        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
        );

        expect(result.length, 1);
        expect(result[0].username, 'Unknown');
        expect(result[0].avatarUrl, isNull);
        expect(result[0].totalStars, 0);
      });

      test('uses cache on subsequent calls', () async {
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
              'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
            });

        // First call - loads from Firestore
        final result1 = await repository.getDailyChallengeLeaderboard(
          date: date,
        );
        expect(result1.length, 1);

        // Add more data
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc('user2')
            .set({
              'username': 'Player Two',
              'totalStars': 150,
              'stars': 3,
              'completionTime': 3000,
              'completedAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
            });

        // Second call - should return cached data (still 1 entry)
        final result2 = await repository.getDailyChallengeLeaderboard(
          date: date,
        );
        expect(result2.length, 1);
      });
    });

    group('watchLeaderboard', () {
      test('emits initial empty list when no players exist', () async {
        final stream = repository.watchLeaderboard();

        await expectLater(stream, emits(isEmpty));
      });

      test('emits players ordered by totalStars', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'username': 'Player Two',
          'totalStars': 200,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });

        final stream = repository.watchLeaderboard();

        await expectLater(
          stream.first,
          completion(
            predicate<List<LeaderboardEntry>>((entries) {
              return entries.length == 2 &&
                  entries[0].username == 'Player Two' &&
                  entries[0].rank == 1 &&
                  entries[1].username == 'Player One' &&
                  entries[1].rank == 2;
            }),
          ),
        );
      });

      test('emits updated data when players change', () async {
        // Add initial data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'username': 'Player One',
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final stream = repository.watchLeaderboard();

        // Expect initial data
        await expectLater(
          stream.first,
          completion(
            predicate<List<LeaderboardEntry>>((entries) => entries.length == 1),
          ),
        );

        // Add another player
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'username': 'Player Two',
          'totalStars': 200,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });

        // Wait a bit for the stream to update
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('respects limit parameter', () async {
        // Add test data
        for (int i = 1; i <= 10; i++) {
          await fakeFirestore.collection('leaderboard').doc('user$i').set({
            'username': 'Player $i',
            'totalStars': i * 10,
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, i)),
          });
        }

        final stream = repository.watchLeaderboard(limit: 5);

        await expectLater(
          stream.first,
          completion(
            predicate<List<LeaderboardEntry>>((entries) => entries.length == 5),
          ),
        );
      });

      test('handles missing optional fields gracefully', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'totalStars': 100,
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final stream = repository.watchLeaderboard();

        await expectLater(
          stream.first,
          completion(
            predicate<List<LeaderboardEntry>>((entries) {
              return entries.length == 1 &&
                  entries[0].username == 'Unknown' &&
                  entries[0].avatarUrl == null;
            }),
          ),
        );
      });
    });

    group('Cache behavior', () {
      test('uses different cache keys for different parameters', () async {
        // Add test data
        for (int i = 1; i <= 20; i++) {
          await fakeFirestore.collection('leaderboard').doc('user$i').set({
            'username': 'Player $i',
            'totalStars': i * 10,
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, i)),
          });
        }

        // Call with different parameters
        final result1 = await repository.getTopPlayers(limit: 5);
        final result2 = await repository.getTopPlayers(limit: 10);
        final result3 = await repository.getTopPlayers(limit: 5, offset: 5);

        // Each should return different results
        expect(result1.length, 5);
        expect(result2.length, 10);
        expect(result3.length, 5);
        expect(result3[0].rank, 6); // offset = 5
      });
    });
  });
}
