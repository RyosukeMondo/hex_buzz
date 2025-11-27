import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/hex_cell.dart';

void main() {
  group('HexCell', () {
    group('construction', () {
      test('creates cell with required coordinates', () {
        final cell = HexCell(q: 1, r: 2);

        expect(cell.q, 1);
        expect(cell.r, 2);
        expect(cell.checkpoint, isNull);
        expect(cell.visited, false);
      });

      test('creates cell with checkpoint', () {
        final cell = HexCell(q: 0, r: 0, checkpoint: 1);

        expect(cell.checkpoint, 1);
      });

      test('creates cell with visited flag', () {
        final cell = HexCell(q: 0, r: 0, visited: true);

        expect(cell.visited, true);
      });
    });

    group('copyWith', () {
      test('copies with new visited state', () {
        final cell = HexCell(q: 1, r: 2, checkpoint: 3);
        final copy = cell.copyWith(visited: true);

        expect(copy.q, 1);
        expect(copy.r, 2);
        expect(copy.checkpoint, 3);
        expect(copy.visited, true);
      });

      test('copies with new coordinates', () {
        final cell = HexCell(q: 1, r: 2);
        final copy = cell.copyWith(q: 5, r: 6);

        expect(copy.q, 5);
        expect(copy.r, 6);
      });
    });

    group('toPixel', () {
      test('converts origin to pixel (0, 0)', () {
        final cell = HexCell(q: 0, r: 0);
        final pixel = cell.toPixel(10.0);

        expect(pixel.x, closeTo(0.0, 0.001));
        expect(pixel.y, closeTo(0.0, 0.001));
      });

      test('converts q=1, r=0 correctly for flat-top hex', () {
        final cell = HexCell(q: 1, r: 0);
        final pixel = cell.toPixel(10.0);

        // For flat-top: x = size * 3/2 * q
        expect(pixel.x, closeTo(15.0, 0.001));
        // y = size * (sqrt(3)/2 * q + sqrt(3) * r)
        expect(pixel.y, closeTo(8.660, 0.01));
      });

      test('converts q=0, r=1 correctly for flat-top hex', () {
        final cell = HexCell(q: 0, r: 1);
        final pixel = cell.toPixel(10.0);

        expect(pixel.x, closeTo(0.0, 0.001));
        // y = size * sqrt(3) * r
        expect(pixel.y, closeTo(17.32, 0.01));
      });

      test('converts negative coordinates correctly', () {
        final cell = HexCell(q: -1, r: -1);
        final pixel = cell.toPixel(10.0);

        expect(pixel.x, closeTo(-15.0, 0.001));
        expect(pixel.y, closeTo(-25.98, 0.01));
      });
    });

    group('neighbors', () {
      test('returns 6 neighbors', () {
        final cell = HexCell(q: 0, r: 0);
        final neighbors = cell.neighbors;

        expect(neighbors.length, 6);
      });

      test('returns correct neighbors for origin', () {
        final cell = HexCell(q: 0, r: 0);
        final neighbors = cell.neighbors;

        expect(neighbors, containsAll([
          (q: 1, r: 0),     // East
          (q: 1, r: -1),    // Northeast
          (q: 0, r: -1),    // Northwest
          (q: -1, r: 0),    // West
          (q: -1, r: 1),    // Southwest
          (q: 0, r: 1),     // Southeast
        ]));
      });

      test('returns correct neighbors for non-origin cell', () {
        final cell = HexCell(q: 2, r: 3);
        final neighbors = cell.neighbors;

        expect(neighbors, containsAll([
          (q: 3, r: 3),
          (q: 3, r: 2),
          (q: 2, r: 2),
          (q: 1, r: 3),
          (q: 1, r: 4),
          (q: 2, r: 4),
        ]));
      });
    });

    group('isAdjacentTo', () {
      test('returns true for adjacent cells', () {
        final cell = HexCell(q: 0, r: 0);
        final neighbor = HexCell(q: 1, r: 0);

        expect(cell.isAdjacentTo(neighbor), true);
      });

      test('returns true for all 6 neighbor directions', () {
        final cell = HexCell(q: 2, r: 2);
        final directions = [
          HexCell(q: 3, r: 2),
          HexCell(q: 3, r: 1),
          HexCell(q: 2, r: 1),
          HexCell(q: 1, r: 2),
          HexCell(q: 1, r: 3),
          HexCell(q: 2, r: 3),
        ];

        for (final neighbor in directions) {
          expect(cell.isAdjacentTo(neighbor), true,
              reason: 'Expected ($cell) to be adjacent to ($neighbor)');
        }
      });

      test('returns false for non-adjacent cells', () {
        final cell = HexCell(q: 0, r: 0);
        final farCell = HexCell(q: 2, r: 0);

        expect(cell.isAdjacentTo(farCell), false);
      });

      test('returns false for same cell', () {
        final cell = HexCell(q: 1, r: 1);
        final sameCell = HexCell(q: 1, r: 1);

        expect(cell.isAdjacentTo(sameCell), false);
      });

      test('returns false for diagonal cells', () {
        final cell = HexCell(q: 0, r: 0);
        final diagonal = HexCell(q: 1, r: 1);

        expect(cell.isAdjacentTo(diagonal), false);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final cell = HexCell(q: 1, r: 2, checkpoint: 3, visited: true);
        final json = cell.toJson();

        expect(json['q'], 1);
        expect(json['r'], 2);
        expect(json['checkpoint'], 3);
        expect(json['visited'], true);
      });

      test('toJson excludes null checkpoint', () {
        final cell = HexCell(q: 1, r: 2);
        final json = cell.toJson();

        expect(json.containsKey('checkpoint'), false);
      });

      test('fromJson creates correct cell', () {
        final json = {'q': 1, 'r': 2, 'checkpoint': 3, 'visited': true};
        final cell = HexCell.fromJson(json);

        expect(cell.q, 1);
        expect(cell.r, 2);
        expect(cell.checkpoint, 3);
        expect(cell.visited, true);
      });

      test('fromJson handles missing optional fields', () {
        final json = {'q': 1, 'r': 2};
        final cell = HexCell.fromJson(json);

        expect(cell.checkpoint, isNull);
        expect(cell.visited, false);
      });

      test('JSON round-trip preserves data', () {
        final original = HexCell(q: -3, r: 5, checkpoint: 2, visited: true);
        final json = original.toJson();
        final restored = HexCell.fromJson(json);

        expect(restored.q, original.q);
        expect(restored.r, original.r);
        expect(restored.checkpoint, original.checkpoint);
        expect(restored.visited, original.visited);
      });
    });

    group('equality', () {
      test('cells with same coordinates are equal', () {
        final cell1 = HexCell(q: 1, r: 2);
        final cell2 = HexCell(q: 1, r: 2);

        expect(cell1, equals(cell2));
      });

      test('cells with same coordinates but different checkpoint are equal', () {
        final cell1 = HexCell(q: 1, r: 2, checkpoint: 1);
        final cell2 = HexCell(q: 1, r: 2, checkpoint: 2);

        // Equality is based on position only
        expect(cell1, equals(cell2));
      });

      test('cells with same coordinates but different visited are equal', () {
        final cell1 = HexCell(q: 1, r: 2, visited: false);
        final cell2 = HexCell(q: 1, r: 2, visited: true);

        expect(cell1, equals(cell2));
      });

      test('cells with different coordinates are not equal', () {
        final cell1 = HexCell(q: 1, r: 2);
        final cell2 = HexCell(q: 2, r: 1);

        expect(cell1, isNot(equals(cell2)));
      });

      test('hashCode is consistent for equal cells', () {
        final cell1 = HexCell(q: 1, r: 2);
        final cell2 = HexCell(q: 1, r: 2);

        expect(cell1.hashCode, equals(cell2.hashCode));
      });
    });

    group('toString', () {
      test('basic cell', () {
        final cell = HexCell(q: 1, r: 2);
        expect(cell.toString(), 'HexCell(1, 2)');
      });

      test('cell with checkpoint', () {
        final cell = HexCell(q: 1, r: 2, checkpoint: 3);
        expect(cell.toString(), 'HexCell(1, 2, checkpoint: 3)');
      });

      test('visited cell', () {
        final cell = HexCell(q: 1, r: 2, visited: true);
        expect(cell.toString(), 'HexCell(1, 2, visited)');
      });

      test('visited cell with checkpoint', () {
        final cell = HexCell(q: 1, r: 2, checkpoint: 1, visited: true);
        expect(cell.toString(), 'HexCell(1, 2, checkpoint: 1, visited)');
      });
    });
  });
}
