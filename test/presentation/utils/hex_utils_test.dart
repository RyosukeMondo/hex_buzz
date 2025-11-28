import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/utils/hex_utils.dart';

void main() {
  group('HexUtils', () {
    const cellSize = 30.0;

    group('axialToPixel', () {
      test('converts origin (0,0) to pixel origin', () {
        final pixel = HexUtils.axialToPixel(0, 0, cellSize);
        expect(pixel.dx, closeTo(0, 0.001));
        expect(pixel.dy, closeTo(0, 0.001));
      });

      test('converts (1,0) correctly', () {
        final pixel = HexUtils.axialToPixel(1, 0, cellSize);
        expect(pixel.dx, closeTo(45.0, 0.001)); // 30 * 3/2
        expect(pixel.dy, closeTo(25.98, 0.01)); // 30 * sqrt(3)/2
      });

      test('converts (0,1) correctly', () {
        final pixel = HexUtils.axialToPixel(0, 1, cellSize);
        expect(pixel.dx, closeTo(0, 0.001));
        expect(pixel.dy, closeTo(51.96, 0.01)); // 30 * sqrt(3)
      });

      test('respects origin offset', () {
        final origin = const Offset(100, 50);
        final pixel = HexUtils.axialToPixel(0, 0, cellSize, origin);
        expect(pixel.dx, closeTo(100, 0.001));
        expect(pixel.dy, closeTo(50, 0.001));
      });
    });

    group('pixelToAxial', () {
      test('converts pixel origin to (0,0)', () {
        final axial = HexUtils.pixelToAxial(Offset.zero, cellSize);
        expect(axial.q, 0);
        expect(axial.r, 0);
      });

      test('round-trips axialToPixel -> pixelToAxial', () {
        for (var q = -3; q <= 3; q++) {
          for (var r = -3; r <= 3; r++) {
            final pixel = HexUtils.axialToPixel(q, r, cellSize);
            final result = HexUtils.pixelToAxial(pixel, cellSize);
            expect(result.q, q, reason: 'q mismatch for ($q, $r)');
            expect(result.r, r, reason: 'r mismatch for ($q, $r)');
          }
        }
      });

      test('handles origin offset in round-trip', () {
        final origin = const Offset(200, 150);
        for (var q = -2; q <= 2; q++) {
          for (var r = -2; r <= 2; r++) {
            final pixel = HexUtils.axialToPixel(q, r, cellSize, origin);
            final result = HexUtils.pixelToAxial(pixel, cellSize, origin);
            expect(result.q, q, reason: 'q mismatch for ($q, $r)');
            expect(result.r, r, reason: 'r mismatch for ($q, $r)');
          }
        }
      });
    });

    group('getHexVertices', () {
      test('returns 6 vertices', () {
        final vertices = HexUtils.getHexVertices(Offset.zero, cellSize);
        expect(vertices.length, 6);
      });

      test('vertices are at correct distance from center', () {
        final center = const Offset(100, 100);
        final vertices = HexUtils.getHexVertices(center, cellSize);
        for (final vertex in vertices) {
          final distance = (vertex - center).distance;
          expect(distance, closeTo(cellSize, 0.001));
        }
      });

      test('first vertex is at 0 degrees (right corner)', () {
        final center = const Offset(50, 50);
        final vertices = HexUtils.getHexVertices(center, cellSize);
        expect(vertices[0].dx, closeTo(50 + cellSize, 0.001));
        expect(vertices[0].dy, closeTo(50, 0.001));
      });
    });

    group('dimension calculations', () {
      test('innerRadius is sqrt(3)/2 of outer radius', () {
        expect(HexUtils.innerRadius(cellSize), closeTo(25.98, 0.01));
      });

      test('hexWidth is 2 * size', () {
        expect(HexUtils.hexWidth(cellSize), 60.0);
      });

      test('hexHeight is sqrt(3) * size', () {
        expect(HexUtils.hexHeight(cellSize), closeTo(51.96, 0.01));
      });

      test('horizontalSpacing is 3/2 * size', () {
        expect(HexUtils.horizontalSpacing(cellSize), 45.0);
      });

      test('verticalSpacing is sqrt(3) * size', () {
        expect(HexUtils.verticalSpacing(cellSize), closeTo(51.96, 0.01));
      });
    });

    group('isInsideHex', () {
      test('center point is inside', () {
        final center = const Offset(100, 100);
        expect(HexUtils.isInsideHex(center, center, cellSize), true);
      });

      test('point at corner is inside', () {
        final center = const Offset(100, 100);
        // Point just inside the corner
        final nearCorner = Offset(100 + cellSize - 1, 100);
        expect(HexUtils.isInsideHex(nearCorner, center, cellSize), true);
      });

      test('point outside is outside', () {
        final center = const Offset(100, 100);
        final outside = Offset(100 + cellSize + 10, 100);
        expect(HexUtils.isInsideHex(outside, center, cellSize), false);
      });
    });
  });
}
