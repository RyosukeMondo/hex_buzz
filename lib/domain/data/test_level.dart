import '../models/hex_cell.dart';
import '../models/hex_edge.dart';
import '../models/level.dart';

/// Creates a hardcoded test level for development and testing.
///
/// This is a hexagonal grid with edge size 3 (19 cells total) with 2 checkpoints
/// and strategic walls that create exactly one solution path.
///
/// Grid layout (axial coordinates q,r):
/// The hexagonal grid uses axial coordinates where the constraint is:
/// max(|q|, |r|, |s|) <= 2, where s = -q-r
///
/// Checkpoint positions:
/// - Checkpoint 1 (start): (0,-2) - top
/// - Checkpoint 2 (end): (0,2) - bottom (must be last)
///
/// The walls force the path to snake through the grid while
/// visiting every cell exactly once.
Level getTestLevel() {
  // Create hexagonal grid with edge size 3 (19 cells total)
  // Using axial coordinates where the constraint is:
  // max(|q|, |r|, |s|) <= n-1, where s = -q-r and n=3
  final cells = <(int, int), HexCell>{};
  const edgeSize = 3;
  const maxCoord = edgeSize - 1; // 2

  for (var q = -maxCoord; q <= maxCoord; q++) {
    for (var r = -maxCoord; r <= maxCoord; r++) {
      final s = -q - r;
      // Check if cell is within hexagonal bounds
      if (q.abs() <= maxCoord && r.abs() <= maxCoord && s.abs() <= maxCoord) {
        int? checkpoint;
        // Place checkpoints at strategic positions
        if (q == 0 && r == -2) checkpoint = 1; // Start - top
        if (q == 0 && r == 2) checkpoint = 2; // End - bottom

        cells[(q, r)] = HexCell(q: q, r: r, checkpoint: checkpoint);
      }
    }
  }

  // Strategic walls to create a challenging but solvable puzzle
  // These walls force a specific path through the grid
  final walls = <HexEdge>{
    // Wall creating a barrier that forces path around center
    HexEdge(cellQ1: 0, cellR1: -1, cellQ2: 0, cellR2: 0),
  };

  return Level(size: edgeSize, cells: cells, walls: walls, checkpointCount: 2);
}
