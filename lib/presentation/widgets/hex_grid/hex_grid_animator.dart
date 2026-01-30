import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/hex_cell.dart';
import '../../utils/hex_utils.dart';
import 'hex_grid_theme.dart';

/// Manages animation state for visited cells.
///
/// Tracks which cells have been animated to prevent re-triggering
/// animations on widget rebuilds.
class HexGridAnimator {
  final Set<String> _animatedCellKeys = {};

  /// Checks if a cell has already been animated.
  bool hasAnimated(HexCell cell) {
    return _animatedCellKeys.contains(_keyForCell(cell));
  }

  /// Marks a cell as animated.
  void markAnimated(HexCell cell) {
    _animatedCellKeys.add(_keyForCell(cell));
  }

  /// Resets animation state (e.g., when starting a new game).
  void reset() {
    _animatedCellKeys.clear();
  }

  String _keyForCell(HexCell cell) => '${cell.q},${cell.r}';
}

/// Widget that renders animated overlays for visited cells.
///
/// Positions AnimatedCellPaint widgets over each visited cell
/// and manages their animation triggers.
class HexGridAnimationOverlays extends StatelessWidget {
  final Set<HexCell> visitedCells;
  final List<HexCell> path;
  final int totalCells;
  final double cellSize;
  final Offset origin;
  final HexGridTheme theme;
  final HexGridAnimator animator;

  const HexGridAnimationOverlays({
    super.key,
    required this.visitedCells,
    required this.path,
    required this.totalCells,
    required this.cellSize,
    required this.origin,
    required this.theme,
    required this.animator,
  });

  @override
  Widget build(BuildContext context) {
    final overlays = <Widget>[];
    final hexWidth = HexUtils.hexWidth(cellSize);
    final hexHeight = HexUtils.hexHeight(cellSize);

    for (final cell in visitedCells) {
      final isNewlyVisited = !animator.hasAnimated(cell);

      // Mark cell as animated
      animator.markAnimated(cell);

      final center = HexUtils.axialToPixel(cell.q, cell.r, cellSize, origin);
      final left = center.dx - hexWidth / 2;
      final top = center.dy - hexHeight / 2;

      // Get the color for this cell based on path position
      final pathIndex = path.indexOf(cell);
      final progress = totalCells > 1 ? pathIndex / (totalCells - 1) : 0.0;
      final visitedColor = theme.colorForProgress(progress.clamp(0.0, 1.0));

      overlays.add(
        Positioned(
          left: left,
          top: top,
          width: hexWidth,
          height: hexHeight,
          child: _AnimatedCellOverlay(
            key: ValueKey('${cell.q},${cell.r}'),
            cellSize: cellSize,
            visitedColor: visitedColor,
            shouldAnimate: isNewlyVisited,
          ),
        ),
      );
    }

    return Stack(children: overlays);
  }
}

/// Internal widget that wraps AnimatedCellPaint with custom painting.
class _AnimatedCellOverlay extends StatelessWidget {
  final double cellSize;
  final Color visitedColor;
  final bool shouldAnimate;

  const _AnimatedCellOverlay({
    super.key,
    required this.cellSize,
    required this.visitedColor,
    required this.shouldAnimate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(HexUtils.hexWidth(cellSize), HexUtils.hexHeight(cellSize)),
      painter: _AnimatedCellOverlayPainter(
        cellSize: cellSize,
        visitedColor: visitedColor,
      ),
    );
  }
}

/// Custom painter for the animated cell overlay.
/// Paints a hexagon fill that appears during the animation.
class _AnimatedCellOverlayPainter extends CustomPainter {
  final double cellSize;
  final Color visitedColor;

  _AnimatedCellOverlayPainter({
    required this.cellSize,
    required this.visitedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = _createHexPath(center, cellSize * 0.85);

    final paint = Paint()
      ..color = visitedColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  Path _createHexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // Pointy-top hex: first vertex at 30 degrees.
      final angle = (60 * i - 30) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_AnimatedCellOverlayPainter oldDelegate) {
    return cellSize != oldDelegate.cellSize ||
        visitedColor != oldDelegate.visitedColor;
  }
}
