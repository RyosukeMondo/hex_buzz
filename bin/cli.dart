import 'dart:io';

import 'package:honeycomb_one_pass/debug/cli/cli_runner.dart';

/// Entry point for the Honeycomb One Pass CLI.
///
/// Provides debug and validation tools for AI agent interaction.
/// All output is JSON formatted for easy parsing.
Future<void> main(List<String> arguments) async {
  final runner = CliRunner();

  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
