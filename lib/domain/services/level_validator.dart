import '../models/hex_cell.dart';
import '../models/level.dart';

/// Result of level validation.
class ValidationResult {
  final bool isSolvable;
  final List<HexCell>? solutionPath;
  final String? error;

  const ValidationResult.solvable(this.solutionPath)
      : isSolvable = true,
        error = null;

  const ValidationResult.unsolvable(this.error)
      : isSolvable = false,
        solutionPath = null;

  Map<String, dynamic> toJson() {
    return {
      'isSolvable': isSolvable,
      if (solutionPath != null)
        'solutionPath': solutionPath!.map((c) => {'q': c.q, 'r': c.r}).toList(),
      if (error != null) 'error': error,
    };
  }
}

/// Service for validating levels and finding solutions.
///
/// Uses DFS backtracking to find a Hamiltonian path that visits all cells
/// while respecting checkpoint order and wall constraints.
class LevelValidator {
  const LevelValidator();

  /// Validates that a level is solvable.
  ///
  /// A level is solvable if there exists a Hamiltonian path from the start
  /// cell (checkpoint 1) to the end cell (last checkpoint) that:
  /// - Visits every cell exactly once
  /// - Visits checkpoints in order (1, 2, 3, ...)
  /// - Does not cross any walls
  ValidationResult validate(Level level) {
    // Basic validation checks
    final basicError = _validateBasicStructure(level);
    if (basicError != null) {
      return ValidationResult.unsolvable(basicError);
    }

    // Try to find a solution
    final solution = findSolution(level);
    if (solution != null) {
      return ValidationResult.solvable(solution);
    }

    return const ValidationResult.unsolvable('No valid path exists');
  }

  /// Performs basic structural validation on the level.
  String? _validateBasicStructure(Level level) {
    if (level.cells.isEmpty) {
      return 'Level has no cells';
    }

    if (level.checkpointCount < 2) {
      return 'Level must have at least 2 checkpoints (start and end)';
    }

    // Verify all checkpoints exist
    for (var i = 1; i <= level.checkpointCount; i++) {
      final hasCheckpoint = level.cells.values.any((c) => c.checkpoint == i);
      if (!hasCheckpoint) {
        return 'Missing checkpoint $i';
      }
    }

    return null;
  }

  /// Finds a solution path using DFS backtracking.
  ///
  /// Returns the solution path if found, null otherwise.
  List<HexCell>? findSolution(Level level) {
    final startCell = level.cells.values.firstWhere(
      (c) => c.checkpoint == 1,
      orElse: () => throw StateError('No start cell'),
    );

    final path = <HexCell>[startCell];
    final visited = <(int, int)>{(startCell.q, startCell.r)};
    final totalCells = level.cells.length;

    // Start DFS from checkpoint 1, next checkpoint is 2
    if (_dfs(level, path, visited, totalCells, 2)) {
      return path;
    }

    return null;
  }

  /// DFS backtracking to find Hamiltonian path.
  ///
  /// [level] - The level being solved
  /// [path] - Current path being built
  /// [visited] - Set of visited cell coordinates
  /// [totalCells] - Total number of cells that must be visited
  /// [nextCheckpoint] - The next checkpoint number we need to reach
  bool _dfs(
    Level level,
    List<HexCell> path,
    Set<(int, int)> visited,
    int totalCells,
    int nextCheckpoint,
  ) {
    // Check if we've visited all cells
    if (path.length == totalCells) {
      // Verify we've passed all checkpoints
      return nextCheckpoint > level.checkpointCount;
    }

    final current = path.last;
    final neighbors = level.getPassableNeighbors(current);

    for (final neighbor in neighbors) {
      final coords = (neighbor.q, neighbor.r);

      // Skip if already visited
      if (visited.contains(coords)) continue;

      // Check checkpoint constraints
      if (neighbor.checkpoint != null) {
        // If this is a checkpoint, it must be the next one in sequence
        if (neighbor.checkpoint != nextCheckpoint) continue;
      }

      // Try this neighbor
      path.add(neighbor);
      visited.add(coords);

      final newNextCheckpoint =
          neighbor.checkpoint == nextCheckpoint
              ? nextCheckpoint + 1
              : nextCheckpoint;

      if (_dfs(level, path, visited, totalCells, newNextCheckpoint)) {
        return true;
      }

      // Backtrack
      path.removeLast();
      visited.remove(coords);
    }

    return false;
  }
}
