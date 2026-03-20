import '../models/game_state.dart';
import '../models/hex_cell.dart';

/// Result of a hint computation.
///
/// Contains the suggested next cell and a human-readable message.
/// When no hint is available, [isAvailable] is false.
class HintResult {
  final HexCell? suggestedCell;
  final String? message;
  final bool isAvailable;

  const HintResult({
    this.suggestedCell,
    this.message,
    this.isAvailable = true,
  });

  const HintResult.unavailable(String msg)
    : suggestedCell = null,
      message = msg,
      isAvailable = false;

  @override
  String toString() {
    if (!isAvailable) return 'HintResult.unavailable($message)';
    return 'HintResult(cell: $suggestedCell, message: $message)';
  }
}

/// Computes hints for the current game state.
///
/// Uses depth-first search to determine which neighbor cells lead to
/// valid solutions. Prefers checkpoint cells that match the next
/// expected checkpoint.
class HintService {
  const HintService();

  /// Returns a hint for the current game state.
  ///
  /// Logic:
  /// - If path is empty, suggests the start cell (checkpoint 1).
  /// - If game is complete, returns unavailable.
  /// - Otherwise, evaluates passable unvisited neighbors via DFS to find
  ///   which ones can lead to completing the puzzle.
  /// - Prefers the neighbor that is the next checkpoint.
  /// - If no valid path exists from any neighbor, suggests undoing.
  HintResult getHint(GameState state) {
    if (state.isComplete) {
      return const HintResult.unavailable('Puzzle already completed');
    }

    if (state.path.isEmpty) {
      return _suggestStartCell(state);
    }

    return _suggestNextMove(state);
  }

  HintResult _suggestStartCell(GameState state) {
    try {
      final startCell = state.level.startCell;
      return HintResult(
        suggestedCell: startCell,
        message: 'Start at checkpoint 1',
      );
    } on StateError {
      return const HintResult.unavailable('No start cell found');
    }
  }

  HintResult _suggestNextMove(GameState state) {
    final validNeighbors = _getValidNeighbors(state);
    if (validNeighbors == null) {
      return const HintResult.unavailable(
        'No valid moves available. Try undoing.',
      );
    }

    // If only one valid neighbor, suggest it directly
    if (validNeighbors.length == 1) {
      return _hintForCell(validNeighbors.first, state.nextCheckpoint);
    }

    return _evaluateBestNeighbor(validNeighbors, state);
  }

  /// Returns valid unvisited neighbors respecting checkpoint order,
  /// or null if none exist.
  List<HexCell>? _getValidNeighbors(GameState state) {
    final currentCell = state.currentCell!;
    final visited = state.visitedCoordinates;
    final neighbors = state.level.getPassableNeighbors(currentCell);
    final unvisited = neighbors
        .where((n) => !visited.contains((n.q, n.r)))
        .toList();

    if (unvisited.isEmpty) return null;

    final valid = _filterByCheckpointOrder(unvisited, state.nextCheckpoint);
    return valid.isEmpty ? null : valid;
  }

  /// Evaluates multiple valid neighbors using DFS and checkpoint priority.
  HintResult _evaluateBestNeighbor(
    List<HexCell> validNeighbors,
    GameState state,
  ) {
    final checkpointNeighbor = _findNextCheckpoint(
      validNeighbors,
      state.nextCheckpoint,
    );

    final solvableNeighbor = _findSolvableNeighbor(
      validNeighbors,
      state,
      checkpointNeighbor,
    );

    final suggestion =
        solvableNeighbor ?? checkpointNeighbor ?? validNeighbors.first;
    return _hintForCell(suggestion, state.nextCheckpoint);
  }

  HintResult _hintForCell(HexCell cell, int nextCheckpoint) {
    return HintResult(
      suggestedCell: cell,
      message: _messageForCell(cell, nextCheckpoint),
    );
  }

  /// Filters out neighbors that have a checkpoint number not matching
  /// the expected next checkpoint.
  List<HexCell> _filterByCheckpointOrder(
    List<HexCell> neighbors,
    int nextCheckpoint,
  ) {
    return neighbors.where((n) {
      if (n.checkpoint == null) return true;
      return n.checkpoint == nextCheckpoint;
    }).toList();
  }

  /// Finds the neighbor that matches the next expected checkpoint.
  HexCell? _findNextCheckpoint(
    List<HexCell> neighbors,
    int nextCheckpoint,
  ) {
    for (final n in neighbors) {
      if (n.checkpoint == nextCheckpoint) return n;
    }
    return null;
  }

  /// Uses DFS from each neighbor to check which can lead to a complete
  /// solution. Prefers checkpoint neighbors when solvable.
  HexCell? _findSolvableNeighbor(
    List<HexCell> neighbors,
    GameState state,
    HexCell? checkpointNeighbor,
  ) {
    // Check checkpoint neighbor first if present
    if (checkpointNeighbor != null) {
      if (_canSolveFrom(checkpointNeighbor, state)) {
        return checkpointNeighbor;
      }
    }

    // Check remaining neighbors
    for (final neighbor in neighbors) {
      if (neighbor == checkpointNeighbor) continue;
      if (_canSolveFrom(neighbor, state)) {
        return neighbor;
      }
    }
    return null;
  }

  /// Checks if moving to [cell] can eventually lead to visiting all
  /// remaining cells while respecting checkpoint order.
  bool _canSolveFrom(HexCell cell, GameState state) {
    final totalCells = state.level.cells.length;
    final visited = Set<(int, int)>.from(state.visitedCoordinates);
    visited.add((cell.q, cell.r));

    var nextCheckpoint = state.nextCheckpoint;
    if (cell.checkpoint == nextCheckpoint) {
      nextCheckpoint++;
    }

    return _dfs(cell, visited, nextCheckpoint, state, totalCells);
  }

  /// Recursive DFS that tries to visit all remaining cells.
  ///
  /// Returns true if a complete path exists from [current] visiting
  /// all unvisited cells while respecting checkpoint order and walls.
  bool _dfs(
    HexCell current,
    Set<(int, int)> visited,
    int nextCheckpoint,
    GameState state,
    int totalCells,
  ) {
    if (visited.length == totalCells) {
      return nextCheckpoint > state.level.checkpointCount;
    }

    final neighbors = state.level.getPassableNeighbors(current);
    for (final neighbor in neighbors) {
      final coords = (neighbor.q, neighbor.r);
      if (visited.contains(coords)) continue;

      // Check checkpoint order
      if (neighbor.checkpoint != null &&
          neighbor.checkpoint != nextCheckpoint) {
        continue;
      }

      visited.add(coords);
      var updatedCheckpoint = nextCheckpoint;
      if (neighbor.checkpoint == nextCheckpoint) {
        updatedCheckpoint++;
      }

      if (_dfs(neighbor, visited, updatedCheckpoint, state, totalCells)) {
        visited.remove(coords);
        return true;
      }
      visited.remove(coords);
    }

    return false;
  }

  String _messageForCell(HexCell cell, int nextCheckpoint) {
    if (cell.checkpoint == nextCheckpoint) {
      return 'Move to checkpoint $nextCheckpoint';
    }
    return 'Move to (${cell.q}, ${cell.r})';
  }
}
