import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hex_buzz/data/firebase/firestore_daily_challenge_repository.dart';
import 'package:hex_buzz/data/firebase/firestore_leaderboard_repository.dart';

void main() {
  group('Daily Challenge Submission & Leaderboard', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDailyChallengeRepository repository;
    late FirestoreLeaderboardRepository leaderboardRepository;

    /// Today's date string in YYYY-MM-DD format (UTC).
    String todayDateStr() {
      final now = DateTime.now().toUtc();
      return '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    }

    /// Seeds a daily challenge and a user document into fake Firestore.
    Future<void> seedChallengeAndUser(String dateStr, String userId) async {
      final cells = <Map<String, dynamic>>[];
      for (int q = 0; q < 6; q++) {
        for (int r = 0; r < 6; r++) {
          final cell = <String, dynamic>{'q': q, 'r': r};
          if (q == 0 && r == 0) cell['checkpoint'] = 1;
          if (q == 5 && r == 5) cell['checkpoint'] = 2;
          cells.add(cell);
        }
      }

      await fakeFirestore.collection('dailyChallenges').doc(dateStr).set({
        'id': dateStr,
        'level': {
          'id': 'daily-$dateStr',
          'size': 6,
          'cells': cells,
          'walls': [
            {'q1': 0, 'r1': 0, 'q2': 1, 'r2': 0},
          ],
          'checkpointCount': 2,
        },
        'completionCount': 0,
        'notificationSent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fakeFirestore.collection('users').doc(userId).set({
        'uid': userId,
        'displayName': 'TestUser',
        'photoURL': null,
        'totalStars': 42,
      });
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDailyChallengeRepository(firestore: fakeFirestore);
      leaderboardRepository = FirestoreLeaderboardRepository(
        firestore: fakeFirestore,
      );
    });

    test(
      'writes entry with completionTime field (not completionTimeMs)',
      () async {
        final dateStr = todayDateStr();
        const userId = 'user-field-test';
        await seedChallengeAndUser(dateStr, userId);

        final success = await repository.submitChallengeCompletion(
          userId: userId,
          stars: 3,
          completionTimeMs: 45000,
        );
        expect(success, isTrue);

        // Verify the document in Firestore has 'completionTime' field
        final doc = await fakeFirestore
            .collection('dailyChallenges')
            .doc(dateStr)
            .collection('entries')
            .doc(userId)
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['completionTime'], equals(45000));
        expect(
          data.containsKey('completionTimeMs'),
          isFalse,
          reason: 'Should use completionTime, not completionTimeMs',
        );
        expect(data['stars'], equals(3));
        expect(data['userId'], equals(userId));
        expect(data['username'], equals('TestUser'));
      },
    );

    test('returns true without writing when entry already exists', () async {
      final dateStr = todayDateStr();
      const userId = 'user-duplicate';
      await seedChallengeAndUser(dateStr, userId);

      // First submission
      final first = await repository.submitChallengeCompletion(
        userId: userId,
        stars: 2,
        completionTimeMs: 60000,
      );
      expect(first, isTrue);

      // Second submission (even with better score)
      final second = await repository.submitChallengeCompletion(
        userId: userId,
        stars: 3,
        completionTimeMs: 30000,
      );
      expect(second, isTrue);

      // Verify original entry is unchanged
      final doc = await fakeFirestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .collection('entries')
          .doc(userId)
          .get();

      expect(
        doc.data()!['stars'],
        equals(2),
        reason: 'Original score should be preserved',
      );
      expect(
        doc.data()!['completionTime'],
        equals(60000),
        reason: 'Original time should be preserved',
      );
    });

    test('increments completionCount only on first submission', () async {
      final dateStr = todayDateStr();
      const userId = 'user-count';
      await seedChallengeAndUser(dateStr, userId);

      await repository.submitChallengeCompletion(
        userId: userId,
        stars: 3,
        completionTimeMs: 45000,
      );

      // Try duplicate
      await repository.submitChallengeCompletion(
        userId: userId,
        stars: 3,
        completionTimeMs: 45000,
      );

      final challengeDoc = await fakeFirestore
          .collection('dailyChallenges')
          .doc(dateStr)
          .get();
      expect(
        challengeDoc.data()!['completionCount'],
        equals(1),
        reason: 'Count should increment only once per user',
      );
    });

    test('getCompletion reads completionTime field correctly', () async {
      final dateStr = todayDateStr();
      const userId = 'user-read';
      await seedChallengeAndUser(dateStr, userId);

      await repository.submitChallengeCompletion(
        userId: userId,
        stars: 2,
        completionTimeMs: 55000,
      );

      final completion = await repository.getCompletion(
        userId: userId,
        dateId: dateStr,
      );

      expect(completion, isNotNull);
      expect(completion!.completionTimeMs, equals(55000));
      expect(completion.stars, equals(2));
      expect(completion.userId, equals(userId));
    });

    test('getChallengeLeaderboard returns entries sorted correctly', () async {
      final dateStr = todayDateStr();
      final date = DateTime.parse(dateStr);

      // Seed challenge and multiple users
      for (final id in ['user-a', 'user-b', 'user-c']) {
        await seedChallengeAndUser(dateStr, id);
      }

      // Submit in mixed order
      await repository.submitChallengeCompletion(
        userId: 'user-a',
        stars: 2,
        completionTimeMs: 40000,
      );
      await repository.submitChallengeCompletion(
        userId: 'user-b',
        stars: 3,
        completionTimeMs: 50000,
      );
      await repository.submitChallengeCompletion(
        userId: 'user-c',
        stars: 3,
        completionTimeMs: 30000,
      );

      final entries = await repository.getChallengeLeaderboard(
        date: date,
        limit: 50,
      );

      expect(entries.length, equals(3));
      // user-c: 3 stars, 30s (rank 1)
      // user-b: 3 stars, 50s (rank 2)
      // user-a: 2 stars, 40s (rank 3)
      expect(entries[0].userId, equals('user-c'));
      expect(entries[0].rank, equals(1));
      expect(entries[0].completionTime, equals(30000));
      expect(entries[0].stars, equals(3));
      expect(entries[1].userId, equals('user-b'));
      expect(entries[1].rank, equals(2));
      expect(entries[2].userId, equals('user-a'));
      expect(entries[2].rank, equals(3));
    });

    test(
      'leaderboardRepository.getDailyChallengeLeaderboard reads completionTime',
      () async {
        final dateStr = todayDateStr();
        final date = DateTime.parse(dateStr);
        const userId = 'user-lb';
        await seedChallengeAndUser(dateStr, userId);

        await repository.submitChallengeCompletion(
          userId: userId,
          stars: 3,
          completionTimeMs: 25000,
        );

        final entries = await leaderboardRepository
            .getDailyChallengeLeaderboard(date: date, limit: 50);

        expect(entries.length, equals(1));
        expect(entries[0].completionTime, equals(25000));
        expect(entries[0].stars, equals(3));
        expect(entries[0].userId, equals(userId));
      },
    );

    test('hasCompletedToday returns correct status', () async {
      final dateStr = todayDateStr();
      const userId = 'user-status';
      await seedChallengeAndUser(dateStr, userId);

      expect(await repository.hasCompletedToday(userId), isFalse);

      await repository.submitChallengeCompletion(
        userId: userId,
        stars: 1,
        completionTimeMs: 90000,
      );

      expect(await repository.hasCompletedToday(userId), isTrue);
    });
  });
}
