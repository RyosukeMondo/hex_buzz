import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/domain/services/game_engine.dart';

void main() {
  group('GameProvider Edge Cases', () {
    late Level testLevel;

    setUp(() {
      final cells = <(int, int), HexCell>{
        (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
        (1, 0): const HexCell(q: 1, r: 0),
        (0, 1): const HexCell(q: 0, r: 1),
        (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
      };
      testLevel = Level(size: 2, cells: cells, walls: {}, checkpointCount: 2);
    });

    test('undo does nothing when path is empty', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      // Initial state has empty path
      notifier.undo();

      // Should not throw and path should still be empty
      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .path,
        isEmpty,
      );
    });

    test('restart clears path and resets timer', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      // Make some moves
      notifier.selectCell(const HexCell(q: 0, r: 0, checkpoint: 1));
      notifier.selectCell(const HexCell(q: 1, r: 0));

      // Restart
      notifier.restart();

      final state = container.read(
        gameNotifierProvider(level: testLevel, mode: GameMode.practice),
      );

      expect(state.path, isEmpty);
      expect(state.isStarted, false);
      expect(state.elapsedTime, Duration.zero);
    });

    test('selectCell with invalid cell is rejected', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      // Select a cell not in the level
      final invalidCell = const HexCell(q: 99, r: 99);
      notifier.selectCell(invalidCell);

      final state = container.read(
        gameNotifierProvider(level: testLevel, mode: GameMode.practice),
      );

      // Path should be empty (invalid move rejected)
      expect(state.path, isEmpty);
    });

    test('completing level starts timer and marks completion', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      // Complete the level
      notifier.selectCell(const HexCell(q: 0, r: 0, checkpoint: 1));
      notifier.selectCell(const HexCell(q: 1, r: 0));
      notifier.selectCell(const HexCell(q: 1, r: 1, checkpoint: 2));
      notifier.selectCell(const HexCell(q: 0, r: 1));

      // Give time for completion to process
      Future.microtask(() {
        final state = container.read(
          gameNotifierProvider(level: testLevel, mode: GameMode.practice),
        );

        expect(state.isComplete, true);
        expect(state.isStarted, true);
      });
    });

    test('timer starts on first move', () async {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .isStarted,
        false,
      );

      notifier.selectCell(const HexCell(q: 0, r: 0, checkpoint: 1));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .isStarted,
        true,
      );
    });

    test('undo removes last cell from path', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      notifier.selectCell(const HexCell(q: 0, r: 0, checkpoint: 1));
      notifier.selectCell(const HexCell(q: 1, r: 0));

      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .path
            .length,
        2,
      );

      notifier.undo();

      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .path
            .length,
        1,
      );
    });

    test('multiple undos work correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(
        gameNotifierProvider(
          level: testLevel,
          mode: GameMode.practice,
        ).notifier,
      );

      notifier.selectCell(const HexCell(q: 0, r: 0, checkpoint: 1));
      notifier.selectCell(const HexCell(q: 1, r: 0));
      notifier.selectCell(const HexCell(q: 1, r: 1, checkpoint: 2));

      notifier.undo();
      notifier.undo();

      expect(
        container
            .read(
              gameNotifierProvider(level: testLevel, mode: GameMode.practice),
            )
            .path
            .length,
        1,
      );
    });

    test('game state preserves level and mode', () {
      final container = ProviderContainer();

      final state = container.read(
        gameNotifierProvider(level: testLevel, mode: GameMode.daily),
      );

      expect(state.level, testLevel);
      expect(state.mode, GameMode.daily);
    });
  });
}
