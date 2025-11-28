import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import '../../utils/hex_utils.dart';
import 'hex_cell_widget.dart';
import 'path_painter.dart';
import 'wall_painter.dart';

/// Callback signature for cell interaction events.
typedef CellCallback = void Function(HexCell cell);

/// Interactive hexagonal grid widget that composes cells, walls, and path.
///
/// Handles touch/mouse drag input, converts pointer positions to cell
/// coordinates, and emits cell interactions via callbacks.
class HexGridWidget extends StatefulWidget {
  final Level level;
  final List<HexCell> path;
  final Set<HexCell> visitedCells;
  final CellCallback? onCellEntered;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const HexGridWidget({
    super.key,
    required this.level,
    required this.path,
    required this.visitedCells,
    this.onCellEntered,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<HexGridWidget> createState() => _HexGridWidgetState();
}

class _HexGridWidgetState extends State<HexGridWidget> {
  static const _minCellSize = 20.0;
  static const _maxCellSize = 80.0;
  static const _padding = 24.0;

  HexCell? _lastEnteredCell;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = _calculateCellSize(constraints);
        final gridSize = _calculateGridSize(cellSize);
        final origin = _calculateOrigin(constraints, gridSize, cellSize);

        return GestureDetector(
          onPanStart: (details) => _handleDragStart(details, cellSize, origin),
          onPanUpdate: (details) =>
              _handleDragUpdate(details, cellSize, origin),
          onPanEnd: (_) => _handleDragEnd(),
          onTapDown: (details) => _handleTap(details, cellSize, origin),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _HexGridPainter(
                level: widget.level,
                path: widget.path,
                visitedCells: widget.visitedCells,
                cellSize: cellSize,
                origin: origin,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculates the optimal cell size to fit the grid within constraints.
  /// Uses actual pixel bounds of all cells for accurate sizing.
  double _calculateCellSize(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth - (_padding * 2);
    final availableHeight = constraints.maxHeight - (_padding * 2);

    final cells = widget.level.cells.values;
    if (cells.isEmpty) return _minCellSize;

    // Calculate actual pixel bounds at size=1.0 to determine scaling
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, 1.0);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    // Add hex radius to bounds (cells extend beyond their centers)
    final gridWidth = (maxX - minX) + 2.0; // +2 for hex width at size 1
    final gridHeight =
        (maxY - minY) + sqrt(3); // +sqrt(3) for hex height at size 1

    if (gridWidth <= 0 || gridHeight <= 0) return _minCellSize;

    // Calculate scale factor to fit
    final scaleX = availableWidth / gridWidth;
    final scaleY = availableHeight / gridHeight;
    final cellSize = min(scaleX, scaleY);

    return cellSize.clamp(_minCellSize, _maxCellSize);
  }

  /// Calculates the actual pixel size of the grid.
  Size _calculateGridSize(double cellSize) {
    final cells = widget.level.cells.values;
    if (cells.isEmpty) return Size.zero;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, cellSize);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final width = (maxX - minX) + HexUtils.hexWidth(cellSize);
    final height = (maxY - minY) + HexUtils.hexHeight(cellSize);

    return Size(width, height);
  }

  /// Calculates the origin offset to center the grid.
  Offset _calculateOrigin(
    BoxConstraints constraints,
    Size gridSize,
    double cellSize,
  ) {
    final cells = widget.level.cells.values;
    if (cells.isEmpty) return Offset.zero;

    // Find the center of all cell positions
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in cells) {
      final pos = HexUtils.axialToPixel(cell.q, cell.r, cellSize);
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    final gridCenterX = (minX + maxX) / 2;
    final gridCenterY = (minY + maxY) / 2;

    // Offset to center grid in available space
    final originX = constraints.maxWidth / 2 - gridCenterX;
    final originY = constraints.maxHeight / 2 - gridCenterY;

    return Offset(originX, originY);
  }

  void _handleDragStart(
    DragStartDetails details,
    double cellSize,
    Offset origin,
  ) {
    _isDragging = true;
    _lastEnteredCell = null;
    widget.onDragStart?.call();
    _processPointerPosition(details.localPosition, cellSize, origin);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double cellSize,
    Offset origin,
  ) {
    if (!_isDragging) return;
    _processPointerPosition(details.localPosition, cellSize, origin);
  }

  void _handleDragEnd() {
    _isDragging = false;
    _lastEnteredCell = null;
    widget.onDragEnd?.call();
  }

  void _handleTap(TapDownDetails details, double cellSize, Offset origin) {
    _processPointerPosition(details.localPosition, cellSize, origin);
  }

  void _processPointerPosition(
    Offset position,
    double cellSize,
    Offset origin,
  ) {
    final coords = HexUtils.pixelToAxial(position, cellSize, origin);
    final cell = widget.level.getCell(coords.q, coords.r);

    if (cell == null) return;

    // Only emit if entering a different cell
    if (cell != _lastEnteredCell) {
      _lastEnteredCell = cell;
      widget.onCellEntered?.call(cell);
    }
  }
}

/// Custom painter that renders the complete hex grid with cells, walls, and path.
class _HexGridPainter extends CustomPainter {
  final Level level;
  final List<HexCell> path;
  final Set<HexCell> visitedCells;
  final double cellSize;
  final Offset origin;

  _HexGridPainter({
    required this.level,
    required this.path,
    required this.visitedCells,
    required this.cellSize,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCells(canvas);
    _drawWalls(canvas, size);
    _drawPath(canvas, size);
  }

  void _drawCells(Canvas canvas) {
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
    return _colorForProgress(progress);
  }

  Color _colorForProgress(double progress) {
    const startColor = Color(0xFF2196F3); // Blue
    const midColor = Color(0xFF9C27B0); // Purple
    const endColor = Color(0xFFF44336); // Red

    final clampedProgress = progress.clamp(0.0, 1.0);

    if (clampedProgress < 0.5) {
      final t = clampedProgress * 2;
      return Color.lerp(startColor, midColor, t)!;
    } else {
      final t = (clampedProgress - 0.5) * 2;
      return Color.lerp(midColor, endColor, t)!;
    }
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

  @override
  bool shouldRepaint(_HexGridPainter oldDelegate) {
    return level != oldDelegate.level ||
        path != oldDelegate.path ||
        visitedCells != oldDelegate.visitedCells ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin;
  }
}
