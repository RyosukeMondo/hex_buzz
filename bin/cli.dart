import 'dart:io';

import 'package:hex_buzz/debug/cli/cli_runner.dart';

/// Entry point for the HexBuzz CLI.
///
/// Provides debug and validation tools for AI agent interaction.
/// All output is JSON formatted for easy parsing.
Future<void> main(List<String> arguments) async {
  final runner = CliRunner();

  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
