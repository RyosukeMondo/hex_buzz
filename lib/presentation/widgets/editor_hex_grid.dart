import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/editor_state.dart';
import '../../domain/models/hex_edge.dart';
import '../../domain/models/level.dart';
import '../theme/honey_theme.dart';
import '../utils/hex_utils.dart';

/// Callback for cell tap events in the editor.
typedef EditorCellCallback = void Function(int q, int r);

/// Callback for edge tap events in the editor.
typedef EditorEdgeCallback = void Function(int q1, int r1, int q2, int r2);

/// Interactive hexagonal grid widget for the level editor.
///
/// Supports tapping cells and edges (no drag-based path drawing).
/// Renders checkpoint numbers, walls, and selection highlights.
class EditorHexGrid extends StatelessWidget {
  final EditorState editorState;
  final EditorCellCallback? onCellTapped;
  final EditorEdgeCallback? onEdgeTapped;

  const EditorHexGrid({
    super.key,
    required this.editorState,
    this.onCellTapped,
    this.onEdgeTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final level = editorState.toLevel();
        final layout = _EditorLayout.calculate(
          level: level,
          constraints: constraints,
        );

        return GestureDetector(
          onTapDown: (details) => _handleTap(details, layout, level),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _EditorGridPainter(
              editorState: editorState,
              cellSize: layout.cellSize,
              origin: layout.origin,
            ),
          ),
        );
      },
    );
  }

  /// Handles tap events, determining whether a cell or edge was tapped.
  void _handleTap(
    TapDownDetails details,
    _EditorLayout layout,
    Level level,
  ) {
    final position = details.localPosition;

    // Check if tap is near an edge first (higher priority for wall tool)
    if (editorState.currentTool == EditorTool.wall ||
        editorState.currentTool == EditorTool.eraser) {
      final edgeHit = _findNearestEdge(position, layout, level);
      if (edgeHit != null) {
        onEdgeTapped?.call(
          edgeHit.q1,
          edgeHit.r1,
          edgeHit.q2,
          edgeHit.r2,
        );
        return;
      }
    }

    // Otherwise, find the cell that was tapped
    final coords = HexUtils.pixelToAxial(
      position,
      layout.cellSize,
      layout.origin,
    );

    if (level.cells.containsKey((coords.q, coords.r))) {
      onCellTapped?.call(coords.q, coords.r);
    }
  }

  /// Finds the nearest edge to a tap position.
  ///
  /// Returns the edge if the tap is within a threshold distance,
  /// null otherwise.
  HexEdge? _findNearestEdge(
    Offset position,
    _EditorLayout layout,
    Level level,
  ) {
    const tapThreshold = 15.0;
    HexEdge? nearestEdge;
    var nearestDistance = double.infinity;

    // Check all possible edges between adjacent cells
    for (final cell in level.cells.values) {
      for (final neighbor in cell.neighbors) {
        if (!level.cells.containsKey((neighbor.q, neighbor.r))) continue;

        final edge = HexEdge(
          cellQ1: cell.q,
          cellR1: cell.r,
          cellQ2: neighbor.q,
          cellR2: neighbor.r,
        );

        final edgeMidpoint = _getEdgeMidpoint(
          cell.q,
          cell.r,
          neighbor.q,
          neighbor.r,
          layout,
        );

        final distance = (position - edgeMidpoint).distance;
        if (distance < nearestDistance && distance < tapThreshold) {
          nearestDistance = distance;
          nearestEdge = edge;
        }
      }
    }

    return nearestEdge;
  }

  /// Calculates the midpoint of the shared edge between two cells.
  Offset _getEdgeMidpoint(
    int q1,
    int r1,
    int q2,
    int r2,
    _EditorLayout layout,
  ) {
    final center1 = HexUtils.axialToPixel(
      q1,
      r1,
      layout.cellSize,
      layout.origin,
    );
    final center2 = HexUtils.axialToPixel(
      q2,
      r2,
      layout.cellSize,
      layout.origin,
    );
    return Offset(
      (center1.dx + center2.dx) / 2,
      (center1.dy + center2.dy) / 2,
    );
  }
}

/// Layout calculator for the editor grid.
class _EditorLayout {
  final double cellSize;
  final Offset origin;

  static const _padding = 24.0;
  static const _minCellSize = 20.0;
  static const _maxCellSize = 80.0;

  _EditorLayout._({required this.cellSize, required this.origin});

  factory _EditorLayout.calculate({
    required Level level,
    required BoxConstraints constraints,
  }) {
    final cellSize = _calculateCellSize(level, constraints);
    final origin = _calculateOrigin(level, constraints, cellSize);
    return _EditorLayout._(cellSize: cellSize, origin: origin);
  }

  static double _calculateCellSize(Level level, BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth - (_padding * 2);
    final availableHeight = constraints.maxHeight - (_padding * 2);

    if (level.cells.isEmpty) return _minCellSize;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in level.cells.values) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, 1.0);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final gridWidth = (maxX - minX) + 2.0;
    final gridHeight = (maxY - minY) + sqrt(3);

    if (gridWidth <= 0 || gridHeight <= 0) return _minCellSize;

    final scaleX = availableWidth / gridWidth;
    final scaleY = availableHeight / gridHeight;
    return min(scaleX, scaleY).clamp(_minCellSize, _maxCellSize);
  }

  static Offset _calculateOrigin(
    Level level,
    BoxConstraints constraints,
    double cellSize,
  ) {
    if (level.cells.isEmpty) return Offset.zero;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in level.cells.values) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, cellSize);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final gridCenterX = (minX + maxX) / 2;
    final gridCenterY = (minY + maxY) / 2;

    return Offset(
      constraints.maxWidth / 2 - gridCenterX,
      constraints.maxHeight / 2 - gridCenterY,
    );
  }
}

/// Custom painter that renders the editor hex grid.
///
/// Renders cells, walls, checkpoint numbers, and selection highlights.
class _EditorGridPainter extends CustomPainter {
  final EditorState editorState;
  final double cellSize;
  final Offset origin;

  _EditorGridPainter({
    required this.editorState,
    required this.cellSize,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCells(canvas);
    _drawWalls(canvas);
    _drawCheckpoints(canvas);
    _drawSelection(canvas);
  }

  void _drawCells(Canvas canvas) {
    final fillPaint = Paint()
      ..color = HoneyTheme.cellUnvisited
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = HoneyTheme.cellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final cell in editorState.cells.values) {
      final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);
      final vertices = HexUtils.getHexVertices(center, cellSize);
      final path = _createPath(vertices);

      // Highlight cells with checkpoints
      if (cell.checkpoint != null) {
        final cpPaint = Paint()
          ..color = cell.checkpoint == 1
              ? HoneyTheme.cellBorderStart.withValues(alpha: 0.2)
              : (cell.checkpoint == editorState.checkpointCount
                    ? HoneyTheme.cellBorderEnd.withValues(alpha: 0.2)
                    : HoneyTheme.honeyGoldLight.withValues(alpha: 0.4))
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, cpPaint);
      } else {
        canvas.drawPath(path, fillPaint);
      }

      // Draw border with color indicating checkpoint type
      if (cell.checkpoint == 1) {
        final startBorder = Paint()
          ..color = HoneyTheme.cellBorderStart
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawPath(path, startBorder);
      } else if (cell.checkpoint == editorState.checkpointCount &&
          editorState.checkpointCount > 0) {
        final endBorder = Paint()
          ..color = HoneyTheme.cellBorderEnd
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawPath(path, endBorder);
      } else {
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  void _drawWalls(Canvas canvas) {
    if (editorState.walls.isEmpty) return;

    final wallPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (final wall in editorState.walls) {
      final endpoints = _getWallEndpoints(wall);
      if (endpoints != null) {
        canvas.drawLine(endpoints.$1, endpoints.$2, wallPaint);
      }
    }
  }

  void _drawCheckpoints(Canvas canvas) {
    for (final cell in editorState.cells.values) {
      if (cell.checkpoint == null) continue;

      final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);

      final textSpan = TextSpan(
        text: cell.checkpoint.toString(),
        style: TextStyle(
          color: HoneyTheme.textPrimary,
          fontSize: cellSize * 0.4,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    final selected = editorState.selectedCell;
    if (selected == null) return;
    if (!editorState.cells.containsKey(selected)) return;

    final center = HexUtils.axialToPixel(
      selected.$1,
      selected.$2,
      cellSize,
      origin,
    );
    final vertices = HexUtils.getHexVertices(center, cellSize);
    final path = _createPath(vertices);

    final selectionPaint = Paint()
      ..color = HoneyTheme.honeyGold.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, selectionPaint);

    final selectionBorder = Paint()
      ..color = HoneyTheme.honeyGoldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(path, selectionBorder);
  }

  (Offset, Offset)? _getWallEndpoints(HexEdge wall) {
    final center = HexUtils.axialToPixel(wall.q1, wall.r1, cellSize, origin);
    final dq = wall.q2 - wall.q1;
    final dr = wall.r2 - wall.r1;

    final edgeIndex = _getEdgeIndex(dq, dr);
    if (edgeIndex == null) return null;

    final vertices = HexUtils.getHexVertices(center, cellSize);
    return (vertices[edgeIndex], vertices[(edgeIndex + 1) % 6]);
  }

  int? _getEdgeIndex(int dq, int dr) {
    if (dq == 1 && dr == 0) return 0;
    if (dq == 0 && dr == 1) return 1;
    if (dq == -1 && dr == 1) return 2;
    if (dq == -1 && dr == 0) return 3;
    if (dq == 0 && dr == -1) return 4;
    if (dq == 1 && dr == -1) return 5;
    return null;
  }

  Path _createPath(List<Offset> vertices) {
    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (var i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_EditorGridPainter oldDelegate) {
    return editorState != oldDelegate.editorState ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin;
  }
}
