/// Represents a wall/edge between two adjacent hexagonal cells.
///
/// Edges are stored in canonical order (cell1 < cell2) to ensure
/// that HexEdge(A, B) == HexEdge(B, A) for consistent equality and hashing.
class HexEdge {
  final int q1;
  final int r1;
  final int q2;
  final int r2;

  /// Creates a HexEdge between two cells, automatically applying canonical ordering.
  ///
  /// The cells are ordered such that the "smaller" cell (by q, then by r)
  /// is always stored as cell1.
  HexEdge({
    required int cellQ1,
    required int cellR1,
    required int cellQ2,
    required int cellR2,
  }) : q1 = _isFirstSmaller(cellQ1, cellR1, cellQ2, cellR2) ? cellQ1 : cellQ2,
       r1 = _isFirstSmaller(cellQ1, cellR1, cellQ2, cellR2) ? cellR1 : cellR2,
       q2 = _isFirstSmaller(cellQ1, cellR1, cellQ2, cellR2) ? cellQ2 : cellQ1,
       r2 = _isFirstSmaller(cellQ1, cellR1, cellQ2, cellR2) ? cellR2 : cellR1;

  /// Creates a HexEdge from two HexCell-like objects with q and r properties.
  factory HexEdge.fromCells(({int q, int r}) cell1, ({int q, int r}) cell2) {
    return HexEdge(
      cellQ1: cell1.q,
      cellR1: cell1.r,
      cellQ2: cell2.q,
      cellR2: cell2.r,
    );
  }

  /// Determines if the first cell should come before the second in canonical order.
  static bool _isFirstSmaller(int q1, int r1, int q2, int r2) {
    if (q1 != q2) return q1 < q2;
    return r1 < r2;
  }

  /// Cell 1 coordinates (the "smaller" cell in canonical order).
  ({int q, int r}) get cell1 => (q: q1, r: r1);

  /// Cell 2 coordinates (the "larger" cell in canonical order).
  ({int q, int r}) get cell2 => (q: q2, r: r2);

  /// Checks if this edge connects the given cell to any other cell.
  bool connectsCell({required int q, required int r}) {
    return (q1 == q && r1 == r) || (q2 == q && r2 == r);
  }

  /// Checks if this edge connects the two given cells.
  bool connects({
    required int q1,
    required int r1,
    required int q2,
    required int r2,
  }) {
    // Check both orderings since we don't know which order the caller provides
    return (this.q1 == q1 && this.r1 == r1 && this.q2 == q2 && this.r2 == r2) ||
        (this.q1 == q2 && this.r1 == r2 && this.q2 == q1 && this.r2 == r1);
  }

  /// Serializes the edge to JSON.
  Map<String, dynamic> toJson() {
    return {'q1': q1, 'r1': r1, 'q2': q2, 'r2': r2};
  }

  /// Creates a HexEdge from JSON data.
  factory HexEdge.fromJson(Map<String, dynamic> json) {
    return HexEdge(
      cellQ1: json['q1'] as int,
      cellR1: json['r1'] as int,
      cellQ2: json['q2'] as int,
      cellR2: json['r2'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HexEdge &&
        other.q1 == q1 &&
        other.r1 == r1 &&
        other.q2 == q2 &&
        other.r2 == r2;
  }

  @override
  int get hashCode => Object.hash(q1, r1, q2, r2);

  @override
  String toString() => 'HexEdge(($q1, $r1) <-> ($q2, $r2))';
}
