import '../models/hex_cell.dart';
import '../models/hex_edge.dart';
import '../models/level.dart';

/// Creates a hardcoded test level for development and testing.
///
/// This is a 4x4 hexagonal grid (16 cells) with 3 checkpoints and
/// strategic walls that create exactly one solution path.
///
/// Grid layout (axial coordinates q,r):
/// ```
///     (0,0) (1,0) (2,0) (3,0)
///   (0,1) (1,1) (2,1) (3,1)
///     (0,2) (1,2) (2,2) (3,2)
///   (0,3) (1,3) (2,3) (3,3)
/// ```
///
/// Checkpoint positions:
/// - Checkpoint 1 (start): (0,0) - top left
/// - Checkpoint 2 (middle): (1,2) - center-left area
/// - Checkpoint 3 (end): (3,3) - bottom right corner (must be last)
///
/// The walls force the path to snake through the grid while
/// visiting checkpoint 2 before reaching checkpoint 3 as the final cell.
Level getTestLevel() {
  // Create 4x4 grid of cells (16 cells total)
  final cells = <(int, int), HexCell>{};

  for (var q = 0; q < 4; q++) {
    for (var r = 0; r < 4; r++) {
      int? checkpoint;
      if (q == 0 && r == 0) checkpoint = 1; // Start
      if (q == 1 && r == 2) checkpoint = 2; // Middle checkpoint
      if (q == 3 && r == 3) checkpoint = 3; // End (must be final cell)

      cells[(q, r)] = HexCell(q: q, r: r, checkpoint: checkpoint);
    }
  }

  // Strategic walls to create a challenging but solvable puzzle
  // The walls force a path that ends at checkpoint 3 (3,3) as the final cell
  final walls = <HexEdge>{
    // Wall between (0,1) and (1,1) - forces early path choice
    HexEdge(cellQ1: 0, cellR1: 1, cellQ2: 1, cellR2: 1),
    // Wall between (2,1) and (2,2) - creates routing constraint
    HexEdge(cellQ1: 2, cellR1: 1, cellQ2: 2, cellR2: 2),
    // Wall between (2,3) and (3,3) - protects final approach to end
    HexEdge(cellQ1: 2, cellR1: 3, cellQ2: 3, cellR2: 3),
  };

  return Level(size: 4, cells: cells, walls: walls, checkpointCount: 3);
}
