import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/data/local/local_progress_repository.dart';
import 'package:honeycomb_one_pass/domain/models/progress_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalProgressRepository', () {
    late SharedPreferences prefs;
    late LocalProgressRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalProgressRepository(prefs);
    });

    group('load', () {
      test('returns empty state when no saved data exists', () async {
        final state = await repository.load();
        expect(state, const ProgressState.empty());
      });

      test('loads saved progress state correctly', () async {
        const savedData =
            '{"levels":{"0":{"completed":true,"stars":3,'
            '"bestTimeMs":8000},"1":{"completed":true,"stars":2,"bestTimeMs":15000}}}';
        await prefs.setString('progress_state', savedData);

        final state = await repository.load();

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
        await prefs.setString('progress_state', savedData);

        final state = await repository.load();

        expect(state.levels, isEmpty);
      });

      test('handles missing bestTimeMs gracefully', () async {
        const savedData = '{"levels":{"0":{"completed":true,"stars":2}}}';
        await prefs.setString('progress_state', savedData);

        final state = await repository.load();

        expect(state.getProgress(0).completed, true);
        expect(state.getProgress(0).stars, 2);
        expect(state.getProgress(0).bestTime, isNull);
      });
    });

    group('corrupted data handling', () {
      test('returns empty state for invalid JSON', () async {
        await prefs.setString('progress_state', 'not valid json');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for malformed JSON structure', () async {
        await prefs.setString('progress_state', '{"invalid": "structure"}');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for truncated JSON', () async {
        await prefs.setString('progress_state', '{"levels":{"0":{"com');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for empty string', () async {
        await prefs.setString('progress_state', '');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for non-object JSON', () async {
        await prefs.setString('progress_state', '"just a string"');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for array JSON', () async {
        await prefs.setString('progress_state', '[1, 2, 3]');

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });

      test('returns empty state for invalid level keys', () async {
        await prefs.setString(
          'progress_state',
          '{"levels":{"not_a_number":{"completed":true,"stars":1}}}',
        );

        final state = await repository.load();

        expect(state, const ProgressState.empty());
      });
    });

    group('save', () {
      test('saves empty state correctly', () async {
        const state = ProgressState.empty();

        await repository.save(state);

        final savedString = prefs.getString('progress_state');
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

        await repository.save(state);

        final savedString = prefs.getString('progress_state');
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

        await repository.save(original);
        final loaded = await repository.load();

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

        await repository.save(original);
        final loaded = await repository.load();

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

        await repository.save(original);
        final loaded = await repository.load();

        expect(loaded, original);
      });

      test('round-trips state with level without bestTime', () async {
        const original = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 2)},
        );

        await repository.save(original);
        final loaded = await repository.load();

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

        await repository.save(original);
        final loaded = await repository.load();

        expect(loaded, original);
      });
    });

    group('reset', () {
      test('removes saved data', () async {
        const state = ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 3)},
        );
        await repository.save(state);

        await repository.reset();

        final savedString = prefs.getString('progress_state');
        expect(savedString, isNull);
      });

      test('load returns empty state after reset', () async {
        const state = ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );
        await repository.save(state);

        await repository.reset();
        final loaded = await repository.load();

        expect(loaded, const ProgressState.empty());
      });

      test('reset is idempotent', () async {
        await repository.reset();
        await repository.reset();

        final loaded = await repository.load();
        expect(loaded, const ProgressState.empty());
      });

      test('reset when no data exists does not throw', () async {
        await expectLater(repository.reset(), completes);

        final loaded = await repository.load();
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

        await repository.save(state1);
        await repository.save(state2);
        final loaded = await repository.load();

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

        await repository.save(state1);
        await repository.save(state2);
        final loaded = await repository.load();

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

        await repository1.save(state);
        final loaded = await repository2.load();

        expect(loaded, state);
      });
    });
  });
}
