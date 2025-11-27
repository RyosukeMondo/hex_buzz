import 'package:flutter/material.dart';

import '../../../domain/models/hex_edge.dart';
import '../../utils/hex_utils.dart';

/// Custom painter that renders walls between hexagonal cells.
///
/// Walls are drawn as thick dark lines on the shared edges between cells.
/// Each wall is defined by a [HexEdge] which specifies the two cells it separates.
class WallPainter extends CustomPainter {
  final Set<HexEdge> walls;
  final double cellSize;
  final Offset origin;

  static const _wallColor = Color(0xFF1A1A1A);
  static const _wallWidth = 4.0;

  WallPainter({
    required this.walls,
    required this.cellSize,
    this.origin = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (walls.isEmpty) return;

    final wallPaint = Paint()
      ..color = _wallColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _wallWidth
      ..strokeCap = StrokeCap.round;

    for (final wall in walls) {
      final edge = _getSharedEdge(wall);
      if (edge != null) {
        canvas.drawLine(edge.$1, edge.$2, wallPaint);
      }
    }
  }

  /// Calculates the shared edge between two adjacent cells.
  ///
  /// Returns the two endpoints of the edge line, or null if cells aren't adjacent.
  (Offset, Offset)? _getSharedEdge(HexEdge wall) {
    final cell1Center = HexUtils.axialToPixel(
      wall.q1,
      wall.r1,
      cellSize,
      origin,
    );

    // Find the neighbor direction from cell1 to cell2
    final dq = wall.q2 - wall.q1;
    final dr = wall.r2 - wall.r1;

    // Map direction to edge index for flat-top hexagons.
    // Vertices are clockwise from right (0°): 0=right, 1=lower-right, etc.
    // Edge i connects vertex i to vertex (i+1)%6
    final edgeIndex = _getEdgeIndex(dq, dr);
    if (edgeIndex == null) return null;

    final vertices = HexUtils.getHexVertices(cell1Center, cellSize);
    final p1 = vertices[edgeIndex];
    final p2 = vertices[(edgeIndex + 1) % 6];

    return (p1, p2);
  }

  /// Maps neighbor direction (dq, dr) to edge index.
  ///
  /// For flat-top hexagons with vertices starting at 0° (right):
  /// - Edge 0 (vertices 0-1): faces East (dq=+1, dr=0)
  /// - Edge 1 (vertices 1-2): faces Southeast (dq=0, dr=+1)
  /// - Edge 2 (vertices 2-3): faces Southwest (dq=-1, dr=+1)
  /// - Edge 3 (vertices 3-4): faces West (dq=-1, dr=0)
  /// - Edge 4 (vertices 4-5): faces Northwest (dq=0, dr=-1)
  /// - Edge 5 (vertices 5-0): faces Northeast (dq=+1, dr=-1)
  int? _getEdgeIndex(int dq, int dr) {
    if (dq == 1 && dr == 0) return 0; // East
    if (dq == 0 && dr == 1) return 1; // Southeast
    if (dq == -1 && dr == 1) return 2; // Southwest
    if (dq == -1 && dr == 0) return 3; // West
    if (dq == 0 && dr == -1) return 4; // Northwest
    if (dq == 1 && dr == -1) return 5; // Northeast
    return null; // Not adjacent
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) {
    return walls != oldDelegate.walls ||
        cellSize != oldDelegate.cellSize ||
        origin != oldDelegate.origin;
  }
}
