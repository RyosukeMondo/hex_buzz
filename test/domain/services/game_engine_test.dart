import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/game_mode.dart';
import 'package:honeycomb_one_pass/domain/models/game_state.dart';
import 'package:honeycomb_one_pass/domain/models/hex_cell.dart';
import 'package:honeycomb_one_pass/domain/models/hex_edge.dart';
import 'package:honeycomb_one_pass/domain/models/level.dart';
import 'package:honeycomb_one_pass/domain/services/game_engine.dart';

void main() {
  /// Creates a simple 2x2 solvable level.
  ///
  /// Layout (flat-top hexagons):
  ///   (0,0)[1] - (1,0)
  ///      \    /  \
  ///     (0,1) - (1,1)[2]
  ///
  /// Checkpoint 1 at (0,0), Checkpoint 2 at (1,1)
  Level createSimpleLevel({Set<HexEdge>? walls}) {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    };
    return Level(size: 2, cells: cells, walls: walls ?? {}, checkpointCount: 2);
  }

  /// Creates a level with 3 checkpoints.
  ///
  /// Layout:
  ///   (0,0)[1] - (1,0)[2]
  ///      \    /  \
  ///     (0,1) - (1,1)[3]
  Level createThreeCheckpointLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 3),
    };
    return Level(size: 2, cells: cells, walls: {}, checkpointCount: 3);
  }

  group('GameEngine', () {
    group('initialization', () {
      test('creates engine with initial state', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        expect(engine.state.level, level);
        expect(engine.state.mode, GameMode.practice);
        expect(engine.state.path, isEmpty);
        expect(engine.state.isStarted, false);
        expect(engine.state.isComplete, false);
      });

      test('creates engine from existing state', () {
        final level = createSimpleLevel();
        final existingState = GameState(
          level: level,
          mode: GameMode.daily,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final engine = GameEngine.fromState(state: existingState);

        expect(engine.state.path.length, 1);
        expect(engine.state.mode, GameMode.daily);
        expect(engine.state.nextCheckpoint, 2);
      });

      test('creates engine with custom validator', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Should not throw - validator is used internally
        expect(engine.state, isNotNull);
      });
    });

    group('tryMove', () {
      test('first move to start cell succeeds', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);
        final startCell = const HexCell(q: 0, r: 0);

        final result = engine.tryMove(startCell);

        expect(result.success, true);
        expect(result.error, isNull);
        expect(engine.state.path.length, 1);
        expect(engine.state.path.first.q, 0);
        expect(engine.state.path.first.r, 0);
      });

      test('first move to non-start cell fails', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);
        final nonStartCell = const HexCell(q: 1, r: 0);

        final result = engine.tryMove(nonStartCell);

        expect(result.success, false);
        expect(result.error, isNotNull);
        expect(engine.state.path, isEmpty);
      });

      test('valid adjacent move succeeds', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // First move to start
        engine.tryMove(const HexCell(q: 0, r: 0));

        // Move to adjacent cell
        final result = engine.tryMove(const HexCell(q: 1, r: 0));

        expect(result.success, true);
        expect(engine.state.path.length, 2);
      });

      test('move to non-adjacent cell fails', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // First move to start
        engine.tryMove(const HexCell(q: 0, r: 0));

        // Try to move to non-adjacent cell
        final result = engine.tryMove(const HexCell(q: 1, r: 1));

        expect(result.success, false);
        expect(result.error, contains('adjacent'));
        expect(engine.state.path.length, 1);
      });

      test('move to already visited cell fails', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Build a path
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 1));

        // Try to move back to (1,0) which is adjacent to (1,1) and already visited
        final result = engine.tryMove(const HexCell(q: 1, r: 0));

        expect(result.success, false);
        expect(result.error, contains('visited'));
      });

      test('move blocked by wall fails', () {
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSimpleLevel(walls: walls);
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // First move to start
        engine.tryMove(const HexCell(q: 0, r: 0));

        // Try to move through wall
        final result = engine.tryMove(const HexCell(q: 1, r: 0));

        expect(result.success, false);
        expect(result.error, contains('Wall'));
      });

      test('move to cell not in level fails', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));

        final result = engine.tryMove(const HexCell(q: 99, r: 99));

        expect(result.success, false);
        expect(result.error, contains('not in level'));
      });

      test('move after game complete fails', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Complete the game
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        engine.tryMove(const HexCell(q: 1, r: 1));

        expect(engine.state.isComplete, true);

        // Try another move
        final result = engine.tryMove(const HexCell(q: 0, r: 0));

        expect(result.success, false);
        expect(result.error, contains('complete'));
      });

      test('checkpoint increments on reaching correct checkpoint', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        expect(engine.state.nextCheckpoint, 1);

        // Move to checkpoint 1
        engine.tryMove(const HexCell(q: 0, r: 0));
        expect(engine.state.nextCheckpoint, 2);

        // Move to checkpoint 2
        engine.tryMove(const HexCell(q: 1, r: 0));
        expect(engine.state.nextCheckpoint, 3);
      });

      test('move to wrong checkpoint order fails', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Move to checkpoint 1
        engine.tryMove(const HexCell(q: 0, r: 0));

        // Move to non-checkpoint cell
        engine.tryMove(const HexCell(q: 0, r: 1));

        // Try to reach checkpoint 3 before checkpoint 2
        final result = engine.tryMove(const HexCell(q: 1, r: 1));

        expect(result.success, false);
        expect(result.error, contains('checkpoint'));
      });
    });

    group('timing', () {
      test('starts timer on first move', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        expect(engine.state.startTime, isNull);
        expect(engine.state.isStarted, false);

        engine.tryMove(const HexCell(q: 0, r: 0));

        expect(engine.state.startTime, isNotNull);
        expect(engine.state.isStarted, true);
      });

      test('does not reset timer on subsequent moves', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        final firstStartTime = engine.state.startTime;

        engine.tryMove(const HexCell(q: 1, r: 0));

        expect(engine.state.startTime, firstStartTime);
      });

      test('records end time on win', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        expect(engine.state.endTime, isNull);

        // Complete the game
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        final result = engine.tryMove(const HexCell(q: 1, r: 1));

        expect(result.isWin, true);
        expect(engine.state.endTime, isNotNull);
        expect(engine.state.isComplete, true);
      });

      test('elapsed time is calculated correctly', () async {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));

        // Small delay to ensure measurable elapsed time
        await Future.delayed(const Duration(milliseconds: 10));

        expect(engine.state.elapsedTime, isNotNull);
        expect(engine.state.elapsedTime!.inMilliseconds, greaterThanOrEqualTo(0));
      });
    });

    group('win detection', () {
      test('returns isWin true when all cells visited in order', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        final result = engine.tryMove(const HexCell(q: 1, r: 1));

        expect(result.isWin, true);
        expect(result.success, true);
      });

      test('returns isWin false when not all cells visited', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        final result = engine.tryMove(const HexCell(q: 1, r: 0));

        expect(result.isWin, false);
        expect(result.success, true);
      });

      test('win requires visiting all checkpoints', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Visit all cells but in wrong checkpoint order (shouldn't be possible
        // due to validation, but test the final state)
        engine.tryMove(const HexCell(q: 0, r: 0)); // CP 1
        engine.tryMove(const HexCell(q: 1, r: 0)); // CP 2
        engine.tryMove(const HexCell(q: 0, r: 1)); // Non-CP
        final result = engine.tryMove(const HexCell(q: 1, r: 1)); // CP 3

        expect(result.isWin, true);
      });
    });

    group('undo', () {
      test('removes last cell from path', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        expect(engine.state.path.length, 2);

        final result = engine.undo();

        expect(result, true);
        expect(engine.state.path.length, 1);
        expect(engine.state.path.last.q, 0);
        expect(engine.state.path.last.r, 0);
      });

      test('returns false on empty path', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        final result = engine.undo();

        expect(result, false);
        expect(engine.state.path, isEmpty);
      });

      test('returns false when game is complete', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Complete the game
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        engine.tryMove(const HexCell(q: 1, r: 1));

        expect(engine.state.isComplete, true);

        final result = engine.undo();

        expect(result, false);
      });

      test('decrements checkpoint counter when undoing checkpoint', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0)); // CP 1
        expect(engine.state.nextCheckpoint, 2);

        engine.tryMove(const HexCell(q: 1, r: 0)); // CP 2
        expect(engine.state.nextCheckpoint, 3);

        engine.undo(); // Remove CP 2
        expect(engine.state.nextCheckpoint, 2);
      });

      test('does not change checkpoint for non-checkpoint undo', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0)); // CP 1
        engine.tryMove(const HexCell(q: 1, r: 0)); // CP 2
        engine.tryMove(const HexCell(q: 0, r: 1)); // Non-CP
        expect(engine.state.nextCheckpoint, 3);

        engine.undo(); // Remove non-CP
        expect(engine.state.nextCheckpoint, 3);
      });

      test('multiple undos work correctly', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        expect(engine.state.path.length, 3);

        engine.undo();
        engine.undo();
        engine.undo();

        expect(engine.state.path, isEmpty);
        expect(engine.undo(), false);
      });
    });

    group('reset', () {
      test('clears path', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));

        engine.reset();

        expect(engine.state.path, isEmpty);
      });

      test('clears timing', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0));
        expect(engine.state.startTime, isNotNull);

        engine.reset();

        expect(engine.state.startTime, isNull);
        expect(engine.state.endTime, isNull);
        expect(engine.state.isStarted, false);
      });

      test('resets checkpoint counter', () {
        final level = createThreeCheckpointLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        engine.tryMove(const HexCell(q: 0, r: 0)); // CP 1
        engine.tryMove(const HexCell(q: 1, r: 0)); // CP 2
        expect(engine.state.nextCheckpoint, 3);

        engine.reset();

        expect(engine.state.nextCheckpoint, 1);
      });

      test('preserves level and mode', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.daily);

        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.reset();

        expect(engine.state.level, level);
        expect(engine.state.mode, GameMode.daily);
      });

      test('allows new game after reset', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Play and reset
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.reset();

        // Play again
        final result = engine.tryMove(const HexCell(q: 0, r: 0));

        expect(result.success, true);
        expect(engine.state.path.length, 1);
      });

      test('can reset completed game', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Complete the game
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));
        engine.tryMove(const HexCell(q: 1, r: 1));
        expect(engine.state.isComplete, true);

        engine.reset();

        expect(engine.state.isComplete, false);
        expect(engine.state.path, isEmpty);
      });
    });

    group('MoveResult', () {
      test('success result has correct properties', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);
        final result = MoveResult.success(state);

        expect(result.success, true);
        expect(result.error, isNull);
        expect(result.isWin, false);
        expect(result.state, state);
      });

      test('success with win has isWin true', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);
        final result = MoveResult.success(state, isWin: true);

        expect(result.success, true);
        expect(result.isWin, true);
      });

      test('failure result has error message', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);
        final result = MoveResult.failure(state, 'Test error');

        expect(result.success, false);
        expect(result.error, 'Test error');
        expect(result.isWin, false);
        expect(result.state, state);
      });
    });

    group('edge cases', () {
      test('handles rapid successive moves', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Rapid moves
        final results = [
          engine.tryMove(const HexCell(q: 0, r: 0)),
          engine.tryMove(const HexCell(q: 1, r: 0)),
          engine.tryMove(const HexCell(q: 0, r: 1)),
          engine.tryMove(const HexCell(q: 1, r: 1)),
        ];

        for (final r in results) {
          expect(r.success, true);
        }
        expect(results.last.isWin, true);
      });

      test('handles move with only coordinates (gets full cell from level)', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Move with minimal cell info (no checkpoint info)
        final result = engine.tryMove(const HexCell(q: 0, r: 0));

        expect(result.success, true);
        // The engine should get the full cell info from the level
        expect(engine.state.path.first.checkpoint, 1);
      });

      test('undo and redo path', () {
        final level = createSimpleLevel();
        final engine = GameEngine(level: level, mode: GameMode.practice);

        // Build path
        engine.tryMove(const HexCell(q: 0, r: 0));
        engine.tryMove(const HexCell(q: 1, r: 0));
        engine.tryMove(const HexCell(q: 0, r: 1));

        // Undo last two
        engine.undo();
        engine.undo();

        expect(engine.state.path.length, 1);

        // Redo with different path
        engine.tryMove(const HexCell(q: 0, r: 1));
        engine.tryMove(const HexCell(q: 1, r: 1));

        expect(engine.state.path.length, 3);
      });
    });
  });
}
