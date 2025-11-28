import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';

void main() {
  group('Level', () {
    late Map<(int, int), HexCell> cells;
    late Set<HexEdge> walls;

    setUp(() {
      // Create a simple 2x2 grid with checkpoints at corners
      cells = {
        (0, 0): HexCell(q: 0, r: 0, checkpoint: 1), // Start
        (1, 0): HexCell(q: 1, r: 0),
        (0, 1): HexCell(q: 0, r: 1),
        (1, 1): HexCell(q: 1, r: 1, checkpoint: 2), // End
      };

      // Add a wall between (0,0) and (1,0)
      walls = {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)};
    });

    group('construction', () {
      test('creates level with required fields', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.size, 2);
        expect(level.cells.length, 4);
        expect(level.walls.length, 1);
        expect(level.checkpointCount, 2);
        expect(level.id, isNotEmpty);
      });

      test('creates level with custom id', () {
        final level = Level(
          id: 'custom-id',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.id, 'custom-id');
      });

      test('cells map is unmodifiable', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(
          () => (level.cells as Map)[const (5, 5)] = HexCell(q: 5, r: 5),
          throwsUnsupportedError,
        );
      });

      test('walls set is unmodifiable', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(
          () => (level.walls as Set).add(
            HexEdge(cellQ1: 0, cellR1: 1, cellQ2: 1, cellR2: 1),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('getCell', () {
      test('returns cell at given coordinates', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final cell = level.getCell(0, 0);

        expect(cell, isNotNull);
        expect(cell!.q, 0);
        expect(cell.r, 0);
        expect(cell.checkpoint, 1);
      });

      test('returns null for non-existent coordinates', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final cell = level.getCell(99, 99);

        expect(cell, isNull);
      });
    });

    group('startCell', () {
      test('returns cell with checkpoint 1', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final start = level.startCell;

        expect(start.q, 0);
        expect(start.r, 0);
        expect(start.checkpoint, 1);
      });

      test('throws if no start cell exists', () {
        final noStartCells = {
          (0, 0): HexCell(q: 0, r: 0),
          (1, 0): HexCell(q: 1, r: 0, checkpoint: 2),
        };

        final level = Level(
          size: 2,
          cells: noStartCells,
          walls: {},
          checkpointCount: 2,
        );

        expect(() => level.startCell, throwsStateError);
      });
    });

    group('endCell', () {
      test('returns cell with last checkpoint', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final end = level.endCell;

        expect(end.q, 1);
        expect(end.r, 1);
        expect(end.checkpoint, 2);
      });

      test('returns correct cell when checkpointCount is 3', () {
        final threeCpCells = {
          (0, 0): HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): HexCell(q: 1, r: 0, checkpoint: 2),
          (0, 1): HexCell(q: 0, r: 1, checkpoint: 3),
        };

        final level = Level(
          size: 2,
          cells: threeCpCells,
          walls: {},
          checkpointCount: 3,
        );

        final end = level.endCell;

        expect(end.q, 0);
        expect(end.r, 1);
        expect(end.checkpoint, 3);
      });

      test('throws if no end cell exists', () {
        final noEndCells = {
          (0, 0): HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): HexCell(q: 1, r: 0),
        };

        final level = Level(
          size: 2,
          cells: noEndCells,
          walls: {},
          checkpointCount: 2,
        );

        expect(() => level.endCell, throwsStateError);
      });
    });

    group('hasWall', () {
      test('returns true when wall exists between cells', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.hasWall(0, 0, 1, 0), true);
      });

      test('returns true regardless of argument order', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        // Wall between (0,0) and (1,0) should be found both ways
        expect(level.hasWall(0, 0, 1, 0), true);
        expect(level.hasWall(1, 0, 0, 0), true);
      });

      test('returns false when no wall exists', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.hasWall(0, 0, 0, 1), false);
      });

      test('returns false for non-adjacent cells', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.hasWall(0, 0, 1, 1), false);
      });
    });

    group('getPassableNeighbors', () {
      test('returns neighbors not blocked by walls', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final cell = level.getCell(0, 0)!;
        final neighbors = level.getPassableNeighbors(cell);

        // (0,0) has neighbors (1,0), (0,1), etc. but (1,0) is blocked by wall
        // Only (0,1) should be passable (if it exists in cells)
        expect(neighbors.any((n) => n.q == 1 && n.r == 0), false);
        expect(neighbors.any((n) => n.q == 0 && n.r == 1), true);
      });

      test('returns only cells that exist in the level', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: {},
          checkpointCount: 2,
        );

        final cell = level.getCell(0, 0)!;
        final neighbors = level.getPassableNeighbors(cell);

        // Only cells within the level's cells map should be returned
        for (final neighbor in neighbors) {
          expect(level.getCell(neighbor.q, neighbor.r), isNotNull);
        }
      });

      test('returns empty list when all neighbors blocked', () {
        // Create walls blocking all neighbors of (0,0)
        final allWalls = {
          HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
          HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 0, cellR2: 1),
        };

        final level = Level(
          size: 2,
          cells: cells,
          walls: allWalls,
          checkpointCount: 2,
        );

        final cell = level.getCell(0, 0)!;
        final neighbors = level.getPassableNeighbors(cell);

        // All adjacent cells in the level are blocked
        expect(neighbors, isEmpty);
      });
    });

    group('computeHash', () {
      test('generates deterministic hash', () {
        final level1 = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final level2 = Level(
          size: 2,
          cells: Map.from(cells),
          walls: Set.from(walls),
          checkpointCount: 2,
        );

        expect(level1.id, level2.id);
      });

      test('different levels have different hashes', () {
        final level1 = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final differentCells = Map.of(cells);
        differentCells[(2, 2)] = HexCell(q: 2, r: 2);

        final level2 = Level(
          size: 3,
          cells: differentCells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level1.id, isNot(level2.id));
      });

      test('hash changes with different walls', () {
        final level1 = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final differentWalls = {
          HexEdge(cellQ1: 0, cellR1: 1, cellQ2: 1, cellR2: 1),
        };

        final level2 = Level(
          size: 2,
          cells: cells,
          walls: differentWalls,
          checkpointCount: 2,
        );

        expect(level1.id, isNot(level2.id));
      });

      test('hash changes with different checkpoint count', () {
        final level1 = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final level2 = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 3,
        );

        expect(level1.id, isNot(level2.id));
      });

      test('hash is 16 characters', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level.id.length, 16);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final json = level.toJson();

        expect(json['id'], level.id);
        expect(json['size'], 2);
        expect(json['checkpointCount'], 2);
        expect(json['cells'], isList);
        expect((json['cells'] as List).length, 4);
        expect(json['walls'], isList);
        expect((json['walls'] as List).length, 1);
      });

      test('fromJson creates correct level', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final json = level.toJson();
        final restored = Level.fromJson(json);

        expect(restored.id, level.id);
        expect(restored.size, 2);
        expect(restored.checkpointCount, 2);
        expect(restored.cells.length, 4);
        expect(restored.walls.length, 1);
      });

      test('JSON round-trip preserves cells', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final json = level.toJson();
        final restored = Level.fromJson(json);

        expect(restored.getCell(0, 0)?.checkpoint, 1);
        expect(restored.getCell(1, 1)?.checkpoint, 2);
        expect(restored.getCell(1, 0)?.checkpoint, isNull);
      });

      test('JSON round-trip preserves walls', () {
        final level = Level(
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final json = level.toJson();
        final restored = Level.fromJson(json);

        expect(restored.hasWall(0, 0, 1, 0), true);
        expect(restored.hasWall(0, 0, 0, 1), false);
      });
    });

    group('equality', () {
      test('levels with same id are equal', () {
        final level1 = Level(
          id: 'test-id',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final level2 = Level(
          id: 'test-id',
          size: 3,
          cells: {},
          walls: {},
          checkpointCount: 1,
        );

        expect(level1, equals(level2));
      });

      test('levels with different ids are not equal', () {
        final level1 = Level(
          id: 'id-1',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final level2 = Level(
          id: 'id-2',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level1, isNot(equals(level2)));
      });

      test('hashCode is consistent with equality', () {
        final level1 = Level(
          id: 'same-id',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final level2 = Level(
          id: 'same-id',
          size: 2,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        expect(level1.hashCode, level2.hashCode);
      });
    });

    group('toString', () {
      test('includes id, size, and counts', () {
        final level = Level(
          id: 'abc123',
          size: 4,
          cells: cells,
          walls: walls,
          checkpointCount: 2,
        );

        final str = level.toString();

        expect(str, contains('abc123'));
        expect(str, contains('size: 4'));
        expect(str, contains('cells: 4'));
        expect(str, contains('walls: 1'));
      });
    });
  });
}
