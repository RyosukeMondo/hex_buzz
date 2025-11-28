import 'dart:math';

import '../models/hex_cell.dart';
import '../models/hex_edge.dart';
import '../models/level.dart';
import 'level_validator.dart';

/// Result of level generation.
class GenerationResult {
  final bool success;
  final Level? level;
  final List<HexCell>? solutionPath;
  final String? error;
  final GenerationStats? stats;

  const GenerationResult.success(this.level, this.solutionPath, this.stats)
    : success = true,
      error = null;

  const GenerationResult.failure(this.error)
    : success = false,
      level = null,
      solutionPath = null,
      stats = null;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (level != null) 'level': level!.toJson(),
      if (solutionPath != null)
        'solutionPath': solutionPath!.map((c) => {'q': c.q, 'r': c.r}).toList(),
      if (error != null) 'error': error,
      if (stats != null) 'stats': stats!.toJson(),
    };
  }
}

/// Statistics about the generation process.
class GenerationStats {
  final int cellCount;
  final int wallCount;
  final int attemptsTaken;
  final int initialSolutionCount;
  final Duration generationTime;

  const GenerationStats({
    required this.cellCount,
    required this.wallCount,
    required this.attemptsTaken,
    required this.initialSolutionCount,
    required this.generationTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'cellCount': cellCount,
      'wallCount': wallCount,
      'attemptsTaken': attemptsTaken,
      'initialSolutionCount': initialSolutionCount,
      'generationTimeMs': generationTime.inMilliseconds,
    };
  }
}

/// Service for generating solvable levels with exactly ONE solution.
///
/// Algorithm:
/// 1. Create hexagonal grid with checkpoints
/// 2. Start with NO walls - count all solutions
/// 3. Identify "critical edges" - edges where alternative solutions diverge
/// 4. Add walls strategically to eliminate alternatives while keeping one path
/// 5. Verify exactly one solution remains
class LevelGenerator {
  final Random _random;
  final LevelValidator _validator;

  /// Maximum attempts before giving up on a single configuration
  static const _maxAttempts = 50;

  /// Maximum solutions to count (for performance)
  static const _maxSolutionCount = 1000;

  LevelGenerator({Random? random, LevelValidator? validator})
    : _random = random ?? Random(),
      _validator = validator ?? const LevelValidator();

  /// Generates a level with the specified edge size and exactly one solution.
  ///
  /// [edgeSize] is the number of cells along each edge (minimum 2).
  /// A hexagonal grid with edge size n has 3n(n-1)+1 cells.
  ///
  /// Returns a [GenerationResult] with the generated level or error.
  GenerationResult generate(int edgeSize) {
    final stopwatch = Stopwatch()..start();

    if (edgeSize < 2) {
      return const GenerationResult.failure('Edge size must be at least 2');
    }

    // Create the hexagonal grid with checkpoints
    final cells = _createHexagonalGrid(edgeSize);
    final cellCount = cells.length;

    // Try multiple times with different random approaches
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final result = _tryGenerateLevel(cells, edgeSize);
      if (result != null) {
        stopwatch.stop();
        final stats = GenerationStats(
          cellCount: cellCount,
          wallCount: result.walls.length,
          attemptsTaken: attempt + 1,
          initialSolutionCount: result.initialSolutionCount,
          generationTime: stopwatch.elapsed,
        );
        return GenerationResult.success(
          result.level,
          result.solutionPath,
          stats,
        );
      }
    }

    stopwatch.stop();
    return const GenerationResult.failure(
      'Failed to generate level with unique solution after maximum attempts',
    );
  }

  /// Creates a hexagonal grid with checkpoints at top and bottom.
  Map<(int, int), HexCell> _createHexagonalGrid(int edgeSize) {
    final cells = <(int, int), HexCell>{};
    final maxCoord = edgeSize - 1;

    for (var q = -maxCoord; q <= maxCoord; q++) {
      for (var r = -maxCoord; r <= maxCoord; r++) {
        final s = -q - r;
        if (q.abs() <= maxCoord && r.abs() <= maxCoord && s.abs() <= maxCoord) {
          int? checkpoint;
          if (q == 0 && r == -maxCoord) checkpoint = 1; // Start - top
          if (q == 0 && r == maxCoord) checkpoint = 2; // End - bottom
          cells[(q, r)] = HexCell(q: q, r: r, checkpoint: checkpoint);
        }
      }
    }

    return cells;
  }

  /// Attempts to generate a valid level with unique solution.
  _GenerationAttempt? _tryGenerateLevel(
    Map<(int, int), HexCell> cells,
    int edgeSize,
  ) {
    // Create level with no walls
    var level = Level(
      size: edgeSize,
      cells: cells,
      walls: <HexEdge>{},
      checkpointCount: 2,
    );

    // Count initial solutions
    final initialResult = _validator.countSolutions(
      level,
      maxCount: _maxSolutionCount,
    );
    if (initialResult.count == 0) return null;
    if (initialResult.count == 1) {
      // Already unique - rare but possible
      return _GenerationAttempt(
        level,
        initialResult.firstSolution!,
        <HexEdge>{},
        initialResult.count,
      );
    }

    // Get all possible edges in the grid
    final allEdges = _getAllEdges(cells);

    // Shuffle edges for randomization
    final shuffledEdges = List<HexEdge>.from(allEdges)..shuffle(_random);

    // Try to reduce to exactly one solution by adding walls
    final walls = <HexEdge>{};

    for (final edge in shuffledEdges) {
      // Try adding this wall
      final testWalls = {...walls, edge};
      final testLevel = Level(
        size: edgeSize,
        cells: cells,
        walls: testWalls,
        checkpointCount: 2,
      );

      final result = _validator.countSolutions(testLevel, maxCount: 2);

      if (result.count == 1) {
        // Perfect! We found a unique solution
        return _GenerationAttempt(
          testLevel,
          result.firstSolution!,
          testWalls,
          initialResult.count,
        );
      } else if (result.count > 1) {
        // Still multiple solutions - keep this wall and continue
        walls.add(edge);
      }
      // If count == 0, this wall blocks all paths - don't add it
    }

    // Couldn't reduce to exactly one solution
    return null;
  }

  /// Gets all possible edges between adjacent cells.
  Set<HexEdge> _getAllEdges(Map<(int, int), HexCell> cells) {
    final edges = <HexEdge>{};
    final directions = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)];

    for (final cell in cells.values) {
      for (final (dq, dr) in directions) {
        final neighborCoord = (cell.q + dq, cell.r + dr);
        if (cells.containsKey(neighborCoord)) {
          // Normalize edge to avoid duplicates
          final edge = _normalizeEdge(
            cell.q,
            cell.r,
            neighborCoord.$1,
            neighborCoord.$2,
          );
          edges.add(edge);
        }
      }
    }

    return edges;
  }

  /// Normalizes an edge so the "smaller" cell comes first.
  HexEdge _normalizeEdge(int q1, int r1, int q2, int r2) {
    if (q1 < q2 || (q1 == q2 && r1 < r2)) {
      return HexEdge(cellQ1: q1, cellR1: r1, cellQ2: q2, cellR2: r2);
    }
    return HexEdge(cellQ1: q2, cellR1: r2, cellQ2: q1, cellR2: r1);
  }
}

/// Internal class for generation attempt results.
class _GenerationAttempt {
  final Level level;
  final List<HexCell> solutionPath;
  final Set<HexEdge> walls;
  final int initialSolutionCount;

  _GenerationAttempt(
    this.level,
    this.solutionPath,
    this.walls,
    this.initialSolutionCount,
  );
}
