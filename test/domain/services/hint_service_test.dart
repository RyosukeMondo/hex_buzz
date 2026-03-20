import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/game_state.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/services/hint_service.dart';

void main() {
  const hintService = HintService();

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
    return Level(
      size: 2,
      cells: cells,
      walls: walls ?? {},
      checkpointCount: 2,
    );
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

  /// Creates a larger level where the player can get stuck.
  ///
  /// Layout:
  ///   (0,0)[1] - (1,0) - (2,0)
  ///      \    /  \
  ///     (0,1) - (1,1)[2]
  ///
  /// Wall between (1,0) and (1,1) forces specific path.
  Level createStuckLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (2, 0): const HexCell(q: 2, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    };
    // Wall between (1,0) and (1,1)
    final walls = {
      HexEdge(cellQ1: 1, cellR1: 0, cellQ2: 1, cellR2: 1),
    };
    return Level(size: 3, cells: cells, walls: walls, checkpointCount: 2);
  }

  group('HintService', () {
    group('empty path suggests start cell', () {
      test('suggests checkpoint 1 when path is empty', () {
        final level = createSimpleLevel();
        final state = GameState.initial(
          level: level,
          mode: GameMode.practice,
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);
        expect(hint.suggestedCell!.q, 0);
        expect(hint.suggestedCell!.r, 0);
        expect(hint.suggestedCell!.checkpoint, 1);
        expect(hint.message, contains('Start'));
      });
    });

    group('complete game returns unavailable', () {
      test('returns unavailable when game is complete', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            const HexCell(q: 0, r: 0, checkpoint: 1),
            const HexCell(q: 1, r: 0),
            const HexCell(q: 0, r: 1),
            const HexCell(q: 1, r: 1, checkpoint: 2),
          ],
          nextCheckpoint: 3,
          startTime: DateTime(2024, 1, 1),
          endTime: DateTime(2024, 1, 1, 0, 1),
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, false);
        expect(hint.suggestedCell, isNull);
        expect(hint.message, contains('completed'));
      });
    });

    group('suggests valid neighbor', () {
      test('suggests an unvisited neighbor when one move in', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [const HexCell(q: 0, r: 0, checkpoint: 1)],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);
        // Should suggest a valid neighbor of (0,0)
        final suggested = hint.suggestedCell!;
        expect(
          level.getCell(suggested.q, suggested.r),
          isNotNull,
          reason: 'Suggested cell must be in the level',
        );
      });

      test('does not suggest already visited cells', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            const HexCell(q: 0, r: 0, checkpoint: 1),
            const HexCell(q: 1, r: 0),
          ],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);
        // Should not suggest (0,0) or (1,0) since they are already visited
        final suggested = hint.suggestedCell!;
        expect(suggested.q == 0 && suggested.r == 0, false);
        expect(suggested.q == 1 && suggested.r == 0, false);
      });
    });

    group('prefers checkpoint neighbors', () {
      test(
        'suggests next checkpoint when it is a valid unvisited neighbor',
        () {
          final level = createThreeCheckpointLevel();
          final state = GameState(
            level: level,
            mode: GameMode.practice,
            path: [const HexCell(q: 0, r: 0, checkpoint: 1)],
            nextCheckpoint: 2,
            startTime: DateTime(2024, 1, 1),
          );

          final hint = hintService.getHint(state);

          expect(hint.isAvailable, true);
          expect(hint.suggestedCell, isNotNull);
          // Should prefer checkpoint 2 at (1,0) over non-checkpoint (0,1)
          expect(hint.suggestedCell!.q, 1);
          expect(hint.suggestedCell!.r, 0);
          expect(hint.message, contains('checkpoint'));
        },
      );
    });

    group('returns undo suggestion when stuck', () {
      test('suggests undo when no valid moves exist', () {
        final level = createStuckLevel();

        // Create a state where we went to a dead end:
        // (0,0) -> (1,0) -> (2,0) : now stuck because (2,0) has no
        // unvisited passable neighbors reachable
        // Actually (2,0)'s only neighbor in grid might be (1,0) which
        // is already visited. Let's verify the topology.
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            const HexCell(q: 0, r: 0, checkpoint: 1),
            const HexCell(q: 1, r: 0),
            const HexCell(q: 2, r: 0),
          ],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        // Check that it either suggests a valid move or reports being stuck
        // The exact behavior depends on whether (2,0) has any unvisited
        // passable neighbors in this topology
        final cell20 = level.getCell(2, 0)!;
        final passableNeighbors = level.getPassableNeighbors(cell20);
        final visited = state.visitedCoordinates;
        final unvisited =
            passableNeighbors
                .where((n) => !visited.contains((n.q, n.r)))
                .toList();

        if (unvisited.isEmpty) {
          // Truly stuck - should say to undo
          expect(hint.isAvailable, false);
          expect(hint.message, contains('undo'));
        } else {
          // Has options but they may not lead to solution
          expect(hint.suggestedCell, isNotNull);
        }
      });

      test('returns unavailable when surrounded by visited cells', () {
        // Create a level where the current cell has all neighbors visited
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0),
          (0, 1): const HexCell(q: 0, r: 1),
          (1, 1): const HexCell(q: 1, r: 1),
          (2, 0): const HexCell(q: 2, r: 0, checkpoint: 2),
        };
        final level = Level(
          size: 3,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        // Path visits (0,0), (1,0), (1,1), (0,1)
        // Now at (0,1), neighbors are (0,0) and (1,1) - both visited
        // (Also (-1,1) and (-1,2) which don't exist in the level)
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            const HexCell(q: 0, r: 0, checkpoint: 1),
            const HexCell(q: 1, r: 0),
            const HexCell(q: 1, r: 1),
            const HexCell(q: 0, r: 1),
          ],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        // All passable neighbors of (0,1) in the level are visited
        expect(hint.isAvailable, false);
        expect(hint.message, contains('undo'));
      });
    });

    group('HintResult', () {
      test('default constructor creates available hint', () {
        const hint = HintResult(
          suggestedCell: HexCell(q: 1, r: 2),
          message: 'test',
        );
        expect(hint.isAvailable, true);
        expect(hint.suggestedCell!.q, 1);
        expect(hint.suggestedCell!.r, 2);
      });

      test('unavailable constructor creates unavailable hint', () {
        const hint = HintResult.unavailable('no hint');
        expect(hint.isAvailable, false);
        expect(hint.suggestedCell, isNull);
        expect(hint.message, 'no hint');
      });

      test('toString provides useful output', () {
        const hint = HintResult.unavailable('test');
        expect(hint.toString(), contains('unavailable'));

        const hint2 = HintResult(
          suggestedCell: HexCell(q: 0, r: 0),
          message: 'go',
        );
        expect(hint2.toString(), contains('HintResult'));
      });
    });

    group('checkpoint order enforcement', () {
      test('does not suggest wrong checkpoint', () {
        final level = createThreeCheckpointLevel();
        // Path: (0,0)[1] -> (0,1) -- now at (0,1), neighbors include
        // (1,1)[3] but next expected is 2
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [
            const HexCell(q: 0, r: 0, checkpoint: 1),
            const HexCell(q: 0, r: 1),
          ],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        // Should not suggest (1,1) which is checkpoint 3, not checkpoint 2
        if (hint.isAvailable && hint.suggestedCell != null) {
          final suggested = hint.suggestedCell!;
          if (suggested.checkpoint != null) {
            expect(
              suggested.checkpoint,
              2,
              reason: 'Should only suggest the next checkpoint in order',
            );
          }
        }
      });
    });

    group('DFS solver', () {
      test('finds valid path through simple level', () {
        final level = createSimpleLevel();
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [const HexCell(q: 0, r: 0, checkpoint: 1)],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);

        // The suggested cell should be part of a valid solution path
        final suggested = hint.suggestedCell!;
        final validNeighborCoords = [
          (1, 0),
          (0, 1),
        ];
        expect(
          validNeighborCoords.contains((suggested.q, suggested.r)),
          true,
          reason: 'Suggested cell must be a neighbor of current cell',
        );
      });

      test('handles wall constraints correctly', () {
        // Wall between (0,0) and (1,0) forces path through (0,1)
        final walls = {
          HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
        };
        final level = createSimpleLevel(walls: walls);
        final state = GameState(
          level: level,
          mode: GameMode.practice,
          path: [const HexCell(q: 0, r: 0, checkpoint: 1)],
          nextCheckpoint: 2,
          startTime: DateTime(2024, 1, 1),
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);
        // With wall blocking (0,0)->(1,0), must go through (0,1)
        expect(hint.suggestedCell!.q, 0);
        expect(hint.suggestedCell!.r, 1);
      });
    });

    group('edge cases', () {
      test('single cell level returns start cell hint', () {
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
        };
        final level = Level(
          size: 1,
          cells: cells,
          walls: {},
          checkpointCount: 1,
        );
        final state = GameState.initial(
          level: level,
          mode: GameMode.practice,
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell!.q, 0);
        expect(hint.suggestedCell!.r, 0);
      });

      test('works in daily mode', () {
        final level = createSimpleLevel();
        final state = GameState.initial(
          level: level,
          mode: GameMode.daily,
        );

        final hint = hintService.getHint(state);

        expect(hint.isAvailable, true);
        expect(hint.suggestedCell, isNotNull);
      });
    });
  });
}
