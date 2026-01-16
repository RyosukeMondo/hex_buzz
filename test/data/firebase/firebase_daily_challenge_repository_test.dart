import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firebase_daily_challenge_repository.dart';

void main() {
  group('FirebaseDailyChallengeRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseDailyChallengeRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseDailyChallengeRepository(firestore: fakeFirestore);
    });

    // Helper to create test level data
    Map<String, dynamic> createTestLevel({
      String id = 'challenge-001',
      int size = 2,
    }) {
      return {
        'id': id,
        'size': size,
        'cells': [
          {'q': 0, 'r': 0, 'checkpointId': 0},
        ],
        'walls': <Map<String, dynamic>>[],
        'checkpointCount': 1,
      };
    }

    group('getTodaysChallenge', () {
      test('returns null when no challenge exists for today', () async {
        final result = await repository.getTodaysChallenge();

        expect(result, isNull);
      });

      test('returns today\'s challenge when it exists', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'size': 2,
            'cells': [
              {'q': 0, 'r': 0, 'checkpointId': 0},
              {'q': 1, 'r': 0, 'checkpointId': 1},
            ],
            'walls': <Map<String, dynamic>>[],
            'checkpointCount': 2,
          },
          'completionCount': 42,
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.id, dateStr);
        expect(result.level.id, 'challenge-001');
        expect(result.completionCount, 42);
      });

      test('returns null when challenge data is malformed', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Missing level data
        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'completionCount': 42,
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNull);
      });

      test('defaults completionCount to 0 when missing', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': createTestLevel(),
        });

        final result = await repository.getTodaysChallenge();

        expect(result, isNotNull);
        expect(result!.completionCount, 0);
      });
    });

    group('submitChallengeCompletion', () {
      test('creates new completion for first-time user', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Create challenge
        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 0,
        });

        final result = await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        expect(result, isTrue);

        final completion = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .get();

        expect(completion.exists, isTrue);
        expect(completion.data()!['userId'], 'user1');
        expect(completion.data()!['stars'], 3);
        expect(completion.data()!['completionTimeMs'], 5000);
      });

      test('increments completion count for new user', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 5,
        });

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        final challenge = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .get();

        expect(challenge.data()!['completionCount'], 6);
      });

      test('updates completion when new score is better (more stars)', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 1,
        });

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .set({
              'userId': 'user1',
              'stars': 2,
              'completionTimeMs': 5000,
              'completedAt': Timestamp.now(),
            });

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 6000,
        );

        final completion = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .get();

        expect(completion.data()!['stars'], 3);
        expect(completion.data()!['completionTimeMs'], 6000);
      });

      test('updates completion when same stars but faster time', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 1,
        });

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .set({
              'userId': 'user1',
              'stars': 3,
              'completionTimeMs': 6000,
              'completedAt': Timestamp.now(),
            });

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 4000,
        );

        final completion = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .get();

        expect(completion.data()!['completionTimeMs'], 4000);
      });

      test('does not update when new score is worse', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 1,
        });

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

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 2,
          completionTimeMs: 3000,
        );

        final completion = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .get();

        expect(completion.data()!['stars'], 3); // Unchanged
        expect(completion.data()!['completionTimeMs'], 5000); // Unchanged
      });

      test('does not increment count for existing user improvement', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
          'level': {
            'id': 'challenge-001',
            'name': 'Daily Challenge',
            'size': 4,
            'checkpoints': [
              {'id': 0, 'q': 0, 'r': 0},
            ],
            'walls': <Map<String, dynamic>>[],
            'difficulty': 1,
          },
          'completionCount': 5,
        });

        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user1')
            .set({
              'userId': 'user1',
              'stars': 2,
              'completionTimeMs': 6000,
              'completedAt': Timestamp.now(),
            });

        await repository.submitChallengeCompletion(
          userId: 'user1',
          stars: 3,
          completionTimeMs: 5000,
        );

        final challenge = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .get();

        expect(challenge.data()!['completionCount'], 5); // Unchanged
      });
    });

    group('getChallengeLeaderboard', () {
      test('returns empty list when no completions exist', () async {
        final date = DateTime(2024, 1, 15);
        final result = await repository.getChallengeLeaderboard(date: date);

        expect(result, isEmpty);
      });

      test('returns completions sorted by stars then time', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

        await fakeFirestore.collection('users').doc('user1').set({
          'username': 'Player1',
        });
        await fakeFirestore.collection('users').doc('user2').set({
          'username': 'Player2',
        });
        await fakeFirestore.collection('users').doc('user3').set({
          'username': 'Player3',
        });

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
              'stars': 2,
              'completionTimeMs': 3000,
              'completedAt': Timestamp.now(),
            });
        await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('completions')
            .doc('user3')
            .set({
              'userId': 'user3',
              'stars': 3,
              'completionTimeMs': 4000,
              'completedAt': Timestamp.now(),
            });

        final result = await repository.getChallengeLeaderboard(date: date);

        expect(result, hasLength(3));
        expect(result[0].userId, 'user3'); // 3 stars, fastest
        expect(result[0].rank, 1);
        expect(result[1].userId, 'user1'); // 3 stars, slower
        expect(result[1].rank, 2);
        expect(result[2].userId, 'user2'); // 2 stars
        expect(result[2].rank, 3);
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

        final result = await repository.getChallengeLeaderboard(
          date: date,
          limit: 5,
        );

        expect(result, hasLength(5));
      });

      test('handles missing user data gracefully', () async {
        final date = DateTime(2024, 1, 15);
        final dateStr = '2024-01-15';

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

        final result = await repository.getChallengeLeaderboard(date: date);

        expect(result, hasLength(1));
        expect(result[0].username, 'Anonymous');
      });
    });

    group('hasCompletedToday', () {
      test(
        'returns false when user has not completed today\'s challenge',
        () async {
          final result = await repository.hasCompletedToday('user1');

          expect(result, isFalse);
        },
      );

      test('returns true when user has completed today\'s challenge', () async {
        final today = DateTime.now().toUtc();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

        final result = await repository.hasCompletedToday('user1');

        expect(result, isTrue);
      });
    });
  });
}
