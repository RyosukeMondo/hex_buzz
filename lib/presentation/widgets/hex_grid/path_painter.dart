import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../utils/hex_utils.dart';

/// Custom painter that renders the player's path through the hex grid.
///
/// Draws a thick line connecting cell centers with a color gradient
/// based on path progress (0% to 100% of total cells).
/// Gradient: blue -> purple -> red
class PathPainter extends CustomPainter {
  final List<HexCell> path;
  final int totalCells;
  final double cellSize;
  final Offset origin;

  /// Path width as proportion of cell size for consistent scaling
  static const _pathWidthRatio = 0.25;
  static const _minPathWidth = 8.0;
  static const _maxPathWidth = 20.0;

  static const _startColor = Color(0xFF2196F3); // Blue
  static const _midColor = Color(0xFF9C27B0); // Purple
  static const _endColor = Color(0xFFF44336); // Red

  PathPainter({
    required this.path,
    required this.totalCells,
    required this.cellSize,
    this.origin = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final points = _computePathPoints();
    _drawGradientPath(canvas, points);
  }

  /// Computes pixel positions for each cell center in the path.
  List<Offset> _computePathPoints() {
    return path.map((cell) {
      return HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);
    }).toList();
  }

  /// Calculate path width based on cell size
  double get _pathWidth {
    final width = cellSize * _pathWidthRatio;
    return width.clamp(_minPathWidth, _maxPathWidth);
  }

  /// Draws the path with a gradient color based on progress.
  void _drawGradientPath(Canvas canvas, List<Offset> points) {
    final pathWidth = _pathWidth;

    for (var i = 0; i < points.length - 1; i++) {
      final startPoint = points[i];
      final endPoint = points[i + 1];

      // Calculate progress for this segment (0.0 to 1.0)
      final segmentProgress = totalCells > 1 ? i / (totalCells - 1) : 0.0;
      final nextProgress = totalCells > 1 ? (i + 1) / (totalCells - 1) : 0.0;

      final startColor = _colorForProgress(segmentProgress);
      final endColor = _colorForProgress(nextProgress);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [startColor, endColor],
        ).createShader(Rect.fromPoints(startPoint, endPoint))
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  /// Returns the gradient color for a given progress value (0.0 to 1.0).
  ///
  /// 0.0 = blue, 0.5 = purple, 1.0 = red
  Color _colorForProgress(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    if (clampedProgress < 0.5) {
      // Interpolate from blue to purple (0.0 to 0.5)
      final t = clampedProgress * 2;
      return Color.lerp(_startColor, _midColor, t)!;
    } else {
      // Interpolate from purple to red (0.5 to 1.0)
      final t = (clampedProgress - 0.5) * 2;
      return Color.lerp(_midColor, _endColor, t)!;
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return path != oldDelegate.path ||
        totalCells != oldDelegate.totalCells ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin;
  }
}
