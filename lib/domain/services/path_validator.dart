import '../models/game_state.dart';
import '../models/hex_cell.dart';
import '../models/level.dart';

/// Result of checking the win condition.
class WinCheckResult {
  final bool isWin;
  final String? reason;

  const WinCheckResult.win() : isWin = true, reason = null;
  const WinCheckResult.notWin(this.reason) : isWin = false;
}

/// Pure functions for validating path moves and detecting win conditions.
///
/// This service contains no state and all methods are pure functions
/// that validate game moves and check for win conditions.
class PathValidator {
  const PathValidator();

  /// Checks if two cells are adjacent in the hexagonal grid.
  bool isAdjacent(HexCell a, HexCell b) {
    return a.isAdjacentTo(b);
  }

  /// Checks if movement between two cells is not blocked by a wall.
  bool isPassable(Level level, HexCell from, HexCell to) {
    return !level.hasWall(from.q, from.r, to.q, to.r);
  }

  /// Validates if a move to the target cell is valid given the current game state.
  ///
  /// A move is valid if:
  /// 1. The target is adjacent to the current cell (or path is empty and target is start)
  /// 2. There is no wall blocking the movement
  /// 3. The target cell has not been visited
  /// 4. Checkpoint order is respected (if target has a checkpoint)
  MoveValidationResult isValidMove(GameState state, HexCell target) {
    final level = state.level;
    final path = state.path;
    final visitedCoords = state.visitedCoordinates;

    // Get the target cell from the level to ensure we have checkpoint info
    final targetCell = level.getCell(target.q, target.r);
    if (targetCell == null) {
      return const MoveValidationResult.invalid('Target cell not in level');
    }

    // First move must be the starting cell
    if (path.isEmpty) {
      if (targetCell.checkpoint != 1) {
        return const MoveValidationResult.invalid(
          'First move must be start cell',
        );
      }
      return const MoveValidationResult.valid();
    }

    final currentCell = path.last;

    // Check adjacency
    if (!isAdjacent(currentCell, targetCell)) {
      return const MoveValidationResult.invalid('Target not adjacent');
    }

    // Check for wall
    if (!isPassable(level, currentCell, targetCell)) {
      return const MoveValidationResult.invalid('Wall blocks movement');
    }

    // Check if already visited
    if (visitedCoords.contains((targetCell.q, targetCell.r))) {
      return const MoveValidationResult.invalid('Cell already visited');
    }

    // Check checkpoint order
    if (targetCell.checkpoint != null) {
      if (targetCell.checkpoint != state.nextCheckpoint) {
        return MoveValidationResult.invalid(
          'Wrong checkpoint order: expected ${state.nextCheckpoint}, got ${targetCell.checkpoint}',
        );
      }
    }

    return const MoveValidationResult.valid();
  }

  /// Checks if the current game state represents a win condition.
  ///
  /// Win condition is met when:
  /// 1. All cells in the level have been visited
  /// 2. All checkpoints have been visited in order (nextCheckpoint > checkpointCount)
  WinCheckResult checkWinCondition(GameState state) {
    final level = state.level;
    final path = state.path;

    // Check if all cells have been visited
    if (path.length != level.cells.length) {
      return WinCheckResult.notWin(
        'Not all cells visited: ${path.length}/${level.cells.length}',
      );
    }

    // Check if all checkpoints have been reached
    if (state.nextCheckpoint <= level.checkpointCount) {
      return WinCheckResult.notWin(
        'Not all checkpoints reached: next is ${state.nextCheckpoint}, need ${level.checkpointCount}',
      );
    }

    return const WinCheckResult.win();
  }
}

/// Result of move validation.
class MoveValidationResult {
  final bool isValid;
  final String? reason;

  const MoveValidationResult.valid() : isValid = true, reason = null;
  const MoveValidationResult.invalid(this.reason) : isValid = false;
}
