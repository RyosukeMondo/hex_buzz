import 'dart:convert';

import '../models/editor_state.dart';
import '../models/hex_cell.dart';
import '../models/level.dart';
import 'level_validator.dart';

/// Result of editor state validation.
class EditorValidation {
  final bool isValid;
  final String? error;
  final List<String> warnings;

  const EditorValidation({
    required this.isValid,
    this.error,
    this.warnings = const [],
  });

  const EditorValidation.valid({this.warnings = const []})
    : isValid = true,
      error = null;

  const EditorValidation.invalid(this.error, {this.warnings = const []})
    : isValid = false;
}

/// Service for level editor operations.
///
/// Handles grid creation, validation, checkpoint management, and
/// share code encoding/decoding. Uses [LevelValidator] for solvability checks.
class LevelEditorService {
  final LevelValidator _validator;

  const LevelEditorService({LevelValidator? validator})
    : _validator = validator ?? const LevelValidator();

  /// Creates an empty hexagonal grid of the given size with no walls
  /// or checkpoints.
  ///
  /// [size] is the edge size (minimum 2, maximum 6).
  /// Returns an [EditorState] with all cells and no walls.
  EditorState createEmptyGrid(int size) {
    final clampedSize = size.clamp(2, 6);
    final cells = _buildHexGrid(clampedSize);

    return EditorState(
      gridSize: clampedSize,
      cells: cells,
      walls: const {},
      checkpointCount: 0,
    );
  }

  /// Validates the current editor state produces a solvable level.
  ///
  /// Checks structural requirements first (checkpoints exist, proper
  /// sequence), then runs the full solvability check via [LevelValidator].
  EditorValidation validate(EditorState state) {
    final warnings = <String>[];

    // Check minimum checkpoint requirement
    if (state.checkpointCount < 2) {
      return const EditorValidation.invalid(
        'At least 2 checkpoints required (start and end)',
      );
    }

    // Check checkpoint sequence is contiguous (1, 2, ..., N)
    final sequenceError = _validateCheckpointSequence(state);
    if (sequenceError != null) {
      return EditorValidation.invalid(sequenceError);
    }

    // Build a level and run the validator
    final level = state.toLevel();
    final result = _validator.validate(level);

    if (!result.isSolvable) {
      return EditorValidation.invalid(
        result.error ?? 'No valid path exists',
      );
    }

    if (!result.hasUniqueSolution) {
      warnings.add('Level has multiple solutions');
    }

    return EditorValidation.valid(warnings: warnings);
  }

  /// Auto-places start (1) and end (N) checkpoints if not set.
  ///
  /// Places checkpoint 1 at the topmost cell and checkpoint 2 at
  /// the bottommost cell. Does not modify existing checkpoints.
  EditorState autoPlaceCheckpoints(EditorState state) {
    if (state.cells.isEmpty) return state;

    final hasStart = state.cells.values.any((c) => c.checkpoint == 1);
    final hasEnd = state.cells.values.any((c) => c.checkpoint == 2);

    if (hasStart && hasEnd) return state;

    final newCells = Map<(int, int), HexCell>.from(state.cells);
    final sortedByR = newCells.values.toList()
      ..sort((a, b) {
        final rCompare = a.r.compareTo(b.r);
        return rCompare != 0 ? rCompare : a.q.compareTo(b.q);
      });

    if (!hasStart) {
      final topCell = sortedByR.first;
      newCells[(topCell.q, topCell.r)] = HexCell(
        q: topCell.q,
        r: topCell.r,
        checkpoint: 1,
      );
    }

    if (!hasEnd) {
      // Find bottommost cell that is not checkpoint 1
      final bottomCell = sortedByR.reversed.firstWhere(
        (c) => newCells[(c.q, c.r)]?.checkpoint != 1,
        orElse: () => sortedByR.last,
      );
      newCells[(bottomCell.q, bottomCell.r)] = HexCell(
        q: bottomCell.q,
        r: bottomCell.r,
        checkpoint: 2,
      );
    }

    // Recalculate checkpoint count
    var maxCheckpoint = 0;
    for (final cell in newCells.values) {
      if (cell.checkpoint != null && cell.checkpoint! > maxCheckpoint) {
        maxCheckpoint = cell.checkpoint!;
      }
    }

    return state.copyWith(cells: newCells, checkpointCount: maxCheckpoint);
  }

  /// Generates a share code from a level.
  ///
  /// Encodes the level as JSON, compresses with base64url encoding,
  /// and returns a shortened string suitable for sharing.
  String generateShareCode(Level level) {
    final json = level.toJson();
    final jsonString = jsonEncode(json);
    final bytes = utf8.encode(jsonString);
    final encoded = base64Url.encode(bytes);
    return encoded;
  }

  /// Decodes a share code back to a level.
  ///
  /// Returns null if the share code is invalid or cannot be decoded.
  Level? decodeShareCode(String code) {
    try {
      final bytes = base64Url.decode(code);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Level.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Builds a hexagonal grid with the given edge size.
  ///
  /// Uses axial coordinates where the grid spans from -maxCoord to +maxCoord
  /// on each axis, filtered by the cube coordinate constraint |s| <= maxCoord.
  Map<(int, int), HexCell> _buildHexGrid(int edgeSize) {
    final cells = <(int, int), HexCell>{};
    final maxCoord = edgeSize - 1;

    for (var q = -maxCoord; q <= maxCoord; q++) {
      for (var r = -maxCoord; r <= maxCoord; r++) {
        final s = -q - r;
        if (q.abs() <= maxCoord &&
            r.abs() <= maxCoord &&
            s.abs() <= maxCoord) {
          cells[(q, r)] = HexCell(q: q, r: r);
        }
      }
    }

    return cells;
  }

  /// Validates that checkpoints form a contiguous sequence from 1 to N.
  String? _validateCheckpointSequence(EditorState state) {
    for (var i = 1; i <= state.checkpointCount; i++) {
      final hasCheckpoint = state.cells.values.any(
        (c) => c.checkpoint == i,
      );
      if (!hasCheckpoint) {
        return 'Missing checkpoint $i in sequence';
      }
    }
    return null;
  }
}
