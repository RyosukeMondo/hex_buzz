import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/hex_edge.dart';

void main() {
  group('HexEdge', () {
    group('canonical ordering', () {
      test('orders cells by q first, then r', () {
        final edge = HexEdge(cellQ1: 2, cellR1: 1, cellQ2: 1, cellR2: 3);

        expect(edge.q1, 1);
        expect(edge.r1, 3);
        expect(edge.q2, 2);
        expect(edge.r2, 1);
      });

      test('orders by r when q is equal', () {
        final edge = HexEdge(cellQ1: 1, cellR1: 5, cellQ2: 1, cellR2: 2);

        expect(edge.q1, 1);
        expect(edge.r1, 2);
        expect(edge.q2, 1);
        expect(edge.r2, 5);
      });

      test('preserves order when already canonical', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.q1, 0);
        expect(edge.r1, 0);
        expect(edge.q2, 1);
        expect(edge.r2, 0);
      });
    });

    group('equality', () {
      test('edges with same coordinates are equal', () {
        final edge1 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);
        final edge2 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge1, equals(edge2));
        expect(edge1.hashCode, edge2.hashCode);
      });

      test('edges with reversed coordinates are equal', () {
        final edge1 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);
        final edge2 = HexEdge(cellQ1: 1, cellR1: 0, cellQ2: 0, cellR2: 0);

        expect(edge1, equals(edge2));
        expect(edge1.hashCode, edge2.hashCode);
      });

      test('edges with different coordinates are not equal', () {
        final edge1 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);
        final edge2 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 0, cellR2: 1);

        expect(edge1, isNot(equals(edge2)));
      });

      test('works correctly in Set', () {
        final edge1 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);
        final edge2 = HexEdge(cellQ1: 1, cellR1: 0, cellQ2: 0, cellR2: 0);
        final edge3 = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 0, cellR2: 1);

        final walls = <HexEdge>{edge1, edge2, edge3};

        expect(walls.length, 2); // edge1 and edge2 are duplicates
      });
    });

    group('fromCells factory', () {
      test('creates edge from cell records', () {
        final edge = HexEdge.fromCells(
          (q: 2, r: 1),
          (q: 1, r: 1),
        );

        expect(edge.cell1, (q: 1, r: 1));
        expect(edge.cell2, (q: 2, r: 1));
      });
    });

    group('connectsCell', () {
      test('returns true for cell1', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connectsCell(q: 0, r: 0), isTrue);
      });

      test('returns true for cell2', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connectsCell(q: 1, r: 0), isTrue);
      });

      test('returns false for unrelated cell', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connectsCell(q: 2, r: 2), isFalse);
      });
    });

    group('connects', () {
      test('returns true for exact cell pair', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connects(q1: 0, r1: 0, q2: 1, r2: 0), isTrue);
      });

      test('returns true for reversed cell pair', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connects(q1: 1, r1: 0, q2: 0, r2: 0), isTrue);
      });

      test('returns false for different cell pair', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connects(q1: 0, r1: 0, q2: 0, r2: 1), isFalse);
      });

      test('returns false when only one cell matches', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.connects(q1: 0, r1: 0, q2: 2, r2: 2), isFalse);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct structure', () {
        final edge = HexEdge(cellQ1: 2, cellR1: 3, cellQ2: 1, cellR2: 1);
        final json = edge.toJson();

        // Should be in canonical order (1,1) before (2,3)
        expect(json['q1'], 1);
        expect(json['r1'], 1);
        expect(json['q2'], 2);
        expect(json['r2'], 3);
      });

      test('fromJson restores edge correctly', () {
        final json = {'q1': 0, 'r1': 0, 'q2': 1, 'r2': 0};
        final edge = HexEdge.fromJson(json);

        expect(edge.q1, 0);
        expect(edge.r1, 0);
        expect(edge.q2, 1);
        expect(edge.r2, 0);
      });

      test('round-trip preserves edge', () {
        final original = HexEdge(cellQ1: 3, cellR1: 2, cellQ2: 2, cellR2: 2);
        final restored = HexEdge.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('fromJson applies canonical ordering', () {
        // JSON with non-canonical order
        final json = {'q1': 5, 'r1': 5, 'q2': 1, 'r2': 1};
        final edge = HexEdge.fromJson(json);

        // Should reorder to canonical
        expect(edge.q1, 1);
        expect(edge.r1, 1);
        expect(edge.q2, 5);
        expect(edge.r2, 5);
      });
    });

    group('cell getters', () {
      test('cell1 returns smaller cell coordinates', () {
        final edge = HexEdge(cellQ1: 5, cellR1: 5, cellQ2: 1, cellR2: 1);

        expect(edge.cell1, (q: 1, r: 1));
      });

      test('cell2 returns larger cell coordinates', () {
        final edge = HexEdge(cellQ1: 5, cellR1: 5, cellQ2: 1, cellR2: 1);

        expect(edge.cell2, (q: 5, r: 5));
      });
    });

    group('toString', () {
      test('produces readable output', () {
        final edge = HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0);

        expect(edge.toString(), 'HexEdge((0, 0) <-> (1, 0))');
      });
    });
  });
}
