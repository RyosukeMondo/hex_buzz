import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_gesture_handler.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_layout.dart';

void main() {
  group('HexGridGestureHandler', () {
    testWidgets('calls onCellEntered on tap', (tester) async {
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

      HexCell? tappedCell;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridGestureHandler(
              layout: layout,
              level: level,
              onCellEntered: (cell) {
                tappedCell = cell;
              },
              child: Container(width: 800, height: 600, color: Colors.white),
            ),
          ),
        ),
      );

      // Tap at the center of the cell
      final cellPixel = layout.hexToPixel(0, 0);
      await tester.tapAt(cellPixel);
      await tester.pump();

      expect(tappedCell, isNotNull);
      expect(tappedCell!.q, equals(0));
      expect(tappedCell!.r, equals(0));
    });

    testWidgets('calls onDragStart and onDragEnd', (tester) async {
      final level = Level(
        size: 5,
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

      bool dragStarted = false;
      bool dragEnded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridGestureHandler(
              layout: layout,
              level: level,
              onDragStart: () {
                dragStarted = true;
              },
              onDragEnd: () {
                dragEnded = true;
              },
              child: Container(width: 800, height: 600, color: Colors.white),
            ),
          ),
        ),
      );

      final startPixel = layout.hexToPixel(0, 0);
      final endPixel = layout.hexToPixel(1, 0);

      await tester.dragFrom(startPixel, endPixel - startPixel);
      await tester.pump();

      expect(dragStarted, isTrue);
      expect(dragEnded, isTrue);
    });

    testWidgets('calls onCellEntered during drag', (tester) async {
      final level = Level(
        size: 5,
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

      final enteredCells = <HexCell>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridGestureHandler(
              layout: layout,
              level: level,
              onCellEntered: (cell) {
                enteredCells.add(cell);
              },
              child: Container(width: 800, height: 600, color: Colors.white),
            ),
          ),
        ),
      );

      final startPixel = layout.hexToPixel(0, 0);
      final endPixel = layout.hexToPixel(1, 0);

      await tester.dragFrom(startPixel, endPixel - startPixel);
      await tester.pump();

      expect(enteredCells.length, greaterThan(0));
    });

    testWidgets('does not call onCellEntered for same cell twice', (
      tester,
    ) async {
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

      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridGestureHandler(
              layout: layout,
              level: level,
              onCellEntered: (cell) {
                callCount++;
              },
              child: Container(width: 800, height: 600, color: Colors.white),
            ),
          ),
        ),
      );

      final cellPixel = layout.hexToPixel(0, 0);
      await tester.tapAt(cellPixel);
      await tester.pump();

      expect(callCount, equals(1));

      // Tap again at the same position - handler deduplicates same cell
      await tester.tapAt(cellPixel);
      await tester.pump();

      // Same cell is deduplicated by the gesture handler
      expect(callCount, equals(1));
    });

    testWidgets('handles tap outside grid gracefully', (tester) async {
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

      HexCell? tappedCell;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HexGridGestureHandler(
              layout: layout,
              level: level,
              onCellEntered: (cell) {
                tappedCell = cell;
              },
              child: Container(width: 800, height: 600, color: Colors.white),
            ),
          ),
        ),
      );

      // Tap far from any cell
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Should not call callback for invalid cell
      expect(tappedCell, isNull);
    });
  });
}
