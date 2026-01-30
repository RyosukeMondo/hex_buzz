import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_layout.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_renderer.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_theme.dart';

void main() {
  group('HexGridRenderer', () {
    testWidgets('renders without crashing', (tester) async {
      final level = Level(
        size: 5,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridRenderer(
              layout: layout,
              level: level,
              path: const [],
              visitedCells: const {},
              theme: HexGridTheme.fromHoneyTheme(),
            ),
          ),
        ),
      );

      expect(find.byType(HexGridRenderer), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders with path', (tester) async {
      final level = Level(
        size: 5,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
          (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
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

      const path = [
        HexCell(q: 0, r: 0, checkpoint: 1),
        HexCell(q: 1, r: 0, checkpoint: 2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridRenderer(
              layout: layout,
              level: level,
              path: path,
              visitedCells: path.toSet(),
              theme: HexGridTheme.fromHoneyTheme(),
            ),
          ),
        ),
      );

      expect(find.byType(HexGridRenderer), findsOneWidget);
    });

    testWidgets('renders with walls', (tester) async {
      final level = Level(
        size: 5,
        cells: {
          (0, 0): const HexCell(q: 0, r: 0),
          (1, 0): const HexCell(q: 1, r: 0),
        },
        walls: {HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0)},
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridRenderer(
              layout: layout,
              level: level,
              path: const [],
              visitedCells: const {},
              theme: HexGridTheme.fromHoneyTheme(),
            ),
          ),
        ),
      );

      expect(find.byType(HexGridRenderer), findsOneWidget);
    });

    testWidgets('uses RepaintBoundary for optimization', (tester) async {
      final level = Level(
        size: 5,
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridRenderer(
              layout: layout,
              level: level,
              path: const [],
              visitedCells: const {},
              theme: HexGridTheme.fromHoneyTheme(),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsOneWidget);
    });

    test('HexGridPainter shouldRepaint returns true when level changes', () {
      final level1 = Level(
        size: 5,
        cells: {(0, 0): const HexCell(q: 0, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      final level2 = Level(
        size: 5,
        cells: {(1, 0): const HexCell(q: 1, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      final painter1 = HexGridPainter(
        level: level1,
        path: const [],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      final painter2 = HexGridPainter(
        level: level2,
        path: const [],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('HexGridPainter shouldRepaint returns true when path changes', () {
      final level = Level(
        size: 5,
        cells: {(0, 0): const HexCell(q: 0, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      final painter1 = HexGridPainter(
        level: level,
        path: const [],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      final painter2 = HexGridPainter(
        level: level,
        path: const [HexCell(q: 0, r: 0)],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('HexGridPainter shouldRepaint returns false when nothing changes', () {
      final level = Level(
        size: 5,
        cells: {(0, 0): const HexCell(q: 0, r: 0)},
        walls: {},
        checkpointCount: 1,
      );

      final painter1 = HexGridPainter(
        level: level,
        path: const [],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      final painter2 = HexGridPainter(
        level: level,
        path: const [],
        visitedCells: const {},
        cellSize: 30.0,
        origin: Offset.zero,
        theme: HexGridTheme.fromHoneyTheme(),
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}
