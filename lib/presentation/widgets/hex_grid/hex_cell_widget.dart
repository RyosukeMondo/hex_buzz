import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../theme/honey_theme.dart';
import '../../utils/hex_utils.dart';

/// Widget that renders a single hexagonal cell.
///
/// Uses [CustomPainter] for efficient rendering of the hexagon shape.
/// Visual states:
/// - Unvisited: light gray fill
/// - Visited: smaller colored fill with visible border gap for path
/// - Start checkpoint (1): green border
/// - End checkpoint (max): red border
class HexCellWidget extends StatelessWidget {
  final HexCell cell;
  final double cellSize;
  final bool isStart;
  final bool isEnd;
  final Color? visitedColor;

  const HexCellWidget({
    super.key,
    required this.cell,
    required this.cellSize,
    this.isStart = false,
    this.isEnd = false,
    this.visitedColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(HexUtils.hexWidth(cellSize), HexUtils.hexHeight(cellSize)),
      painter: HexCellPainter(
        cell: cell,
        cellSize: cellSize,
        isStart: isStart,
        isEnd: isEnd,
        visitedColor: visitedColor,
      ),
    );
  }
}

/// Custom painter for drawing a hexagonal cell.
///
/// Handles:
/// - Hexagon shape with fill and stroke
/// - Visited state coloring (smaller fill to show path better)
/// - Checkpoint number display
/// - Start/end checkpoint border highlighting
class HexCellPainter extends CustomPainter {
  final HexCell cell;
  final double cellSize;
  final bool isStart;
  final bool isEnd;
  final Color? visitedColor;

  /// When true, skips drawing checkpoint numbers (for layered rendering)
  final bool skipCheckpoint;

  // Using HoneyTheme colors for honey/bee visual styling
  static const _unvisitedColor = HoneyTheme.cellUnvisited;
  static const _defaultVisitedColor = HoneyTheme.cellVisited;
  static const _borderColor = HoneyTheme.cellBorder;
  static const _startBorderColor = HoneyTheme.cellBorderStart;
  static const _endBorderColor = HoneyTheme.cellBorderEnd;
  static const _checkpointTextColor = HoneyTheme.textPrimary;

  /// Scale factor for visited cell fill (smaller to show path better)
  static const _visitedFillScale = 0.75;

  HexCellPainter({
    required this.cell,
    required this.cellSize,
    this.isStart = false,
    this.isEnd = false,
    this.visitedColor,
    this.skipCheckpoint = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw full-size hex for unvisited or border
    final fullVertices = HexUtils.getHexVertices(center, cellSize);
    final fullPath = _createHexPath(fullVertices);

    if (cell.visited) {
      // Draw smaller fill for visited cells to show path better
      final smallerSize = cellSize * _visitedFillScale;
      final smallerVertices = HexUtils.getHexVertices(center, smallerSize);
      final smallerPath = _createHexPath(smallerVertices);

      // Draw background (slightly visible for context)
      _drawBackground(canvas, fullPath);

      // Draw the smaller visited fill
      _drawVisitedFill(canvas, smallerPath);
    } else {
      // Draw unvisited cell fill
      _drawFill(canvas, fullPath);
    }

    // Always draw the border
    _drawBorder(canvas, fullPath);

    // Draw checkpoint number (unless skipped for layered rendering)
    if (!skipCheckpoint) {
      _drawCheckpoint(canvas, center);
    }
  }

  Path _createHexPath(List<Offset> vertices) {
    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (var i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    return path;
  }

  void _drawBackground(Canvas canvas, Path path) {
    // Light honey background for visited cells to show the cell boundary
    final bgPaint = Paint()
      ..color = HoneyTheme.warmCream
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);
  }

  void _drawFill(Canvas canvas, Path path) {
    final fillPaint = Paint()
      ..color = _unvisitedColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  void _drawVisitedFill(Canvas canvas, Path path) {
    final fillColor = visitedColor ?? _defaultVisitedColor;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  void _drawBorder(Canvas canvas, Path path) {
    Color borderColor;
    double borderWidth;

    if (isStart) {
      borderColor = _startBorderColor;
      borderWidth = 3.0;
    } else if (isEnd) {
      borderColor = _endBorderColor;
      borderWidth = 3.0;
    } else {
      borderColor = _borderColor;
      borderWidth = 1.5;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, borderPaint);
  }

  void _drawCheckpoint(Canvas canvas, Offset center) {
    if (cell.checkpoint == null) return;

    final textSpan = TextSpan(
      text: cell.checkpoint.toString(),
      style: TextStyle(
        color: _checkpointTextColor,
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
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(HexCellPainter oldDelegate) {
    return cell != oldDelegate.cell ||
        cellSize != oldDelegate.cellSize ||
        isStart != oldDelegate.isStart ||
        isEnd != oldDelegate.isEnd ||
        visitedColor != oldDelegate.visitedColor ||
        skipCheckpoint != oldDelegate.skipCheckpoint;
  }
}

/// Custom painter that renders only checkpoint numbers.
///
/// Used for layered rendering where checkpoints must appear above the path.
class CheckpointPainter extends CustomPainter {
  final HexCell cell;
  final double cellSize;

  static const _checkpointTextColor = HoneyTheme.textPrimary;

  CheckpointPainter({required this.cell, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (cell.checkpoint == null) return;

    final center = Offset(size.width / 2, size.height / 2);

    final textSpan = TextSpan(
      text: cell.checkpoint.toString(),
      style: TextStyle(
        color: _checkpointTextColor,
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
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CheckpointPainter oldDelegate) {
    return cell != oldDelegate.cell || cellSize != oldDelegate.cellSize;
  }
}
