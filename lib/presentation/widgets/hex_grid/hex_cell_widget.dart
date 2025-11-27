import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../utils/hex_utils.dart';

/// Widget that renders a single hexagonal cell.
///
/// Uses [CustomPainter] for efficient rendering of the hexagon shape.
/// Visual states:
/// - Unvisited: light gray fill
/// - Visited: colored fill (based on path progress)
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
/// - Visited state coloring
/// - Checkpoint number display
/// - Start/end checkpoint border highlighting
class HexCellPainter extends CustomPainter {
  final HexCell cell;
  final double cellSize;
  final bool isStart;
  final bool isEnd;
  final Color? visitedColor;

  static const _unvisitedColor = Color(0xFFE0E0E0);
  static const _defaultVisitedColor = Color(0xFF64B5F6);
  static const _borderColor = Color(0xFF424242);
  static const _startBorderColor = Color(0xFF4CAF50);
  static const _endBorderColor = Color(0xFFF44336);
  static const _checkpointTextColor = Color(0xFF212121);

  HexCellPainter({
    required this.cell,
    required this.cellSize,
    this.isStart = false,
    this.isEnd = false,
    this.visitedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vertices = HexUtils.getHexVertices(center, cellSize);
    final path = _createHexPath(vertices);

    _drawFill(canvas, path);
    _drawBorder(canvas, path);
    _drawCheckpoint(canvas, center);
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

  void _drawFill(Canvas canvas, Path path) {
    final fillColor = cell.visited
        ? (visitedColor ?? _defaultVisitedColor)
        : _unvisitedColor;

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
      borderWidth = 1.0;
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
        visitedColor != oldDelegate.visitedColor;
  }
}
