import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/hex_cell.dart';
import '../models/level.dart';
import 'path_validator.dart';

/// Result of a move attempt.
class MoveResult {
  final bool success;
  final GameState state;
  final String? error;
  final bool isWin;

  const MoveResult._({
    required this.success,
    required this.state,
    this.error,
    this.isWin = false,
  });

  factory MoveResult.success(GameState state, {bool isWin = false}) {
    return MoveResult._(success: true, state: state, isWin: isWin);
  }

  factory MoveResult.failure(GameState state, String error) {
    return MoveResult._(success: false, state: state, error: error);
  }
}

/// Core game state machine that manages game flow.
///
/// Handles move validation, undo operations, and state transitions.
/// Uses [PathValidator] for all move validation logic.
class GameEngine {
  final PathValidator _validator;
  GameState _state;

  GameEngine({
    required Level level,
    required GameMode mode,
    PathValidator? validator,
  }) : _validator = validator ?? const PathValidator(),
       _state = GameState.initial(level: level, mode: mode);

  /// Creates a GameEngine with an existing game state.
  GameEngine.fromState({required GameState state, PathValidator? validator})
    : _validator = validator ?? const PathValidator(),
      _state = state;

  /// The current game state.
  GameState get state => _state;

  /// Attempts to move to the target cell.
  ///
  /// Returns a [MoveResult] indicating success/failure and the new state.
  /// Starts the timer on the first valid move.
  /// Records end time when win condition is met.
  MoveResult tryMove(HexCell target) {
    // If game is already complete, reject move
    if (_state.isComplete) {
      return MoveResult.failure(_state, 'Game already complete');
    }

    // Get the target cell from the level to ensure we have full cell info
    final targetCell = _state.level.getCell(target.q, target.r);
    if (targetCell == null) {
      return MoveResult.failure(_state, 'Target cell not in level');
    }

    // Validate the move
    final validation = _validator.isValidMove(_state, targetCell);
    if (!validation.isValid) {
      return MoveResult.failure(_state, validation.reason ?? 'Invalid move');
    }

    // Build the new path
    final newPath = [..._state.path, targetCell];

    // Determine the new checkpoint number
    var newNextCheckpoint = _state.nextCheckpoint;
    if (targetCell.checkpoint == _state.nextCheckpoint) {
      newNextCheckpoint++;
    }

    // Determine timing
    DateTime? newStartTime = _state.startTime;
    DateTime? newEndTime = _state.endTime;

    // Start timer on first move
    if (!_state.isStarted) {
      newStartTime = DateTime.now();
    }

    // Update state
    _state = _state.copyWith(
      path: newPath,
      nextCheckpoint: newNextCheckpoint,
      startTime: newStartTime,
    );

    // Check for win condition
    final winCheck = _validator.checkWinCondition(_state);
    if (winCheck.isWin) {
      newEndTime = DateTime.now();
      _state = _state.copyWith(endTime: newEndTime);
      return MoveResult.success(_state, isWin: true);
    }

    return MoveResult.success(_state);
  }

  /// Removes the last cell from the path (undo last move).
  ///
  /// Returns false if path is empty or game is complete.
  bool undo() {
    if (_state.path.isEmpty || _state.isComplete) {
      return false;
    }

    final lastCell = _state.path.last;
    final newPath = _state.path.sublist(0, _state.path.length - 1);

    // If we're undoing a checkpoint, decrement the counter
    var newNextCheckpoint = _state.nextCheckpoint;
    if (lastCell.checkpoint != null &&
        lastCell.checkpoint == _state.nextCheckpoint - 1) {
      newNextCheckpoint--;
    }

    _state = _state.copyWith(path: newPath, nextCheckpoint: newNextCheckpoint);

    return true;
  }

  /// Resets the game to its initial state.
  ///
  /// Clears the path and timing information.
  void reset() {
    _state = GameState.initial(level: _state.level, mode: _state.mode);
  }
}
