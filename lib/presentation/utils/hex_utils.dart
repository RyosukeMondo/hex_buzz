import 'dart:math';
import 'dart:ui';

/// Utility functions for hexagonal grid coordinate conversions.
///
/// Uses flat-top hexagon orientation consistent with HexCell.toPixel().
/// Coordinate systems:
/// - Axial: (q, r) where q is column, r is row, s = -q-r (implicit)
/// - Pixel: (x, y) screen coordinates with origin at top-left
class HexUtils {
  HexUtils._();

  /// Converts axial coordinates (q, r) to pixel position.
  ///
  /// [q] and [r] are the axial coordinates.
  /// [cellSize] is the distance from center to corner (outer radius).
  /// [origin] is the pixel offset for the grid origin (default: 0,0).
  ///
  /// Returns the center position of the hexagon in pixel coordinates.
  static Offset axialToPixel(
    int q,
    int r,
    double cellSize, [
    Offset origin = Offset.zero,
  ]) {
    final x = cellSize * (3 / 2 * q);
    final y = cellSize * (sqrt(3) / 2 * q + sqrt(3) * r);
    return Offset(x + origin.dx, y + origin.dy);
  }

  /// Converts pixel position to axial coordinates.
  ///
  /// [pixel] is the screen position to convert.
  /// [cellSize] is the distance from center to corner (outer radius).
  /// [origin] is the pixel offset for the grid origin (default: 0,0).
  ///
  /// Returns the (q, r) axial coordinates of the containing hexagon.
  static ({int q, int r}) pixelToAxial(
    Offset pixel,
    double cellSize, [
    Offset origin = Offset.zero,
  ]) {
    final adjustedX = pixel.dx - origin.dx;
    final adjustedY = pixel.dy - origin.dy;

    // Convert to fractional axial coordinates (inverse of axialToPixel)
    final q = (2 / 3 * adjustedX) / cellSize;
    final r = (-1 / 3 * adjustedX + sqrt(3) / 3 * adjustedY) / cellSize;

    // Round to nearest hex using cube coordinate rounding
    return _axialRound(q, r);
  }

  /// Rounds fractional axial coordinates to the nearest hex.
  ///
  /// Uses cube coordinate rounding for accuracy.
  static ({int q, int r}) _axialRound(double q, double r) {
    // Convert to cube coordinates (q, r, s where s = -q - r)
    final s = -q - r;

    var rq = q.round();
    var rr = r.round();
    var rs = s.round();

    // Fix rounding errors: cube coordinates must sum to 0
    final qDiff = (rq - q).abs();
    final rDiff = (rr - r).abs();
    final sDiff = (rs - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      rq = -rr - rs;
    } else if (rDiff > sDiff) {
      rr = -rq - rs;
    }
    // s is not used in axial coordinates, so we don't need to fix it

    return (q: rq, r: rr);
  }

  /// Calculates the 6 vertices of a flat-top hexagon.
  ///
  /// [center] is the center position of the hexagon.
  /// [size] is the distance from center to corner (outer radius).
  ///
  /// Returns vertices in clockwise order starting from the right corner.
  static List<Offset> getHexVertices(Offset center, double size) {
    final vertices = <Offset>[];
    for (var i = 0; i < 6; i++) {
      // Flat-top: start at 0 degrees (right corner)
      final angleDeg = 60.0 * i;
      final angleRad = pi / 180 * angleDeg;
      vertices.add(
        Offset(
          center.dx + size * cos(angleRad),
          center.dy + size * sin(angleRad),
        ),
      );
    }
    return vertices;
  }

  /// Calculates the inner radius (apothem) of a hexagon.
  ///
  /// [outerRadius] is the distance from center to corner.
  /// Returns the distance from center to the middle of an edge.
  static double innerRadius(double outerRadius) {
    return outerRadius * sqrt(3) / 2;
  }

  /// Calculates the width of a flat-top hexagon.
  ///
  /// [size] is the distance from center to corner (outer radius).
  static double hexWidth(double size) {
    return size * 2;
  }

  /// Calculates the height of a flat-top hexagon.
  ///
  /// [size] is the distance from center to corner (outer radius).
  static double hexHeight(double size) {
    return size * sqrt(3);
  }

  /// Calculates the horizontal spacing between hex centers (column spacing).
  ///
  /// [size] is the distance from center to corner (outer radius).
  static double horizontalSpacing(double size) {
    return size * 3 / 2;
  }

  /// Calculates the vertical spacing between hex centers (row spacing).
  ///
  /// [size] is the distance from center to corner (outer radius).
  static double verticalSpacing(double size) {
    return size * sqrt(3);
  }

  /// Checks if a pixel position is inside a hexagon.
  ///
  /// [pixel] is the point to test.
  /// [center] is the center of the hexagon.
  /// [size] is the distance from center to corner (outer radius).
  static bool isInsideHex(Offset pixel, Offset center, double size) {
    final dx = (pixel.dx - center.dx).abs();
    final dy = (pixel.dy - center.dy).abs();

    // Use hexagon boundary equations for flat-top orientation
    final inner = innerRadius(size);
    if (dx > size || dy > inner) return false;

    // Check the angled edges
    return inner * size - inner * dx - size / 2 * dy >= 0;
  }
}
