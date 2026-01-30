import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/firestore_progress_repository.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreProgressRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreProgressRepository(firestore: fakeFirestore);
  });

  group('FirestoreProgressRepository', () {
    const testUserId = 'user-123';

    test('loadForUser returns empty state when no data exists', () async {
      final result = await repository.loadForUser(testUserId);

      expect(result, equals(const ProgressState.empty()));
      expect(result.levels, isEmpty);
    });

    test('saveForUser stores progress in Firestore', () async {
      final progressState = ProgressState(
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 45),
          ),
          1: const LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 60),
          ),
        },
      );

      await repository.saveForUser(testUserId, progressState);

      // Verify data was stored
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('progress')
          .get();

      expect(snapshot.docs.length, 2);
      expect(snapshot.docs[0].id, '0');
      expect(snapshot.docs[0].data()['stars'], 3);
      expect(snapshot.docs[0].data()['completed'], true);
      expect(snapshot.docs[0].data()['bestTimeMs'], 45000);
    });

    test('loadForUser retrieves stored progress', () async {
      final progressState = ProgressState(
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 45),
          ),
          1: const LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 60),
          ),
        },
      );

      await repository.saveForUser(testUserId, progressState);

      final loaded = await repository.loadForUser(testUserId);

      expect(loaded.levels.length, 2);
      expect(loaded.levels[0]?.stars, 3);
      expect(loaded.levels[0]?.completed, true);
      expect(loaded.levels[0]?.bestTime, const Duration(seconds: 45));
      expect(loaded.levels[1]?.stars, 2);
      expect(loaded.totalStars, 5);
    });

    test('resetForUser deletes all progress', () async {
      final progressState = ProgressState(
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
          1: const LevelProgress(completed: true, stars: 2),
        },
      );

      await repository.saveForUser(testUserId, progressState);

      // Verify data exists
      var loaded = await repository.loadForUser(testUserId);
      expect(loaded.levels.length, 2);

      // Reset
      await repository.resetForUser(testUserId);

      // Verify data is gone
      loaded = await repository.loadForUser(testUserId);
      expect(loaded.levels, isEmpty);
    });

    test('saveLevelProgress updates single level', () async {
      final progress = const LevelProgress(
        completed: true,
        stars: 3,
        bestTime: Duration(seconds: 45),
      );

      await repository.saveLevelProgress(testUserId, 5, progress);

      final loaded = await repository.loadForUser(testUserId);

      expect(loaded.levels.length, 1);
      expect(loaded.levels[5]?.stars, 3);
      expect(loaded.levels[5]?.completed, true);
    });

    test('watchProgress streams real-time updates', () async {
      final stream = repository.watchProgress(testUserId);

      final states = <ProgressState>[];
      final subscription = stream.listen(states.add);

      // Initial empty state
      await Future.delayed(const Duration(milliseconds: 100));
      expect(states.length, 1);
      expect(states[0].levels, isEmpty);

      // Add progress
      await repository.saveLevelProgress(
        testUserId,
        0,
        const LevelProgress(completed: true, stars: 3),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(states.length, 2);
      expect(states[1].levels[0]?.stars, 3);

      // Add more progress
      await repository.saveLevelProgress(
        testUserId,
        1,
        const LevelProgress(completed: true, stars: 2),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(states.length, 3);
      expect(states[2].levels.length, 2);
      expect(states[2].totalStars, 5);

      await subscription.cancel();
    });

    test('handles corrupted data gracefully', () async {
      // Manually insert invalid data
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('progress')
          .doc('invalid')
          .set({'corrupted': 'data'});

      // Should not throw and should skip invalid entry
      final loaded = await repository.loadForUser(testUserId);

      expect(loaded.levels, isEmpty);
    });

    test('merges progress when saving partial updates', () async {
      // Save initial progress
      await repository.saveLevelProgress(
        testUserId,
        0,
        const LevelProgress(completed: true, stars: 2),
      );

      // Save different level
      await repository.saveLevelProgress(
        testUserId,
        1,
        const LevelProgress(completed: true, stars: 3),
      );

      // Load and verify both levels exist
      final loaded = await repository.loadForUser(testUserId);

      expect(loaded.levels.length, 2);
      expect(loaded.levels[0]?.stars, 2);
      expect(loaded.levels[1]?.stars, 3);
      expect(loaded.totalStars, 5);
    });

    test('overwrites existing level progress', () async {
      // Save initial progress
      await repository.saveLevelProgress(
        testUserId,
        0,
        const LevelProgress(completed: true, stars: 2),
      );

      // Update with better score
      await repository.saveLevelProgress(
        testUserId,
        0,
        const LevelProgress(
          completed: true,
          stars: 3,
          bestTime: Duration(seconds: 30),
        ),
      );

      // Load and verify update
      final loaded = await repository.loadForUser(testUserId);

      expect(loaded.levels[0]?.stars, 3);
      expect(loaded.levels[0]?.bestTime, const Duration(seconds: 30));
    });

    test('handles multiple users independently', () async {
      const user1 = 'user-1';
      const user2 = 'user-2';

      // Save different progress for each user
      await repository.saveLevelProgress(
        user1,
        0,
        const LevelProgress(completed: true, stars: 3),
      );

      await repository.saveLevelProgress(
        user2,
        0,
        const LevelProgress(completed: true, stars: 2),
      );

      // Verify each user has their own progress
      final loaded1 = await repository.loadForUser(user1);
      final loaded2 = await repository.loadForUser(user2);

      expect(loaded1.levels[0]?.stars, 3);
      expect(loaded2.levels[0]?.stars, 2);
    });
  });
}
