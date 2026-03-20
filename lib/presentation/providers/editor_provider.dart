import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/editor_state.dart';
import '../../domain/models/hex_cell.dart';
import '../../domain/models/level.dart';
import '../../domain/models/user_level.dart';
import '../../domain/services/level_editor_service.dart';
import '../../domain/services/user_level_repository.dart';
import 'auth_provider.dart';

/// Provider for the level editor service (dependency injection point).
final levelEditorServiceProvider = Provider<LevelEditorService>((ref) {
  return const LevelEditorService();
});

/// Provider for the user level repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation.
final userLevelRepositoryProvider = Provider<UserLevelRepository>((ref) {
  throw UnimplementedError(
    'userLevelRepositoryProvider must be overridden with a concrete '
    'implementation',
  );
});

/// Notifier for managing level editor state.
///
/// Provides methods for all editor interactions: tool selection,
/// cell/edge tapping, grid resizing, validation, and saving.
class EditorNotifier extends Notifier<EditorState> {
  late LevelEditorService _service;

  @override
  EditorState build() {
    _service = ref.watch(levelEditorServiceProvider);
    return _service.createEmptyGrid(2);
  }

  /// Sets the active editor tool.
  void setTool(EditorTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// Handles a tap on a cell, performing the action for the current tool.
  ///
  /// - [EditorTool.select]: Selects the cell.
  /// - [EditorTool.checkpoint]: Cycles through checkpoint numbers.
  /// - [EditorTool.eraser]: Removes the checkpoint from the cell.
  /// - [EditorTool.wall]: Selects the cell (walls are toggled via edges).
  void tapCell(int q, int r) {
    if (!state.cells.containsKey((q, r))) return;

    switch (state.currentTool) {
      case EditorTool.select:
      case EditorTool.wall:
        state = state.copyWith(selectedCell: (q, r));

      case EditorTool.checkpoint:
        _cycleCheckpoint(q, r);

      case EditorTool.eraser:
        _eraseCell(q, r);
    }
  }

  /// Handles a tap on an edge between two cells, toggling a wall.
  ///
  /// Only active when the wall or eraser tool is selected.
  void tapEdge(int q1, int r1, int q2, int r2) {
    if (state.currentTool != EditorTool.wall &&
        state.currentTool != EditorTool.eraser) {
      return;
    }

    // Verify both cells exist
    if (!state.cells.containsKey((q1, r1)) ||
        !state.cells.containsKey((q2, r2))) {
      return;
    }

    state = state.withWallToggled(q1, r1, q2, r2);
  }

  /// Sets the grid size, rebuilding the grid from scratch.
  ///
  /// Clears all walls and checkpoints.
  void setGridSize(int size) {
    state = _service.createEmptyGrid(size);
  }

  /// Validates the current editor state for solvability.
  ///
  /// Updates the state with validation results (isValid, error, warnings).
  void validate() {
    final validation = _service.validate(state);
    state = state.copyWith(
      isValid: validation.isValid,
      validationError: validation.error,
      clearValidationError: validation.error == null,
      warnings: validation.warnings,
    );
  }

  /// Clears all walls and checkpoints, keeping the grid size.
  void clear() {
    state = _service.createEmptyGrid(state.gridSize);
  }

  /// Saves the current level as a user level.
  ///
  /// Generates a share code, creates a [UserLevel], and persists it
  /// via the [UserLevelRepository].
  Future<void> saveLevel() async {
    final validation = _service.validate(state);
    if (!validation.isValid) return;

    final level = state.toLevel();
    final shareCode = _service.generateShareCode(level);

    final user = ref.read(authProvider).valueOrNull;
    final creatorId = user?.id ?? 'guest';
    final creatorName = user?.username ?? 'Guest';

    final userLevel = UserLevel(
      id: level.id,
      level: level,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: DateTime.now(),
      shareCode: shareCode,
    );

    try {
      final repository = ref.read(userLevelRepositoryProvider);
      await repository.saveLevel(userLevel);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save user level: $e');
      }
    }
  }

  /// Loads an existing level into the editor for modification.
  void loadLevel(Level level) {
    // Recalculate checkpoint count
    var maxCheckpoint = 0;
    for (final cell in level.cells.values) {
      if (cell.checkpoint != null && cell.checkpoint! > maxCheckpoint) {
        maxCheckpoint = cell.checkpoint!;
      }
    }

    state = EditorState(
      gridSize: level.size,
      cells: Map<(int, int), HexCell>.from(level.cells),
      walls: Set.from(level.walls),
      checkpointCount: maxCheckpoint,
    );
  }

  /// Auto-places start and end checkpoints.
  void autoPlaceCheckpoints() {
    state = _service.autoPlaceCheckpoints(state);
  }

  /// Cycles the checkpoint number on a cell.
  ///
  /// No checkpoint -> 1 -> 2 -> ... -> N+1 -> remove.
  void _cycleCheckpoint(int q, int r) {
    final cell = state.cells[(q, r)];
    if (cell == null) return;

    final int? newCheckpoint;
    if (cell.checkpoint == null) {
      newCheckpoint = state.checkpointCount + 1;
    } else if (cell.checkpoint! >= state.checkpointCount) {
      // Remove checkpoint and renumber remaining
      newCheckpoint = null;
    } else {
      newCheckpoint = cell.checkpoint! + 1;
    }

    if (newCheckpoint == null) {
      _removeAndRenumberCheckpoint(q, r, cell.checkpoint!);
    } else {
      state = state.withCheckpointSet(q, r, newCheckpoint);
    }
  }

  /// Removes a checkpoint and renumbers higher-numbered checkpoints.
  void _removeAndRenumberCheckpoint(int q, int r, int removedNumber) {
    var newState = state.withCheckpointSet(q, r, null);
    final newCells = Map<(int, int), HexCell>.from(newState.cells);

    // Renumber checkpoints that were higher than the removed one
    for (final entry in newCells.entries) {
      final cell = entry.value;
      if (cell.checkpoint != null && cell.checkpoint! > removedNumber) {
        newCells[entry.key] = HexCell(
          q: cell.q,
          r: cell.r,
          checkpoint: cell.checkpoint! - 1,
        );
      }
    }

    // Recalculate max checkpoint
    var maxCheckpoint = 0;
    for (final cell in newCells.values) {
      if (cell.checkpoint != null && cell.checkpoint! > maxCheckpoint) {
        maxCheckpoint = cell.checkpoint!;
      }
    }

    state = newState.copyWith(cells: newCells, checkpointCount: maxCheckpoint);
  }

  /// Erases checkpoint from a cell.
  void _eraseCell(int q, int r) {
    final cell = state.cells[(q, r)];
    if (cell == null || cell.checkpoint == null) return;

    _removeAndRenumberCheckpoint(q, r, cell.checkpoint!);
  }
}

/// Provider for editor state management.
final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);
