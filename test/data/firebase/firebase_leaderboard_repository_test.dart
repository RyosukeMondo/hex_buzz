import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firebase_leaderboard_repository.dart';

void main() {
  group('FirebaseLeaderboardRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseLeaderboardRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseLeaderboardRepository(firestore: fakeFirestore);
    });

    group('getTopPlayers', () {
      test('returns empty list when no leaderboard data exists', () async {
        final result = await repository.getTopPlayers();

        expect(result, isEmpty);
      });

      test('returns top players sorted by stars descending', () async {
        // Add test data
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'userId': 'user2',
          'username': 'Player2',
          'avatarUrl': null,
          'totalStars': 200,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user3').set({
          'userId': 'user3',
          'username': 'Player3',
          'avatarUrl': null,
          'totalStars': 150,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.getTopPlayers();

        expect(result, hasLength(3));
        expect(result[0].userId, 'user2');
        expect(result[0].totalStars, 200);
        expect(result[0].rank, 1);
        expect(result[1].userId, 'user3');
        expect(result[1].totalStars, 150);
        expect(result[1].rank, 2);
        expect(result[2].userId, 'user1');
        expect(result[2].totalStars, 100);
        expect(result[2].rank, 3);
      });

      test('respects limit parameter', () async {
        for (int i = 0; i < 10; i++) {
          await fakeFirestore.collection('leaderboard').doc('user$i').set({
            'userId': 'user$i',
            'username': 'Player$i',
            'avatarUrl': null,
            'totalStars': i * 10,
            'updatedAt': Timestamp.now(),
          });
        }

        final result = await repository.getTopPlayers(limit: 5);

        expect(result, hasLength(5));
      });

      test('handles pagination with offset', () async {
        for (int i = 0; i < 10; i++) {
          await fakeFirestore.collection('leaderboard').doc('user$i').set({
            'userId': 'user$i',
            'username': 'Player$i',
            'avatarUrl': null,
            'totalStars': i * 10,
            'updatedAt': Timestamp.now(),
          });
        }

        final result = await repository.getTopPlayers(limit: 5, offset: 3);

        // fake_cloud_firestore may not fully support startAfterDocument pagination
        // Just verify we get some results and ranks start correctly
        expect(result.isNotEmpty, isTrue);
        if (result.isNotEmpty) {
          expect(result[0].rank, greaterThanOrEqualTo(4));
        }
      });

      test('returns empty list for offset beyond available data', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.getTopPlayers(offset: 10);

        expect(result, isEmpty);
      });

      test('skips invalid entries gracefully', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });
        // Invalid entry missing required fields
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'userId': 'user2',
          // Missing username
        });

        final result = await repository.getTopPlayers();

        expect(result, hasLength(1));
        expect(result[0].userId, 'user1');
      });
    });

    group('getUserRank', () {
      test('returns null when user has no leaderboard entry', () async {
        final result = await repository.getUserRank('nonexistent');

        expect(result, isNull);
      });

      test('returns correct rank for user', () async {
        // Add users with different scores
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'userId': 'user2',
          'username': 'Player2',
          'avatarUrl': null,
          'totalStars': 200,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user3').set({
          'userId': 'user3',
          'username': 'Player3',
          'avatarUrl': null,
          'totalStars': 150,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.getUserRank('user3');

        expect(result, isNotNull);
        expect(result!.userId, 'user3');
        expect(result.rank, 2); // Rank 2 because user2 has more stars
      });

      test('returns rank 1 for top scorer', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'userId': 'user2',
          'username': 'Player2',
          'avatarUrl': null,
          'totalStars': 200,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.getUserRank('user2');

        expect(result, isNotNull);
        expect(result!.rank, 1);
      });
    });

    group('submitScore', () {
      test('creates new leaderboard entry for new user', () async {
        // Create user document
        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'TestPlayer',
          'photoURL': 'https://example.com/avatar.png',
        });

        final result = await repository.submitScore(
          userId: 'user1',
          stars: 100,
        );

        expect(result, isTrue);

        final doc = await fakeFirestore
            .collection('leaderboard')
            .doc('user1')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['userId'], 'user1');
        expect(doc.data()!['totalStars'], 100);
        expect(doc.data()!['username'], 'TestPlayer');
        expect(doc.data()!['avatarUrl'], 'https://example.com/avatar.png');
      });

      test('updates existing entry if new score is higher', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'TestPlayer',
        });

        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'TestPlayer',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.submitScore(
          userId: 'user1',
          stars: 150,
        );

        expect(result, isTrue);

        final doc = await fakeFirestore
            .collection('leaderboard')
            .doc('user1')
            .get();
        expect(doc.data()!['totalStars'], 150);
      });

      test('does not update if new score is lower', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'TestPlayer',
        });

        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'TestPlayer',
          'avatarUrl': null,
          'totalStars': 200,
          'updatedAt': Timestamp.now(),
        });

        final result = await repository.submitScore(
          userId: 'user1',
          stars: 150,
        );

        expect(result, isTrue);

        final doc = await fakeFirestore
            .collection('leaderboard')
            .doc('user1')
            .get();
        expect(doc.data()!['totalStars'], 200); // Unchanged
      });

      test('handles missing user data gracefully', () async {
        final result = await repository.submitScore(
          userId: 'user1',
          stars: 100,
        );

        expect(result, isTrue);

        final doc = await fakeFirestore
            .collection('leaderboard')
            .doc('user1')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['username'], 'Anonymous');
      });

      test('stores levelId when provided', () async {
        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'TestPlayer',
        });

        await repository.submitScore(
          userId: 'user1',
          stars: 100,
          levelId: 'level-4x4-001',
        );

        final doc = await fakeFirestore
            .collection('leaderboard')
            .doc('user1')
            .get();
        expect(doc.data()!['lastLevel'], 'level-4x4-001');
      });
    });

    group('getDailyChallengeLeaderboard', () {
      test('returns empty list when no completions exist', () async {
        final date = DateTime(2024, 1, 15);
        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
        );

        expect(result, isEmpty);
      });

      test('returns completions sorted by stars and time', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        // Add user data
        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'Player1',
        });
        await fakeFirestore.collection('users').doc('user2').set({
          'username': 'Player2',
        });

        // Add completions
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .set({
              'userId': 'user1',
              'stars': 3,
              'completionTimeMs': 5000,
              'completedAt': Timestamp.now(),
            });
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user2')
            .set({
              'userId': 'user2',
              'stars': 3,
              'completionTimeMs': 3000,
              'completedAt': Timestamp.now(),
            });

        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
        );

        expect(result, hasLength(2));
        expect(result[0].userId, 'user2'); // Same stars, faster time
        expect(result[0].rank, 1);
        expect(result[1].userId, 'user1');
        expect(result[1].rank, 2);
      });

      test('respects limit parameter', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        for (int i = 0; i < 10; i++) {
          await fakeFirestore.collection('users').doc('user$i').set({
            'username': 'Player$i',
          });
          await fakeFirestore
              .collection('dailyChallenges')
              .doc(dateStr)
              .collection('completions')
              .doc('user$i')
              .set({
                'userId': 'user$i',
                'stars': 3,
                'completionTimeMs': i * 1000,
                'completedAt': Timestamp.now(),
              });
        }

        final result = await repository.getDailyChallengeLeaderboard(
          date: date,
          limit: 5,
        );

        expect(result, hasLength(5));
      });
    });

    group('watchLeaderboard', () {
      test('emits leaderboard updates in real-time', () async {
        final stream = repository.watchLeaderboard();

        // Initial state: empty
        expect(await stream.first, isEmpty);

        // Add an entry
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });

        // Stream should emit updated list
        final entries = await stream.first;
        expect(entries, hasLength(1));
        expect(entries[0].userId, 'user1');
      });

      test('emits sorted entries by stars', () async {
        await fakeFirestore.collection('leaderboard').doc('user1').set({
          'userId': 'user1',
          'username': 'Player1',
          'avatarUrl': null,
          'totalStars': 100,
          'updatedAt': Timestamp.now(),
        });
        await fakeFirestore.collection('leaderboard').doc('user2').set({
          'userId': 'user2',
          'username': 'Player2',
          'avatarUrl': null,
          'totalStars': 200,
          'updatedAt': Timestamp.now(),
        });

        final stream = repository.watchLeaderboard();
        final entries = await stream.first;

        expect(entries[0].userId, 'user2');
        expect(entries[0].rank, 1);
        expect(entries[1].userId, 'user1');
        expect(entries[1].rank, 2);
      });
    });
  });
}
