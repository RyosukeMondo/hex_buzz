import 'dart:io';

import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage information')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

  try {
    final results = parser.parse(arguments);

    if (results.flag('help')) {
      _printUsage(parser);
      return;
    }

    if (results.flag('version')) {
      print('honeycomb-cli version 1.0.0');
      return;
    }

    _printUsage(parser);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('Honeycomb One Pass CLI\n');
  print('Usage: dart run bin/cli.dart [options] <command>\n');
  print('Commands:');
  print('  validate    Validate a level for solvability');
  print('\nOptions:');
  print(parser.usage);
}
