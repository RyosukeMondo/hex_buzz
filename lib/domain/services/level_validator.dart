import '../models/hex_cell.dart';
import '../models/level.dart';

/// Result of level validation.
class ValidationResult {
  final bool isSolvable;
  final List<HexCell>? solutionPath;
  final int solutionCount;
  final String? error;

  const ValidationResult.solvable(this.solutionPath, {this.solutionCount = 1})
    : isSolvable = true,
      error = null;

  const ValidationResult.unsolvable(this.error)
    : isSolvable = false,
      solutionPath = null,
      solutionCount = 0;

  /// Whether this level has exactly one solution.
  bool get hasUniqueSolution => isSolvable && solutionCount == 1;

  Map<String, dynamic> toJson() {
    return {
      'isSolvable': isSolvable,
      'solutionCount': solutionCount,
      'hasUniqueSolution': hasUniqueSolution,
      if (solutionPath != null)
        'solutionPath': solutionPath!.map((c) => {'q': c.q, 'r': c.r}).toList(),
      if (error != null) 'error': error,
    };
  }
}

/// Service for validating levels and finding/counting solutions.
///
/// Uses DFS backtracking to find Hamiltonian paths that visit all cells
/// while respecting checkpoint order and wall constraints.
///
/// Rules:
/// - Path must start at checkpoint 1
/// - Path must visit checkpoints in order (1, 2, 3, ...)
/// - Path must end at the final checkpoint (which must be the last cell visited)
/// - Path must visit every cell exactly once
/// - Path cannot cross walls
class LevelValidator {
  const LevelValidator();

  /// Validates that a level is solvable.
  ///
  /// A level is solvable if there exists a Hamiltonian path from the start
  /// cell (checkpoint 1) to the end cell (last checkpoint) that:
  /// - Starts at checkpoint 1
  /// - Visits every cell exactly once
  /// - Visits checkpoints in order (1, 2, 3, ...)
  /// - Ends at the final checkpoint (last cell must be the end checkpoint)
  /// - Does not cross any walls
  ValidationResult validate(Level level) {
    // Basic validation checks
    final basicError = _validateBasicStructure(level);
    if (basicError != null) {
      return ValidationResult.unsolvable(basicError);
    }

    // Count all solutions and get the first one
    final result = countSolutions(level, maxCount: 2);
    if (result.count > 0) {
      return ValidationResult.solvable(
        result.firstSolution,
        solutionCount: result.count,
      );
    }

    return const ValidationResult.unsolvable('No valid path exists');
  }

  /// Validates and returns detailed solution count.
  ///
  /// [maxCount] limits how many solutions to find before stopping.
  /// Use maxCount=1 to just check solvability, maxCount=2 to check uniqueness.
  SolutionCountResult countSolutions(Level level, {int maxCount = 100}) {
    final basicError = _validateBasicStructure(level);
    if (basicError != null) {
      return const SolutionCountResult(count: 0, firstSolution: null);
    }

    final startCell = level.cells.values.firstWhere(
      (c) => c.checkpoint == 1,
      orElse: () => throw StateError('No start cell'),
    );

    final endCell = level.cells.values.firstWhere(
      (c) => c.checkpoint == level.checkpointCount,
      orElse: () => throw StateError('No end cell'),
    );

    final path = <HexCell>[startCell];
    final visited = <(int, int)>{(startCell.q, startCell.r)};
    final totalCells = level.cells.length;
    final solutions = <List<HexCell>>[];

    _countDfs(
      level,
      path,
      visited,
      totalCells,
      2, // Next checkpoint to find
      endCell,
      solutions,
      maxCount,
    );

    return SolutionCountResult(
      count: solutions.length,
      firstSolution: solutions.isNotEmpty ? solutions.first : null,
      allSolutions: solutions,
    );
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
    final result = countSolutions(level, maxCount: 1);
    return result.firstSolution;
  }

  /// DFS to count all solutions up to maxCount.
  ///
  /// Key constraint: The path must END at endCell (the final checkpoint).
  void _countDfs(
    Level level,
    List<HexCell> path,
    Set<(int, int)> visited,
    int totalCells,
    int nextCheckpoint,
    HexCell endCell,
    List<List<HexCell>> solutions,
    int maxCount,
  ) {
    // Stop if we've found enough solutions
    if (solutions.length >= maxCount) return;

    // Check if we've visited all cells
    if (path.length == totalCells) {
      final lastCell = path.last;
      // Valid solution: all cells visited AND last cell is the end checkpoint
      if (lastCell.q == endCell.q && lastCell.r == endCell.r) {
        solutions.add(List<HexCell>.from(path));
      }
      return;
    }

    final current = path.last;
    final neighbors = level.getPassableNeighbors(current);

    for (final neighbor in neighbors) {
      if (solutions.length >= maxCount) return;

      final coords = (neighbor.q, neighbor.r);

      // Skip if already visited
      if (visited.contains(coords)) continue;

      // Check checkpoint constraints
      if (neighbor.checkpoint != null) {
        // If this is a checkpoint, it must be the next one in sequence
        if (neighbor.checkpoint != nextCheckpoint) continue;

        // Don't visit the end checkpoint until it's the last cell
        // (This is enforced by the checkpoint sequence check above,
        // since end checkpoint is the highest number)
      }

      // Try this neighbor
      path.add(neighbor);
      visited.add(coords);

      final newNextCheckpoint = neighbor.checkpoint == nextCheckpoint
          ? nextCheckpoint + 1
          : nextCheckpoint;

      _countDfs(
        level,
        path,
        visited,
        totalCells,
        newNextCheckpoint,
        endCell,
        solutions,
        maxCount,
      );

      // Backtrack
      path.removeLast();
      visited.remove(coords);
    }
  }
}

/// Result of solution counting.
class SolutionCountResult {
  final int count;
  final List<HexCell>? firstSolution;
  final List<List<HexCell>> allSolutions;

  const SolutionCountResult({
    required this.count,
    required this.firstSolution,
    this.allSolutions = const [],
  });
}
