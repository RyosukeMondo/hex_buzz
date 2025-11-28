import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'hex_cell.dart';
import 'hex_edge.dart';

/// Represents a complete level definition with cells, walls, and checkpoints.
///
/// A level consists of a hexagonal grid of cells, some of which may have
/// checkpoint numbers, and walls that block passage between adjacent cells.
class Level {
  final String id;
  final int size;
  final Map<(int, int), HexCell> cells;
  final Set<HexEdge> walls;
  final int checkpointCount;

  Level._({
    required this.id,
    required this.size,
    required this.cells,
    required this.walls,
    required this.checkpointCount,
  });

  /// Creates a Level with the given parameters.
  ///
  /// The [id] is computed from the level's canonical representation if not provided.
  factory Level({
    String? id,
    required int size,
    required Map<(int, int), HexCell> cells,
    required Set<HexEdge> walls,
    required int checkpointCount,
  }) {
    final levelId = id ?? _computeHash(size, cells, walls, checkpointCount);
    return Level._(
      id: levelId,
      size: size,
      cells: Map.unmodifiable(cells),
      walls: Set.unmodifiable(walls),
      checkpointCount: checkpointCount,
    );
  }

  /// Returns the cell at the given coordinates, or null if not found.
  HexCell? getCell(int q, int r) => cells[(q, r)];

  /// Returns the starting cell (checkpoint 1).
  HexCell get startCell {
    return cells.values.firstWhere(
      (cell) => cell.checkpoint == 1,
      orElse: () => throw StateError('Level has no start cell (checkpoint 1)'),
    );
  }

  /// Returns the ending cell (last checkpoint).
  HexCell get endCell {
    return cells.values.firstWhere(
      (cell) => cell.checkpoint == checkpointCount,
      orElse: () => throw StateError('Level has no end cell'),
    );
  }

  /// Checks if there is a wall between two cells.
  bool hasWall(int q1, int r1, int q2, int r2) {
    final edge = HexEdge(cellQ1: q1, cellR1: r1, cellQ2: q2, cellR2: r2);
    return walls.contains(edge);
  }

  /// Returns all passable neighbors of a cell (no wall blocking).
  List<HexCell> getPassableNeighbors(HexCell cell) {
    final result = <HexCell>[];
    for (final neighbor in cell.neighbors) {
      final neighborCell = getCell(neighbor.q, neighbor.r);
      if (neighborCell != null &&
          !hasWall(cell.q, cell.r, neighbor.q, neighbor.r)) {
        result.add(neighborCell);
      }
    }
    return result;
  }

  /// Computes a deterministic SHA-256 hash of the level's canonical representation.
  static String _computeHash(
    int size,
    Map<(int, int), HexCell> cells,
    Set<HexEdge> walls,
    int checkpointCount,
  ) {
    final canonical = _toCanonicalString(size, cells, walls, checkpointCount);
    final bytes = utf8.encode(canonical);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Creates a canonical string representation for hashing.
  static String _toCanonicalString(
    int size,
    Map<(int, int), HexCell> cells,
    Set<HexEdge> walls,
    int checkpointCount,
  ) {
    final buffer = StringBuffer();
    buffer.write('size:$size;');
    buffer.write('checkpoints:$checkpointCount;');

    // Sort cells by coordinates for deterministic order
    final sortedCells = cells.entries.toList()
      ..sort((a, b) {
        final qCompare = a.key.$1.compareTo(b.key.$1);
        return qCompare != 0 ? qCompare : a.key.$2.compareTo(b.key.$2);
      });

    buffer.write('cells:');
    for (final entry in sortedCells) {
      final cell = entry.value;
      buffer.write('(${cell.q},${cell.r}');
      if (cell.checkpoint != null) {
        buffer.write(',cp${cell.checkpoint}');
      }
      buffer.write(')');
    }
    buffer.write(';');

    // Sort walls by canonical edge representation
    final sortedWalls = walls.toList()
      ..sort((a, b) {
        final q1Compare = a.q1.compareTo(b.q1);
        if (q1Compare != 0) return q1Compare;
        final r1Compare = a.r1.compareTo(b.r1);
        if (r1Compare != 0) return r1Compare;
        final q2Compare = a.q2.compareTo(b.q2);
        if (q2Compare != 0) return q2Compare;
        return a.r2.compareTo(b.r2);
      });

    buffer.write('walls:');
    for (final wall in sortedWalls) {
      buffer.write('(${wall.q1},${wall.r1})-(${wall.q2},${wall.r2})');
    }

    return buffer.toString();
  }

  /// Serializes the level to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'checkpointCount': checkpointCount,
      'cells': cells.values.map((c) => c.toJson()).toList(),
      'walls': walls.map((w) => w.toJson()).toList(),
    };
  }

  /// Creates a Level from JSON data.
  factory Level.fromJson(Map<String, dynamic> json) {
    final cellsList = (json['cells'] as List)
        .map((c) => HexCell.fromJson(c as Map<String, dynamic>))
        .toList();
    final cellsMap = {for (final c in cellsList) (c.q, c.r): c};

    final wallsList = (json['walls'] as List)
        .map((w) => HexEdge.fromJson(w as Map<String, dynamic>))
        .toSet();

    return Level(
      id: json['id'] as String?,
      size: json['size'] as int,
      cells: cellsMap,
      walls: wallsList,
      checkpointCount: json['checkpointCount'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Level && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Level($id, size: $size, cells: ${cells.length}, walls: ${walls.length})';
}
