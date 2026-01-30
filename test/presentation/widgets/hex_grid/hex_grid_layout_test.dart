import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_layout.dart';

void main() {
  group('HexGridLayout', () {
    test('calculates layout for simple grid', () {
      final level = Level(
        size: 3,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0),
          (1, 0): const HexCell(q: 1, r: 0),
          (0, 1): const HexCell(q: 0, r: 1),
        },
        walls: {},
        checkpointCount: 2,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 800,
        minHeight: 0,
        maxHeight: 600,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      expect(layout.cellSize, greaterThan(0));
      expect(layout.cellSize, greaterThanOrEqualTo(20.0));
      expect(layout.cellSize, lessThanOrEqualTo(80.0));
      expect(layout.gridSize.width, greaterThan(0));
      expect(layout.gridSize.height, greaterThan(0));
      expect(layout.origin.dx, isNotNull);
      expect(layout.origin.dy, isNotNull);
    });

    test('respects min cell size', () {
      final level = Level(
        size: 20,
        cells: {
          for (int q = 0; q < 20; q++)
            for (int r = 0; r < 20; r++) (q, r): HexCell(q: q, r: r),
        },
        walls: {},
        checkpointCount: 2,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 200,
        minHeight: 0,
        maxHeight: 200,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      expect(layout.cellSize, greaterThanOrEqualTo(20.0));
    });

    test('respects max cell size', () {
      final level = Level(
        size: 1,
        cells: {(0, 0): const HexCell(q: 0, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 5000,
        minHeight: 0,
        maxHeight: 5000,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      expect(layout.cellSize, lessThanOrEqualTo(80.0));
    });

    test('converts hex to pixel correctly', () {
      final level = Level(
        size: 2,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0),
          (1, 0): const HexCell(q: 1, r: 0),
        },
        walls: {},
        checkpointCount: 2,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 800,
        minHeight: 0,
        maxHeight: 600,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      final pixel1 = layout.hexToPixel(0, 0);
      final pixel2 = layout.hexToPixel(1, 0);

      expect(pixel1.dx, isNotNull);
      expect(pixel1.dy, isNotNull);
      expect(pixel2.dx, greaterThan(pixel1.dx));
    });

    test('converts pixel to hex correctly', () {
      final level = Level(
        size: 2,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0),
          (1, 0): const HexCell(q: 1, r: 0),
        },
        walls: {},
        checkpointCount: 2,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 800,
        minHeight: 0,
        maxHeight: 600,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      final pixel = layout.hexToPixel(0, 0);
      final hex = layout.pixelToHex(pixel);

      expect(hex.q, equals(0));
      expect(hex.r, equals(0));
    });

    test('handles empty level', () {
      final level = Level(size: 0, cells: {}, walls: {}, checkpointCount: 0);

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 800,
        minHeight: 0,
        maxHeight: 600,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      expect(layout.cellSize, equals(20.0)); // Should use min size
      expect(layout.gridSize, equals(Size.zero));
      expect(layout.origin, equals(Offset.zero));
    });

    test('centers grid in available space', () {
      final level = Level(
        size: 1,
        cells: {(0, 0): const HexCell(q: 0, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      const constraints = BoxConstraints(
        minWidth: 0,
        maxWidth: 800,
        minHeight: 0,
        maxHeight: 600,
      );

      final layout = HexGridLayout.calculate(
        level: level,
        constraints: constraints,
      );

      // Grid should be centered, so origin should be positive
      expect(layout.origin.dx, greaterThan(0));
      expect(layout.origin.dy, greaterThan(0));
    });
  });
}
