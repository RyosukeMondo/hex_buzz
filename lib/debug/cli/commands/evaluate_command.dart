import 'dart:convert';
import 'dart:io';

import '../../../domain/models/hex_cell.dart';
import '../../../domain/models/level.dart';
import '../../../domain/services/level_validator.dart';
import '../cli_runner.dart';

/// CLI command for evaluating level quality.
///
/// Analyzes a level and provides metrics about its difficulty,
/// structure, and solution characteristics.
class EvaluateCommand extends JsonCommand {
  @override
  final String name = 'evaluate';

  @override
  final String description = 'Evaluate a level\'s quality and difficulty';

  EvaluateCommand() {
    argParser.addOption('level', abbr: 'l', help: 'Level JSON string');
    argParser.addOption('file', abbr: 'f', help: 'Path to level JSON file');
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final levelJson = argResults?['level'] as String?;
    final filePath = argResults?['file'] as String?;

    if (levelJson == null && filePath == null) {
      throw ArgumentError('Either --level or --file must be provided');
    }

    if (levelJson != null && filePath != null) {
      throw ArgumentError('Cannot specify both --level and --file');
    }

    final jsonString = levelJson ?? await _readFile(filePath!);
    final level = _parseLevel(jsonString);

    return _evaluateLevel(level);
  }

  Future<String> _readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $path');
    }
    return file.readAsString();
  }

  Level _parseLevel(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Level.fromJson(json);
    } on FormatException {
      throw const FormatException('Invalid JSON format');
    } on TypeError catch (e) {
      throw FormatException('Invalid level structure: $e');
    }
  }

  Map<String, dynamic> _evaluateLevel(Level level) {
    final validator = const LevelValidator();
    final validationResult = validator.validate(level);

    // Basic metrics
    final cellCount = level.cells.length;
    final wallCount = level.walls.length;
    final checkpointCount = level.checkpointCount;

    // Calculate grid metrics
    final edgeSize = level.size;
    final maxPossibleWalls = _calculateMaxPossibleWalls(level);
    final wallDensity = maxPossibleWalls > 0
        ? (wallCount / maxPossibleWalls * 100).round()
        : 0;

    // Solution analysis
    Map<String, dynamic>? solutionAnalysis;
    if (validationResult.isSolvable && validationResult.solutionPath != null) {
      solutionAnalysis = _analyzeSolution(
        level,
        validationResult.solutionPath!,
      );
    }

    // Difficulty estimation (simple heuristic)
    final difficulty = _estimateDifficulty(
      cellCount: cellCount,
      wallCount: wallCount,
      checkpointCount: checkpointCount,
    );

    return {
      'valid': true,
      'solvable': validationResult.isSolvable,
      'solutionCount': validationResult.solutionCount,
      'hasUniqueSolution': validationResult.hasUniqueSolution,
      'metrics': {
        'edgeSize': edgeSize,
        'cellCount': cellCount,
        'wallCount': wallCount,
        'checkpointCount': checkpointCount,
        'wallDensity': '$wallDensity%',
        'maxPossibleWalls': maxPossibleWalls,
      },
      'difficulty': difficulty,
      if (solutionAnalysis != null) 'solution': solutionAnalysis,
      if (validationResult.error != null) 'error': validationResult.error,
    };
  }

  /// Calculates the maximum number of walls that could exist in a hex grid.
  /// Each internal edge can have a wall.
  int _calculateMaxPossibleWalls(Level level) {
    var count = 0;
    final cells = level.cells;

    for (final cell in cells.values) {
      // Count edges to neighbors (divide by 2 later to avoid double counting)
      final neighbors = [
        (cell.q + 1, cell.r),
        (cell.q + 1, cell.r - 1),
        (cell.q, cell.r - 1),
        (cell.q - 1, cell.r),
        (cell.q - 1, cell.r + 1),
        (cell.q, cell.r + 1),
      ];

      for (final coord in neighbors) {
        if (cells.containsKey(coord)) {
          count++;
        }
      }
    }

    return count ~/ 2; // Each edge counted twice
  }

  /// Analyzes the solution path.
  Map<String, dynamic> _analyzeSolution(Level level, List<HexCell> solution) {
    // Calculate direction changes (turns)
    var turns = 0;
    if (solution.length > 2) {
      for (var i = 1; i < solution.length - 1; i++) {
        final prev = solution[i - 1];
        final curr = solution[i];
        final next = solution[i + 1];

        final dir1 = (curr.q - prev.q, curr.r - prev.r);
        final dir2 = (next.q - curr.q, next.r - curr.r);

        if (dir1 != dir2) turns++;
      }
    }

    // Calculate checkpoint distances
    final checkpointDistances = <int>[];
    var lastCheckpointIndex = 0;
    for (var i = 0; i < solution.length; i++) {
      if (solution[i].checkpoint != null && i > 0) {
        checkpointDistances.add(i - lastCheckpointIndex);
        lastCheckpointIndex = i;
      }
    }

    return {
      'pathLength': solution.length,
      'turns': turns,
      'turnsPerCell': solution.length > 1
          ? (turns / (solution.length - 1) * 100).round() / 100
          : 0,
      'checkpointDistances': checkpointDistances,
    };
  }

  /// Estimates difficulty on a scale of 1-10.
  Map<String, dynamic> _estimateDifficulty({
    required int cellCount,
    required int wallCount,
    required int checkpointCount,
  }) {
    // Simple heuristic based on grid size and constraints
    var score = 1.0;

    // Larger grids are harder
    if (cellCount >= 7) score += 1; // Edge 2
    if (cellCount >= 19) score += 2; // Edge 3
    if (cellCount >= 37) score += 2; // Edge 4
    if (cellCount >= 61) score += 2; // Edge 5

    // More walls add complexity
    score += (wallCount / 10).clamp(0, 2);

    // More checkpoints add complexity
    score += (checkpointCount - 2) * 0.5;

    final level = score.round().clamp(1, 10);
    final labels = [
      'trivial',
      'very easy',
      'easy',
      'simple',
      'medium',
      'moderate',
      'challenging',
      'hard',
      'very hard',
      'expert',
    ];

    return {'score': level, 'label': labels[level - 1]};
  }
}
