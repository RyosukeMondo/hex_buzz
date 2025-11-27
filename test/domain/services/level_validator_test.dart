import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/hex_cell.dart';
import 'package:honeycomb_one_pass/domain/models/hex_edge.dart';
import 'package:honeycomb_one_pass/domain/models/level.dart';
import 'package:honeycomb_one_pass/domain/services/level_validator.dart';

void main() {
  late LevelValidator validator;

  setUp(() {
    validator = const LevelValidator();
  });

  /// Creates a simple 2x2 solvable level.
  ///
  /// Layout (flat-top hexagons):
  ///   (0,0)[1] - (1,0)
  ///      \    /  \
  ///     (0,1) - (1,1)[2]
  ///
  /// Checkpoint 1 at (0,0), Checkpoint 2 at (1,1)
  /// Solution: (0,0) -> (1,0) -> (1,1) -> (0,1) or other valid paths
  Level createSolvableLevel({Set<HexEdge>? walls}) {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    };
    return Level(size: 2, cells: cells, walls: walls ?? {}, checkpointCount: 2);
  }

  /// Creates an unsolvable level where walls block all paths.
  ///
  /// Layout with walls blocking:
  ///   (0,0)[1] | (1,0)
  ///      |   /  |
  ///     (0,1) - (1,1)[2]
  ///
  /// Walls isolate (0,0) from (0,1) and (0,0) from (1,0)
  Level createUnsolvableLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    };
    // Block all exits from start cell
    final walls = {
      HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
      HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 0, cellR2: 1),
    };
    return Level(size: 2, cells: cells, walls: walls, checkpointCount: 2);
  }

  /// Creates a level with 3 checkpoints requiring specific order.
  ///
  /// Layout:
  ///   (0,0)[1] - (1,0)[2]
  ///      \    /  \
  ///     (0,1) - (1,1)[3]
  ///
  /// Must visit checkpoints 1 -> 2 -> 3
  Level createThreeCheckpointLevel({Set<HexEdge>? walls}) {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 3),
    };
    return Level(size: 2, cells: cells, walls: walls ?? {}, checkpointCount: 3);
  }

  /// Creates a level where checkpoint order makes it unsolvable.
  ///
  /// Layout (linear, 3 cells):
  ///   (0,0)[1] - (1,0)[3] - (2,0)[2]
  ///
  /// Must visit 1 -> 3 -> 2, but checkpoint order requires 1 -> 2 -> 3
  /// So you must reach (2,0)[2] before (1,0)[3], but (1,0) is in between
  Level createCheckpointOrderUnsolvableLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0, checkpoint: 3),
      (2, 0): const HexCell(q: 2, r: 0, checkpoint: 2),
    };
    return Level(size: 3, cells: cells, walls: {}, checkpointCount: 3);
  }

  group('LevelValidator', () {
    group('validate', () {
      test('returns solvable for simple solvable level', () {
        final level = createSolvableLevel();

        final result = validator.validate(level);

        expect(result.isSolvable, true);
        expect(result.solutionPath, isNotNull);
        expect(result.solutionPath!.length, 4);
        expect(result.error, isNull);
      });

      test('returns unsolvable when walls block all paths', () {
        final level = createUnsolvableLevel();

        final result = validator.validate(level);

        expect(result.isSolvable, false);
        expect(result.solutionPath, isNull);
        expect(result.error, isNotNull);
      });

      test('returns solvable for level with 3 checkpoints', () {
        final level = createThreeCheckpointLevel();

        final result = validator.validate(level);

        expect(result.isSolvable, true);
        expect(result.solutionPath, isNotNull);
      });

      test('returns unsolvable when checkpoint order prevents solution', () {
        final level = createCheckpointOrderUnsolvableLevel();

        final result = validator.validate(level);

        expect(result.isSolvable, false);
      });

      test('returns error for empty level', () {
        final cells = <(int, int), HexCell>{};
        final level = Level(
          size: 0,
          cells: cells,
          walls: {},
          checkpointCount: 0,
        );

        final result = validator.validate(level);

        expect(result.isSolvable, false);
        expect(result.error, contains('no cells'));
      });

      test('returns error for level with only 1 checkpoint', () {
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
        };
        final level = Level(
          size: 1,
          cells: cells,
          walls: {},
          checkpointCount: 1,
        );

        final result = validator.validate(level);

        expect(result.isSolvable, false);
        expect(result.error, contains('at least 2 checkpoints'));
      });

      test('returns error for missing checkpoint', () {
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0),
          // Missing checkpoint 2
        };
        final level = Level(
          size: 2,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final result = validator.validate(level);

        expect(result.isSolvable, false);
        expect(result.error, contains('Missing checkpoint'));
      });
    });

    group('findSolution', () {
      test('finds valid solution for solvable level', () {
        final level = createSolvableLevel();

        final solution = validator.findSolution(level);

        expect(solution, isNotNull);
        expect(solution!.length, 4);
        expect(solution.first.checkpoint, 1); // Starts at checkpoint 1
        expect(solution.last.checkpoint, 2); // Ends at checkpoint 2
      });

      test('solution visits all cells exactly once', () {
        final level = createSolvableLevel();

        final solution = validator.findSolution(level);

        expect(solution, isNotNull);
        final visitedCoords =
            solution!.map((c) => (c.q, c.r)).toSet();
        expect(visitedCoords.length, solution.length);
        expect(visitedCoords.length, level.cells.length);
      });

      test('solution respects checkpoint order', () {
        final level = createThreeCheckpointLevel();

        final solution = validator.findSolution(level);

        expect(solution, isNotNull);

        // Extract checkpoints in order visited
        final checkpointsVisited = solution!
            .where((c) => c.checkpoint != null)
            .map((c) => c.checkpoint!)
            .toList();

        expect(checkpointsVisited, [1, 2, 3]);
      });

      test('solution respects walls', () {
        // Create level with wall between (0,0) and (1,0)
        final walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
        final level = createSolvableLevel(walls: walls);

        final solution = validator.findSolution(level);

        expect(solution, isNotNull);

        // Verify no consecutive cells cross the wall
        for (var i = 0; i < solution!.length - 1; i++) {
          final current = solution[i];
          final next = solution[i + 1];
          final crossesWall =
              (current.q == 0 && current.r == 0 && next.q == 1 && next.r == 0) ||
              (current.q == 1 && current.r == 0 && next.q == 0 && next.r == 0);
          expect(crossesWall, false, reason: 'Solution crosses wall');
        }
      });

      test('returns null for unsolvable level', () {
        final level = createUnsolvableLevel();

        final solution = validator.findSolution(level);

        expect(solution, isNull);
      });

      test('solution path cells are adjacent', () {
        final level = createSolvableLevel();

        final solution = validator.findSolution(level);

        expect(solution, isNotNull);
        for (var i = 0; i < solution!.length - 1; i++) {
          final current = solution[i];
          final next = solution[i + 1];
          expect(
            current.isAdjacentTo(next),
            true,
            reason: 'Cells at index $i and ${i + 1} are not adjacent',
          );
        }
      });
    });

    group('ValidationResult', () {
      test('solvable result has solution path', () {
        final path = [
          const HexCell(q: 0, r: 0),
          const HexCell(q: 1, r: 0),
        ];
        final result = ValidationResult.solvable(path);

        expect(result.isSolvable, true);
        expect(result.solutionPath, path);
        expect(result.error, isNull);
      });

      test('unsolvable result has error', () {
        const result = ValidationResult.unsolvable('No path found');

        expect(result.isSolvable, false);
        expect(result.solutionPath, isNull);
        expect(result.error, 'No path found');
      });

      test('toJson for solvable result', () {
        final path = [
          const HexCell(q: 0, r: 0),
          const HexCell(q: 1, r: 0),
        ];
        final result = ValidationResult.solvable(path);

        final json = result.toJson();

        expect(json['isSolvable'], true);
        expect(json['solutionPath'], isA<List>());
        expect((json['solutionPath'] as List).length, 2);
        expect(json.containsKey('error'), false);
      });

      test('toJson for unsolvable result', () {
        const result = ValidationResult.unsolvable('Test error');

        final json = result.toJson();

        expect(json['isSolvable'], false);
        expect(json.containsKey('solutionPath'), false);
        expect(json['error'], 'Test error');
      });
    });

    group('edge cases', () {
      test('handles single cell level with two checkpoints', () {
        // This is technically invalid (can't have 2 checkpoints on 1 cell)
        // but let's test the validation catches it
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
        };
        final level = Level(
          size: 1,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final result = validator.validate(level);

        expect(result.isSolvable, false);
        expect(result.error, contains('Missing checkpoint'));
      });

      test('handles level where end is not reachable', () {
        // Create a linear level where checkpoint 2 is in the middle
        // making it impossible to visit all cells ending at last checkpoint
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
          (2, 0): const HexCell(q: 2, r: 0),
        };
        final level = Level(
          size: 3,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final result = validator.validate(level);

        // This should still be solvable: 1 -> 2 -> (2,0) is valid
        // as checkpoint 2 doesn't need to be at the end of the path
        expect(result.isSolvable, true);
      });

      test('handles larger grid with multiple solutions', () {
        // 3x3 grid - should have multiple valid Hamiltonian paths
        final cells = <(int, int), HexCell>{
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0),
          (2, 0): const HexCell(q: 2, r: 0),
          (0, 1): const HexCell(q: 0, r: 1),
          (1, 1): const HexCell(q: 1, r: 1),
          (2, 1): const HexCell(q: 2, r: 1),
          (0, 2): const HexCell(q: 0, r: 2),
          (1, 2): const HexCell(q: 1, r: 2),
          (2, 2): const HexCell(q: 2, r: 2, checkpoint: 2),
        };
        final level = Level(
          size: 3,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final result = validator.validate(level);

        expect(result.isSolvable, true);
        expect(result.solutionPath!.length, 9);
      });
    });
  });
}
