import 'dart:convert';
import 'dart:io';

import '../../../domain/models/level.dart';
import '../../../domain/services/level_validator.dart';
import '../cli_runner.dart';

/// CLI command for validating level solvability.
///
/// Accepts level data via JSON string or file path and outputs
/// validation results including solution path if solvable.
class ValidateCommand extends JsonCommand {
  @override
  final String name = 'validate';

  @override
  final String description = 'Validate a level for solvability';

  ValidateCommand() {
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
    final result = const LevelValidator().validate(level);

    return {
      'valid': true,
      'solvable': result.isSolvable,
      if (result.solutionPath != null)
        'solution': result.solutionPath!
            .map((c) => {'q': c.q, 'r': c.r})
            .toList(),
      if (result.error != null) 'error': result.error,
    };
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
}
