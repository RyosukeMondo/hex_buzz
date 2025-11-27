import 'dart:math';

/// Represents a single hexagonal cell in the grid using axial coordinates.
///
/// Axial coordinates (q, r) are used for hexagonal grids where:
/// - q represents the column offset
/// - r represents the row
/// The third cube coordinate s can be derived as s = -q - r
class HexCell {
  final int q;
  final int r;
  final int? checkpoint;
  final bool visited;

  const HexCell({
    required this.q,
    required this.r,
    this.checkpoint,
    this.visited = false,
  });

  /// Creates a copy with optional updated fields.
  HexCell copyWith({
    int? q,
    int? r,
    int? checkpoint,
    bool? visited,
  }) {
    return HexCell(
      q: q ?? this.q,
      r: r ?? this.r,
      checkpoint: checkpoint ?? this.checkpoint,
      visited: visited ?? this.visited,
    );
  }

  /// Converts axial coordinates to pixel position for flat-top hexagons.
  ///
  /// [cellSize] is the distance from center to corner (outer radius).
  /// Returns an offset (x, y) representing the center of the cell.
  ({double x, double y}) toPixel(double cellSize) {
    final x = cellSize * (3 / 2 * q);
    final y = cellSize * (sqrt(3) / 2 * q + sqrt(3) * r);
    return (x: x, y: y);
  }

  /// Returns the 6 neighboring cell coordinates in axial format.
  ///
  /// Neighbors are returned in clockwise order starting from the right.
  List<({int q, int r})> get neighbors {
    return [
      (q: q + 1, r: r),     // East
      (q: q + 1, r: r - 1), // Northeast
      (q: q, r: r - 1),     // Northwest
      (q: q - 1, r: r),     // West
      (q: q - 1, r: r + 1), // Southwest
      (q: q, r: r + 1),     // Southeast
    ];
  }

  /// Checks if another cell is adjacent to this one.
  bool isAdjacentTo(HexCell other) {
    final dq = (other.q - q).abs();
    final dr = (other.r - r).abs();
    final ds = ((other.q + other.r) - (q + r)).abs();

    // In axial coordinates, two cells are adjacent if the sum of
    // absolute differences in q, r, and s equals 2 (with max of 1 each)
    return (dq + dr + ds == 2) && dq <= 1 && dr <= 1 && ds <= 1;
  }

  /// Serializes the cell to JSON.
  Map<String, dynamic> toJson() {
    return {
      'q': q,
      'r': r,
      if (checkpoint != null) 'checkpoint': checkpoint,
      'visited': visited,
    };
  }

  /// Creates a HexCell from JSON data.
  factory HexCell.fromJson(Map<String, dynamic> json) {
    return HexCell(
      q: json['q'] as int,
      r: json['r'] as int,
      checkpoint: json['checkpoint'] as int?,
      visited: json['visited'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HexCell && other.q == q && other.r == r;
  }

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() {
    final cp = checkpoint != null ? ', checkpoint: $checkpoint' : '';
    final vis = visited ? ', visited' : '';
    return 'HexCell($q, $r$cp$vis)';
  }
}
