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
  static const _maxCellSize = 60.0;
  static const _padding = 20.0;

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

  double _calculateCellSize(BoxConstraints constraints) {
    final availableWidth = constraints.maxWidth - (_padding * 2);
    final availableHeight = constraints.maxHeight - (_padding * 2);

    // Calculate size needed to fit grid horizontally
    // For flat-top hexagons: width = (3/2) * size * (cols - 1) + 2 * size
    final cols = widget.level.size;
    final rows = widget.level.size;
    final horizontalSize = availableWidth / (1.5 * (cols - 1) + 2);

    // Calculate size needed to fit grid vertically
    // For flat-top hexagons: height = sqrt(3) * size * (rows - 0.5) for offset rows
    final verticalSize =
        availableHeight / (HexUtils.hexHeight(1) * (rows + 0.5));

    // Use the smaller to ensure grid fits
    final calculatedSize = horizontalSize < verticalSize
        ? horizontalSize
        : verticalSize;

    return calculatedSize.clamp(_minCellSize, _maxCellSize);
  }

  Size _calculateGridSize(double cellSize) {
    final cols = widget.level.size;
    final rows = widget.level.size;

    final width =
        HexUtils.horizontalSpacing(cellSize) * (cols - 1) +
        HexUtils.hexWidth(cellSize);
    final height =
        HexUtils.verticalSpacing(cellSize) * (rows - 1) +
        HexUtils.hexHeight(cellSize);

    return Size(width, height);
  }

  Offset _calculateOrigin(
    BoxConstraints constraints,
    Size gridSize,
    double cellSize,
  ) {
    // Center the grid within the available space
    final centerX = (constraints.maxWidth - gridSize.width) / 2 + cellSize;
    final centerY =
        (constraints.maxHeight - gridSize.height) / 2 +
        HexUtils.hexHeight(cellSize) / 2;

    return Offset(centerX, centerY);
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
