import 'hex_cell.dart';
import 'hex_edge.dart';
import 'level.dart';

/// Available tools in the level editor.
enum EditorTool {
  /// Select and inspect cells.
  select,

  /// Toggle walls between adjacent cells.
  wall,

  /// Set or cycle checkpoint numbers on cells.
  checkpoint,

  /// Remove checkpoints or walls.
  eraser,
}

/// Immutable state for the level editor.
///
/// Tracks the current grid configuration, selected tool, and validation
/// status. Provides mutation methods that return new state instances.
class EditorState {
  final int gridSize;
  final Map<(int, int), HexCell> cells;
  final Set<HexEdge> walls;
  final int checkpointCount;
  final EditorTool currentTool;
  final (int, int)? selectedCell;
  final bool isValid;
  final String? validationError;
  final List<String> warnings;

  const EditorState({
    required this.gridSize,
    required this.cells,
    required this.walls,
    required this.checkpointCount,
    this.currentTool = EditorTool.select,
    this.selectedCell,
    this.isValid = false,
    this.validationError,
    this.warnings = const [],
  });

  /// Creates an empty editor state with default values.
  const EditorState.empty()
    : gridSize = 2,
      cells = const {},
      walls = const {},
      checkpointCount = 0,
      currentTool = EditorTool.select,
      selectedCell = null,
      isValid = false,
      validationError = null,
      warnings = const [];

  /// Converts the current editor state to a playable [Level].
  Level toLevel() {
    return Level(
      size: gridSize,
      cells: cells,
      walls: walls,
      checkpointCount: checkpointCount,
    );
  }

  /// Returns a new state with the wall between two cells toggled.
  ///
  /// If a wall exists between the cells, it is removed.
  /// If no wall exists, one is added.
  EditorState withWallToggled(int q1, int r1, int q2, int r2) {
    final edge = HexEdge(cellQ1: q1, cellR1: r1, cellQ2: q2, cellR2: r2);
    final newWalls = Set<HexEdge>.from(walls);

    if (newWalls.contains(edge)) {
      newWalls.remove(edge);
    } else {
      newWalls.add(edge);
    }

    return copyWith(walls: newWalls, isValid: false, validationError: null);
  }

  /// Returns a new state with a checkpoint set or removed on a cell.
  ///
  /// If [checkpoint] is null, removes the checkpoint from the cell.
  /// Updates [checkpointCount] based on the highest checkpoint number.
  EditorState withCheckpointSet(int q, int r, int? checkpoint) {
    final newCells = Map<(int, int), HexCell>.from(cells);
    final existingCell = newCells[(q, r)];
    if (existingCell == null) return this;

    newCells[(q, r)] = HexCell(q: q, r: r, checkpoint: checkpoint);

    // Recalculate checkpoint count from all cells
    var maxCheckpoint = 0;
    for (final cell in newCells.values) {
      if (cell.checkpoint != null && cell.checkpoint! > maxCheckpoint) {
        maxCheckpoint = cell.checkpoint!;
      }
    }

    return copyWith(
      cells: newCells,
      checkpointCount: maxCheckpoint,
      isValid: false,
      validationError: null,
    );
  }

  /// Returns a new state with a different grid size.
  ///
  /// This triggers a full grid rebuild in the editor service.
  EditorState withGridSize(int size) {
    return copyWith(gridSize: size);
  }

  /// Creates a copy with optional updated fields.
  EditorState copyWith({
    int? gridSize,
    Map<(int, int), HexCell>? cells,
    Set<HexEdge>? walls,
    int? checkpointCount,
    EditorTool? currentTool,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    bool? isValid,
    String? validationError,
    bool clearValidationError = false,
    List<String>? warnings,
  }) {
    return EditorState(
      gridSize: gridSize ?? this.gridSize,
      cells: cells ?? this.cells,
      walls: walls ?? this.walls,
      checkpointCount: checkpointCount ?? this.checkpointCount,
      currentTool: currentTool ?? this.currentTool,
      selectedCell: clearSelectedCell
          ? null
          : (selectedCell ?? this.selectedCell),
      isValid: isValid ?? this.isValid,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      warnings: warnings ?? this.warnings,
    );
  }

  @override
  String toString() =>
      'EditorState(size: $gridSize, cells: ${cells.length}, '
      'walls: ${walls.length}, checkpoints: $checkpointCount, '
      'tool: $currentTool, valid: $isValid)';
}
