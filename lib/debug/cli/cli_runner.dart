import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/evaluate_command.dart';
import 'commands/generate_command.dart';
import 'commands/progress_command.dart';
import 'commands/validate_command.dart';

/// Base class for CLI commands that output JSON responses.
///
/// Provides structured JSON output for AI agent parsing.
abstract class JsonCommand extends Command<int> {
  /// Execute the command and return a result map to be JSON-encoded.
  Future<Map<String, dynamic>> execute();

  @override
  Future<int> run() async {
    try {
      final result = await execute();
      _outputJson({'success': true, ...result});
      return 0;
    } on FormatException catch (e) {
      _outputJson({
        'success': false,
        'error': {'type': 'format_error', 'message': e.message},
      });
      return 1;
    } on ArgumentError catch (e) {
      _outputJson({
        'success': false,
        'error': {'type': 'argument_error', 'message': e.message},
      });
      return 1;
    } catch (e) {
      _outputJson({
        'success': false,
        'error': {'type': 'unknown_error', 'message': e.toString()},
      });
      return 1;
    }
  }

  void _outputJson(Map<String, dynamic> data) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(data));
  }
}

/// CLI runner for Honeycomb One Pass debug commands.
///
/// Provides a command-based interface with JSON output for AI agent interaction.
class CliRunner extends CommandRunner<int> {
  CliRunner()
    : super(
        'honeycomb-cli',
        'Honeycomb One Pass CLI - Debug and validation tools',
      ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Show version information',
    );

    addCommand(ValidateCommand());
    addCommand(GenerateCommand());
    addCommand(EvaluateCommand());
    addCommand(ProgressCommand());
  }

  /// Runs the CLI with the given arguments.
  ///
  /// Returns exit code: 0 for success, non-zero for errors.
  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final results = parse(args);

      if (results.flag('version')) {
        _printVersion();
        return 0;
      }

      final result = await runCommand(results);
      return result ?? 0;
    } on UsageException catch (e) {
      _outputErrorJson('usage_error', e.message);
      stderr.writeln('\n$usage');
      return 64;
    } on FormatException catch (e) {
      _outputErrorJson('format_error', e.message);
      return 1;
    }
  }

  void _printVersion() {
    stdout.writeln(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'name': 'honeycomb-cli', 'version': '1.0.0'}),
    );
  }

  void _outputErrorJson(String type, String message) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'success': false,
        'error': {'type': type, 'message': message},
      }),
    );
  }

  @override
  String get usageFooter => '''

Examples:
  honeycomb-cli validate --file level.json
  honeycomb-cli validate --level '{"size":3,"cells":[...]}'
  honeycomb-cli generate --size 3
  honeycomb-cli generate --size 4 --output level.json
  honeycomb-cli evaluate --file level.json
  honeycomb-cli progress get
  honeycomb-cli progress set --level 1 --stars 3
  honeycomb-cli progress reset

Output is JSON formatted for AI agent parsing.''';
}
