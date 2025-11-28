import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game_mode.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/hex_cell.dart';
import '../../domain/models/level.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/level_generator.dart';
import '../../domain/services/level_repository.dart';

/// Configuration for creating a game.
class GameConfig {
  final Level? level;
  final GameMode mode;
  final GameEngine? engine;
  final int edgeSize;

  const GameConfig({
    this.level,
    required this.mode,
    this.engine,
    this.edgeSize = 3,
  });
}

/// Provider for game configuration, allowing dependency injection.
final gameConfigProvider = Provider<GameConfig>((ref) {
  return const GameConfig(mode: GameMode.practice, edgeSize: 3);
});

/// Provider for the level generator (fallback for when no pre-generated levels).
final levelGeneratorProvider = Provider<LevelGenerator>((ref) {
  return LevelGenerator();
});

/// Provider for the level repository (pre-generated levels).
final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LevelRepository();
});

/// Notifier that wraps [GameEngine] for Riverpod state management.
///
/// Exposes game state and provides methods to interact with the game.
/// Supports dependency injection via [gameConfigProvider] for testability.
class GameNotifier extends Notifier<GameState> {
  late GameEngine _engine;
  late LevelGenerator _generator;
  late LevelRepository _repository;
  late int _edgeSize;
  bool _isGenerating = false;
  bool _repositoryLoaded = false;

  @override
  GameState build() {
    final config = ref.watch(gameConfigProvider);
    _generator = ref.watch(levelGeneratorProvider);
    _repository = ref.watch(levelRepositoryProvider);
    _edgeSize = config.edgeSize;

    // Check if repository was pre-loaded (via provider override)
    _repositoryLoaded = _repository.isLoaded;

    // Generate initial level if not provided (will use fallback generator)
    final level = config.level ?? _getOrGenerateLevel();

    _engine = config.engine ?? GameEngine(level: level, mode: config.mode);
    return _engine.state;
  }

  /// Whether a level is currently being generated.
  bool get isGenerating => _isGenerating;

  /// Current edge size for level generation.
  int get edgeSize => _edgeSize;

  /// Whether the level repository is loaded.
  bool get isRepositoryLoaded => _repositoryLoaded;

  /// Loads the pre-generated levels repository.
  ///
  /// Should be called during app initialization.
  Future<void> loadRepository() async {
    if (_repositoryLoaded) return;
    await _repository.load();
    _repositoryLoaded = true;
  }

  /// Gets a level from repository or generates one if not available.
  Level _getOrGenerateLevel() {
    // Try pre-generated first if loaded
    if (_repositoryLoaded) {
      final level = _repository.getRandomLevel(_edgeSize);
      if (level != null) return level;
    }
    // Fallback to generation
    return _generateLevel();
  }

  /// Generate a new level with current edge size (fallback).
  Level _generateLevel() {
    final result = _generator.generate(_edgeSize);
    if (result.success) {
      return result.level!;
    }
    // Fallback: try smaller size or throw
    throw StateError('Failed to generate level: ${result.error}');
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

  /// Resets the game to initial state (same level).
  void reset() {
    _engine.reset();
    state = _engine.state;
  }

  /// Generates a new level and starts a new game.
  ///
  /// Uses pre-generated levels if available, falls back to generation.
  /// Returns true if successful.
  bool generateNewLevel({int? newEdgeSize}) {
    if (_isGenerating) return false;

    _isGenerating = true;

    try {
      if (newEdgeSize != null) {
        _edgeSize = newEdgeSize;
      }

      // Try pre-generated first
      Level? level;
      if (_repositoryLoaded) {
        level = _repository.getRandomLevel(_edgeSize);
      }

      // Fall back to generation if no pre-generated available
      if (level == null) {
        final result = _generator.generate(_edgeSize);
        if (!result.success) {
          _isGenerating = false;
          return false;
        }
        level = result.level!;
      }

      _engine = GameEngine(level: level, mode: _engine.state.mode);
      state = _engine.state;
      _isGenerating = false;
      return true;
    } catch (e) {
      _isGenerating = false;
      return false;
    }
  }

  /// Sets the edge size for future level generation.
  void setEdgeSize(int size) {
    if (size >= 2 && size <= 6) {
      _edgeSize = size;
    }
  }
}

/// Provider for game state management.
final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
