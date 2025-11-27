import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/data/test_level.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/hex_cell.dart';
import '../../domain/services/game_engine.dart';

/// Notifier that wraps [GameEngine] for Riverpod state management.
///
/// Exposes game state and provides methods to interact with the game.
class GameNotifier extends Notifier<GameState> {
  late GameEngine _engine;

  @override
  GameState build() {
    final level = getTestLevel();
    _engine = GameEngine(level: level, mode: GameMode.practice);
    return _engine.state;
  }

  /// Attempts to move to the target cell.
  ///
  /// Returns true if the move was successful.
  bool tryMove(HexCell target) {
    final result = _engine.tryMove(target);
    state = _engine.state;
    return result.success;
  }

  /// Undoes the last move.
  ///
  /// Returns true if undo was successful.
  bool undo() {
    final success = _engine.undo();
    if (success) {
      state = _engine.state;
    }
    return success;
  }

  /// Resets the game to initial state.
  void reset() {
    _engine.reset();
    state = _engine.state;
  }
}

/// Provider for game state management.
final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
