import 'dart:convert';
import 'dart:io';

import '../../../domain/services/level_generator.dart';
import '../cli_runner.dart';

/// CLI command for generating new levels.
///
/// Generates a hexagonal level with the specified edge size
/// and outputs the level JSON with solution path.
class GenerateCommand extends JsonCommand {
  @override
  final String name = 'generate';

  @override
  final String description = 'Generate a new solvable level';

  GenerateCommand() {
    argParser.addOption(
      'size',
      abbr: 's',
      help: 'Edge size of the hexagonal grid (minimum 2)',
      defaultsTo: '3',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path (optional, outputs to stdout if not specified)',
    );
    argParser.addFlag(
      'pretty',
      abbr: 'p',
      help: 'Pretty print the JSON output',
      defaultsTo: true,
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final sizeStr = argResults?['size'] as String;
    final outputPath = argResults?['output'] as String?;
    final pretty = argResults?['pretty'] as bool;

    final size = int.tryParse(sizeStr);
    if (size == null || size < 2) {
      throw ArgumentError('Size must be an integer >= 2');
    }

    final generator = LevelGenerator();
    final result = generator.generate(size);

    if (!result.success) {
      return {'generated': false, 'error': result.error};
    }

    // Optionally write to file
    if (outputPath != null) {
      final levelJson = result.level!.toJson();
      final encoder = pretty
          ? const JsonEncoder.withIndent('  ')
          : const JsonEncoder();
      await File(outputPath).writeAsString(encoder.convert(levelJson));
    }

    return {
      'generated': true,
      'level': result.level!.toJson(),
      'solutionPath': result.solutionPath!
          .map((c) => {'q': c.q, 'r': c.r})
          .toList(),
      'stats': result.stats!.toJson(),
    };
  }
}
