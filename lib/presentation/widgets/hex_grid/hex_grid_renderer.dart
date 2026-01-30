import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import '../../utils/hex_utils.dart';
import 'hex_cell_widget.dart';
import 'hex_grid_layout.dart';
import 'hex_grid_theme.dart';
import 'path_painter.dart';
import 'wall_painter.dart';

/// Renders the hexagonal grid visually.
///
/// Responsible for:
/// - Painting cell backgrounds and borders
/// - Drawing the path line
/// - Drawing walls
/// - Drawing checkpoint numbers on top layer
class HexGridRenderer extends StatelessWidget {
  final HexGridLayout layout;
  final Level level;
  final List<HexCell> path;
  final Set<HexCell> visitedCells;
  final HexGridTheme theme;

  const HexGridRenderer({
    super.key,
    required this.layout,
    required this.level,
    required this.path,
    required this.visitedCells,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(layout.constraints.maxWidth, layout.constraints.maxHeight),
        painter: HexGridPainter(
          level: level,
          path: path,
          visitedCells: visitedCells,
          cellSize: layout.cellSize,
          origin: layout.origin,
          theme: theme,
        ),
      ),
    );
  }
}

/// Custom painter that renders the complete hex grid.
///
/// Rendering order (REQ-7):
/// 1. Cell backgrounds and borders (without checkpoint numbers)
/// 2. Path line
/// 3. Walls
/// 4. Checkpoint numbers (on top of everything)
class HexGridPainter extends CustomPainter {
  final Level level;
  final List<HexCell> path;
  final Set<HexCell> visitedCells;
  final double cellSize;
  final Offset origin;
  final HexGridTheme theme;

  HexGridPainter({
    required this.level,
    required this.path,
    required this.visitedCells,
    required this.cellSize,
    required this.origin,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Cell backgrounds and borders (without checkpoint numbers)
    _drawCells(canvas, skipCheckpoints: true);

    // Layer 2: Path line
    _drawPath(canvas, size);

    // Layer 3: Walls
    _drawWalls(canvas, size);

    // Layer 4: Checkpoint numbers (on top of everything)
    _drawCheckpoints(canvas);
  }

  void _drawCells(Canvas canvas, {bool skipCheckpoints = false}) {
    final startCheckpoint = 1;
    final endCheckpoint = level.checkpointCount;

    for (final cell in level.cells.values) {
      final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);
      final isStart = cell.checkpoint == startCheckpoint;
      final isEnd = cell.checkpoint == endCheckpoint;
      final isVisited = visitedCells.contains(cell);
      final visitedColor = isVisited ? _getColorForCell(cell) : null;

      canvas.save();
      canvas.translate(
        center.dx - HexUtils.hexWidth(cellSize) / 2,
        center.dy - HexUtils.hexHeight(cellSize) / 2,
      );

      final cellPainter = HexCellPainter(
        cell: isVisited ? cell.copyWith(visited: true) : cell,
        cellSize: cellSize,
        isStart: isStart,
        isEnd: isEnd,
        visitedColor: visitedColor,
        skipCheckpoint: skipCheckpoints,
      );

      cellPainter.paint(
        canvas,
        Size(HexUtils.hexWidth(cellSize), HexUtils.hexHeight(cellSize)),
      );

      canvas.restore();
    }
  }

  Color? _getColorForCell(HexCell cell) {
    final pathIndex = path.indexOf(cell);
    if (pathIndex < 0) return null;

    final progress = level.cells.length > 1
        ? pathIndex / (level.cells.length - 1)
        : 0.0;
    return theme.colorForProgress(progress);
  }

  void _drawWalls(Canvas canvas, Size size) {
    if (level.walls.isEmpty) return;

    final wallPainter = WallPainter(
      walls: level.walls,
      cellSize: cellSize,
      origin: origin,
    );

    wallPainter.paint(canvas, size);
  }

  void _drawPath(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final pathPainter = PathPainter(
      path: path,
      totalCells: level.cells.length,
      cellSize: cellSize,
      origin: origin,
    );

    pathPainter.paint(canvas, size);
  }

  /// Draws checkpoint numbers as a separate layer on top of everything.
  void _drawCheckpoints(Canvas canvas) {
    for (final cell in level.cells.values) {
      if (cell.checkpoint == null) continue;

      final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);

      canvas.save();
      canvas.translate(
        center.dx - HexUtils.hexWidth(cellSize) / 2,
        center.dy - HexUtils.hexHeight(cellSize) / 2,
      );

      final checkpointPainter = CheckpointPainter(
        cell: cell,
        cellSize: cellSize,
      );

      checkpointPainter.paint(
        canvas,
        Size(HexUtils.hexWidth(cellSize), HexUtils.hexHeight(cellSize)),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) {
    return level != oldDelegate.level ||
        path != oldDelegate.path ||
        visitedCells != oldDelegate.visitedCells ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin ||
        theme != oldDelegate.theme;
  }
}
