import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/game_state.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/services/path_validator.dart';

void main() {
  late PathValidator validator;

  setUp(() {
    validator = const PathValidator();
  });

  /// Creates a simple 2x2 level for testing.
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

  group('PathValidator', () {
    group('isAdjacent', () {
      test('returns true for horizontally adjacent cells', () {
        final a = const HexCell(q: 0, r: 0);
        final b = const HexCell(q: 1, r: 0);

        expect(validator.isAdjacent(a, b), true);
      });

      test('returns true for diagonally adjacent cells', () {
        final a = const HexCell(q: 0, r: 0);
        final b = const HexCell(q: 0, r: 1);

        expect(validator.isAdjacent(a, b), true);
      });

      test('returns true for all 6 neighbor directions', () {
        final center = const HexCell(q: 2, r: 2);
        final neighbors = [
          const HexCell(q: 3, r: 2), // East
          const HexCell(q: 3, r: 1), // Northeast
          const HexCell(q: 2, r: 1), // Northwest
          const HexCell(q: 1, r: 2), // West
          const HexCell(q: 1, r: 3), // Southwest
          const HexCell(q: 2, r: 3), // Southeast
        ];

        for (final neighbor in neighbors) {
          expect(
            validator.isAdjacent(center, neighbor),
            true,
            reason: 'Expected (${neighbor.q}, ${neighbor.r}) to be adjacent',
          );
        }
      });

      test('returns false for non-adjacent cells', () {
        final a = const HexCell(q: 0, r: 0);
        final b = const HexCell(q: 2, r: 0);

        expect(validator.isAdjacent(a, b), false);
      });

      test('returns false for same cell', () {
        final a = const HexCell(q: 1, r: 1);
        final b = const HexCell(q: 1, r: 1);

        expect(validator.isAdjacent(a, b), false);
      });

      test('returns false for diagonal non-adjacent cells', () {
        final a = const HexCell(q: 0, r: 0);
        final b = const HexCell(q: 2, r: 2);

        expect(validator.isAdjacent(a, b), false);
      });
    });

    group('isPassable', () {
      test('returns true when no wall exists', () {
        final level = createSimpleLevel();
        final from = const HexCell(q: 0, r: 0);
        final to = const HexCell(q: 1, r: 0);

        expect(validator.isPassable(level, from, to), true);
      });

      test('returns false when wall blocks path', () {
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSimpleLevel(walls: walls);
        final from = const HexCell(q: 0, r: 0);
        final to = const HexCell(q: 1, r: 0);

        expect(validator.isPassable(level, from, to), false);
      });

      test('wall check is symmetric', () {
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSimpleLevel(walls: walls);
        final from = const HexCell(q: 0, r: 0);
        final to = const HexCell(q: 1, r: 0);

        expect(validator.isPassable(level, from, to), false);
        expect(validator.isPassable(level, to, from), false);
      });

      test('returns true for path not blocked by wall', () {
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSimpleLevel(walls: walls);
        final from = const HexCell(q: 0, r: 0);
        final to = const HexCell(q: 0, r: 1);

        expect(validator.isPassable(level, from, to), true);
      });
    });

    group('isValidMove', () {
      test('first move must be start cell', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);
        final startCell = const HexCell(q: 0, r: 0, checkpoint: 1);

        final result = validator.isValidMove(state, startCell);

        expect(result.isValid, true);
      });

      test('first move to non-start cell is invalid', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);
        final nonStart = const HexCell(q: 1, r: 0);

        final result = validator.isValidMove(state, nonStart);

        expect(result.isValid, false);
        expect(result.reason, 'First move must be start cell');
      });

      test('valid adjacent move without wall', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 1, r: 0);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, true);
      });

      test('move blocked by wall is invalid', () {
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSimpleLevel(walls: walls);
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 1, r: 0);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, false);
        expect(result.reason, 'Wall blocks movement');
      });

      test('move to non-adjacent cell is invalid', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 1, r: 1);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, false);
        expect(result.reason, 'Target not adjacent');
      });

      test('move to already visited cell is invalid', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!, level.getCell(1, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 0, r: 0);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, false);
        expect(result.reason, 'Cell already visited');
      });

      test('move to correct checkpoint is valid', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!, level.getCell(1, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 1, r: 1, checkpoint: 2);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, true);
      });

      test('move to wrong checkpoint order is invalid', () {
        // Create a level with 3 checkpoints
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0, checkpoint: 3),
          (0, 1): const HexCell(q: 0, r: 1, checkpoint: 2),
          (1, 1): const HexCell(q: 1, r: 1),
        };
        final level = Level(
          size: 2,
          cells: cells,
          walls: {},
          checkpointCount: 3,
        );

        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        // Try to move to checkpoint 3 when checkpoint 2 is expected
        final target = const HexCell(q: 1, r: 0, checkpoint: 3);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, false);
        expect(result.reason, contains('Wrong checkpoint order'));
      });

      test('move to cell not in level is invalid', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 99, r: 99);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, false);
        expect(result.reason, 'Target cell not in level');
      });

      test('move to non-checkpoint adjacent cell is valid', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!],
          nextCheckpoint: 2,
        );
        final target = const HexCell(q: 0, r: 1);

        final result = validator.isValidMove(state, target);

        expect(result.isValid, true);
      });
    });

    group('checkWinCondition', () {
      test(
        'returns win when all cells visited and all checkpoints reached',
        () {
          final level = createSimpleLevel();
          final state = GameState(
            level: level,
            mode: GameMode.practice,
            path: [
              level.getCell(0, 0)!,
              level.getCell(1, 0)!,
              level.getCell(0, 1)!,
              level.getCell(1, 1)!,
            ],
            nextCheckpoint: 3, // Past checkpoint count (2)
          );

          final result = validator.checkWinCondition(state);

          expect(result.isWin, true);
          expect(result.reason, isNull);
        },
      );

      test('not win when not all cells visited', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [level.getCell(0, 0)!, level.getCell(1, 0)!],
          nextCheckpoint: 2,
        );

        final result = validator.checkWinCondition(state);

        expect(result.isWin, false);
        expect(result.reason, contains('Not all cells visited'));
      });

      test('not win when checkpoints not all reached', () {
        final level = createSimpleLevel();
        // All cells visited but nextCheckpoint hasn't passed checkpointCount
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            level.getCell(0, 0)!,
            level.getCell(1, 0)!,
            level.getCell(0, 1)!,
            level.getCell(1, 1)!,
          ],
          nextCheckpoint: 2, // Still need to reach checkpoint 2
        );

        final result = validator.checkWinCondition(state);

        expect(result.isWin, false);
        expect(result.reason, contains('Not all checkpoints reached'));
      });

      test('not win with empty path', () {
        final level = createSimpleLevel();
        final state = GameState.initial(level: level, mode: GameMode.practice);

        final result = validator.checkWinCondition(state);

        expect(result.isWin, false);
      });
    });

    group('WinCheckResult', () {
      test('win result has no reason', () {
        const result = WinCheckResult.win();

        expect(result.isWin, true);
        expect(result.reason, isNull);
      });

      test('not win result has reason', () {
        const result = WinCheckResult.notWin('Some reason');

        expect(result.isWin, false);
        expect(result.reason, 'Some reason');
      });
    });

    group('MoveValidationResult', () {
      test('valid result has no reason', () {
        const result = MoveValidationResult.valid();

        expect(result.isValid, true);
        expect(result.reason, isNull);
      });

      test('invalid result has reason', () {
        const result = MoveValidationResult.invalid('Some reason');

        expect(result.isValid, false);
        expect(result.reason, 'Some reason');
      });
    });
  });
}
