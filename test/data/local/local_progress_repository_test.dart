import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/local/local_progress_repository.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalProgressRepository', () {
    late SharedPreferences prefs;
    late LocalProgressRepository repository;

    // Default test user ID
    const testUserId = 'test_user';
    const guestUserId = 'guest';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalProgressRepository(prefs);
    });

    group('loadForUser', () {
      test('returns empty state when no saved data exists', () async {
        final state = await repository.loadForUser(testUserId);
        expect(state, const ProgressState.empty());
      });

      test('loads saved progress state correctly', () async {
        const savedData =
            '{"levels":{"0":{"completed":true,"stars":3,'
            '"bestTimeMs":8000},"1":{"completed":true,"stars":2,"bestTimeMs":15000}}}';
        await prefs.setString('progress_state_$testUserId', savedData);

        final state = await repository.loadForUser(testUserId);

        expect(state.levels.length, 2);
        expect(state.getProgress(0).completed, true);
        expect(state.getProgress(0).stars, 3);
        expect(state.getProgress(0).bestTime, const Duration(seconds: 8));
        expect(state.getProgress(1).completed, true);
        expect(state.getProgress(1).stars, 2);
        expect(state.getProgress(1).bestTime, const Duration(seconds: 15));
      });

      test('loads state with empty levels', () async {
        const savedData = '{"levels":{}}';
        await prefs.setString('progress_state_$testUserId', savedData);

        final state = await repository.loadForUser(testUserId);

        expect(state.levels, isEmpty);
      });

      test('handles missing bestTimeMs gracefully', () async {
        const savedData = '{"levels":{"0":{"completed":true,"stars":2}}}';
        await prefs.setString('progress_state_$testUserId', savedData);

        final state = await repository.loadForUser(testUserId);

        expect(state.getProgress(0).completed, true);
        expect(state.getProgress(0).stars, 2);
        expect(state.getProgress(0).bestTime, isNull);
      });
    });

    group('corrupted data handling', () {
      test('returns empty state for invalid JSON', () async {
        await prefs.setString('progress_state_$testUserId', 'not valid json');

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for malformed JSON structure', () async {
        await prefs.setString(
          'progress_state_$testUserId',
          '{"invalid": "structure"}',
        );

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for truncated JSON', () async {
        await prefs.setString(
          'progress_state_$testUserId',
          '{"levels":{"0":{"com',
        );

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for empty string', () async {
        await prefs.setString('progress_state_$testUserId', '');

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for non-object JSON', () async {
        await prefs.setString('progress_state_$testUserId', '"just a string"');

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for array JSON', () async {
        await prefs.setString('progress_state_$testUserId', '[1, 2, 3]');

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for invalid level keys', () async {
        await prefs.setString(
          'progress_state_$testUserId',
          '{"levels":{"not_a_number":{"completed":true,"stars":1}}}',
        );

        final state = await repository.loadForUser(testUserId);

        expect(state, const ProgressState.empty());
      });
    });

    group('saveForUser', () {
      test('saves empty state correctly', () async {
        const state = ProgressState.empty();

        await repository.saveForUser(testUserId, state);

        final savedString = prefs.getString('progress_state_$testUserId');
        expect(savedString, isNotNull);
        expect(savedString, contains('"levels"'));
      });

      test('saves state with multiple levels correctly', () async {
        const state = ProgressState(
          levels: {
            0: LevelProgress(
              completed: true,
              stars: 3,
              bestTime: Duration(seconds: 8),
            ),
            1: LevelProgress(
              completed: true,
              stars: 2,
              bestTime: Duration(seconds: 15),
            ),
            2: LevelProgress(completed: false, stars: 0),
          },
        );

        await repository.saveForUser(testUserId, state);

        final savedString = prefs.getString('progress_state_$testUserId');
        expect(savedString, isNotNull);
        expect(savedString, contains('"0"'));
        expect(savedString, contains('"1"'));
        expect(savedString, contains('"2"'));
        expect(savedString, contains('"stars":3'));
        expect(savedString, contains('"bestTimeMs":8000'));
      });
    });

    group('save/load round-trip', () {
      test('round-trips empty state', () async {
        const original = ProgressState.empty();

        await repository.saveForUser(testUserId, original);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, original);
      });

      test('round-trips state with single level', () async {
        const original = ProgressState(
          levels: {
            0: LevelProgress(
              completed: true,
              stars: 3,
              bestTime: Duration(milliseconds: 8500),
            ),
          },
        );

        await repository.saveForUser(testUserId, original);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, original);
      });

      test('round-trips state with multiple levels', () async {
        const original = ProgressState(
          levels: {
            0: LevelProgress(
              completed: true,
              stars: 3,
              bestTime: Duration(seconds: 8),
            ),
            1: LevelProgress(
              completed: true,
              stars: 2,
              bestTime: Duration(seconds: 15),
            ),
            2: LevelProgress(
              completed: true,
              stars: 1,
              bestTime: Duration(seconds: 45),
            ),
            3: LevelProgress(completed: false, stars: 0),
          },
        );

        await repository.saveForUser(testUserId, original);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, original);
      });

      test('round-trips state with level without bestTime', () async {
        const original = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 2)},
        );

        await repository.saveForUser(testUserId, original);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, original);
      });

      test('round-trips state with non-sequential level indices', () async {
        const original = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            5: LevelProgress(completed: true, stars: 2),
            10: LevelProgress(completed: true, stars: 1),
          },
        );

        await repository.saveForUser(testUserId, original);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, original);
      });
    });

    group('resetForUser', () {
      test('removes saved data for specific user', () async {
        const state = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        await repository.saveForUser(testUserId, state);

        await repository.resetForUser(testUserId);

        final savedString = prefs.getString('progress_state_$testUserId');
        expect(savedString, isNull);
      });

      test('loadForUser returns empty state after reset', () async {
        const state = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );
        await repository.saveForUser(testUserId, state);

        await repository.resetForUser(testUserId);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, const ProgressState.empty());
      });

      test('reset is idempotent', () async {
        await repository.resetForUser(testUserId);
        await repository.resetForUser(testUserId);

        final loaded = await repository.loadForUser(testUserId);
        expect(loaded, const ProgressState.empty());
      });

      test('reset when no data exists does not throw', () async {
        await expectLater(repository.resetForUser(testUserId), completes);

        final loaded = await repository.loadForUser(testUserId);
        expect(loaded, const ProgressState.empty());
      });
    });

    group('overwrite behavior', () {
      test('save overwrites existing data', () async {
        const state1 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 1)},
        );
        const state2 = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );

        await repository.saveForUser(testUserId, state1);
        await repository.saveForUser(testUserId, state2);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, state2);
        expect(loaded.levels.length, 2);
        expect(loaded.getProgress(0).stars, 3);
      });

      test('save with empty state clears previous data', () async {
        const state1 = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );
        const state2 = ProgressState.empty();

        await repository.saveForUser(testUserId, state1);
        await repository.saveForUser(testUserId, state2);
        final loaded = await repository.loadForUser(testUserId);

        expect(loaded, state2);
        expect(loaded.levels, isEmpty);
      });
    });

    group('multiple instances', () {
      test('different instances share same storage', () async {
        final repository1 = LocalProgressRepository(prefs);
        final repository2 = LocalProgressRepository(prefs);

        const state = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );

        await repository1.saveForUser(testUserId, state);
        final loaded = await repository2.loadForUser(testUserId);

        expect(loaded, state);
      });
    });

    group('user isolation', () {
      test('different users have separate progress storage', () async {
        const userId1 = 'user_1';
        const userId2 = 'user_2';

        const state1 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        const state2 = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 1)},
        );

        await repository.saveForUser(userId1, state1);
        await repository.saveForUser(userId2, state2);

        final loaded1 = await repository.loadForUser(userId1);
        final loaded2 = await repository.loadForUser(userId2);

        expect(loaded1.getProgress(0).stars, 3);
        expect(loaded2.getProgress(0).stars, 1);
      });

      test('resetting one user does not affect another', () async {
        const userId1 = 'user_1';
        const userId2 = 'user_2';

        const state = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );

        await repository.saveForUser(userId1, state);
        await repository.saveForUser(userId2, state);

        await repository.resetForUser(userId1);

        final loaded1 = await repository.loadForUser(userId1);
        final loaded2 = await repository.loadForUser(userId2);

        expect(loaded1, const ProgressState.empty());
        expect(loaded2, state);
      });

      test('guest user progress is isolated from regular users', () async {
        const regularUserId = 'regular_user';

        const regularState = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        const guestState = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 1)},
        );

        await repository.saveForUser(regularUserId, regularState);
        await repository.saveForUser(guestUserId, guestState);

        final loadedRegular = await repository.loadForUser(regularUserId);
        final loadedGuest = await repository.loadForUser(guestUserId);

        expect(loadedRegular.getProgress(0).stars, 3);
        expect(loadedGuest.getProgress(0).stars, 1);
      });

      test('guest progress persists across sessions', () async {
        const state = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 2),
            1: LevelProgress(completed: true, stars: 3),
          },
        );

        await repository.saveForUser(guestUserId, state);

        // Create a new repository instance to simulate app restart
        final newRepository = LocalProgressRepository(prefs);
        final loaded = await newRepository.loadForUser(guestUserId);

        expect(loaded, state);
      });
    });
  });
}
