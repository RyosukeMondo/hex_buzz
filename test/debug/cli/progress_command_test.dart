import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressCommand', () {
    late Directory tempDir;
    late String progressFilePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('progress_test_');
      progressFilePath = '${tempDir.path}/progress.json';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// Runs the CLI and returns the exit code and parsed JSON output.
    Future<(int exitCode, Map<String, dynamic> output)> runCli(
      List<String> args,
    ) async {
      final result = await Process.run('dart', [
        'run',
        'honeycomb_one_pass:cli',
        ...args,
      ], workingDirectory: Directory.current.path);
      final output =
          jsonDecode(result.stdout as String) as Map<String, dynamic>;
      return (result.exitCode, output);
    }

    group('get subcommand', () {
      test('returns empty state when no progress file exists', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['totalStars'], equals(0));
        expect(output['completedLevels'], equals(0));
        expect(output['highestUnlockedLevel'], equals(0));
        expect(output['levels'], isEmpty);
      });

      test('returns progress state when file exists', () async {
        // Create a progress file
        final progressData = {
          'levels': {
            '0': {'completed': true, 'stars': 3, 'bestTimeMs': 5000},
            '1': {'completed': true, 'stars': 2, 'bestTimeMs': 25000},
          },
        };
        await File(progressFilePath).writeAsString(jsonEncode(progressData));

        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['totalStars'], equals(5));
        expect(output['completedLevels'], equals(2));
        expect(output['highestUnlockedLevel'], equals(2));
        expect(output['levels'], hasLength(2));
      });

      test('returns specific level progress with --level option', () async {
        final progressData = {
          'levels': {
            '0': {'completed': true, 'stars': 3, 'bestTimeMs': 5000},
            '1': {'completed': false, 'stars': 0},
          },
        };
        await File(progressFilePath).writeAsString(jsonEncode(progressData));

        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
          '-l',
          '0',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['levelIndex'], equals(0));
        expect(output['isUnlocked'], isTrue);

        final progress = output['progress'] as Map<String, dynamic>;
        expect(progress['completed'], isTrue);
        expect(progress['stars'], equals(3));
        expect(progress['bestTimeMs'], equals(5000));
      });

      test('returns empty progress for non-existent level', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
          '-l',
          '5',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['levelIndex'], equals(5));
        expect(output['isUnlocked'], isFalse);

        final progress = output['progress'] as Map<String, dynamic>;
        expect(progress['completed'], isFalse);
        expect(progress['stars'], equals(0));
      });

      test('returns error for invalid level index', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
          '-l',
          'abc',
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });
    });

    group('set subcommand', () {
      test('sets progress for a new level', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '3',
          '-t',
          '8000',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['levelIndex'], equals(0));
        expect(output['message'], contains('level 0'));

        final progress = output['progress'] as Map<String, dynamic>;
        expect(progress['completed'], isTrue);
        expect(progress['stars'], equals(3));
        expect(progress['bestTimeMs'], equals(8000));

        // Verify file was created
        expect(await File(progressFilePath).exists(), isTrue);
      });

      test('sets progress without time', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '2',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);

        final progress = output['progress'] as Map<String, dynamic>;
        expect(progress['completed'], isTrue);
        expect(progress['stars'], equals(2));
        expect(progress.containsKey('bestTimeMs'), isFalse);
      });

      test('sets progress with completed=false', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '0',
          '--no-completed',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);

        final progress = output['progress'] as Map<String, dynamic>;
        expect(progress['completed'], isFalse);
        expect(progress['stars'], equals(0));
      });

      test('returns error for invalid level index', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '-1',
          '-s',
          '1',
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });

      test('returns error for invalid stars value (too high)', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '5',
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });

      test('returns error for negative stars value', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '-1',
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });

      test('returns error for invalid time value', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '2',
          '-t',
          'abc',
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });
    });

    group('reset subcommand', () {
      test('resets all progress when confirmed', () async {
        // Create initial progress
        final progressData = {
          'levels': {
            '0': {'completed': true, 'stars': 3, 'bestTimeMs': 5000},
          },
        };
        await File(progressFilePath).writeAsString(jsonEncode(progressData));

        final (exitCode, output) = await runCli([
          'progress',
          'reset',
          '-f',
          progressFilePath,
          '--confirm',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['message'], contains('reset'));

        // Verify file was deleted
        expect(await File(progressFilePath).exists(), isFalse);
      });

      test('returns error when not confirmed', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'reset',
          '-f',
          progressFilePath,
        ]);

        expect(exitCode, equals(1));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('argument_error'));
      });

      test('succeeds even when no progress file exists', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'reset',
          '-f',
          progressFilePath,
          '--confirm',
        ]);

        expect(exitCode, equals(0));
        expect(output['success'], isTrue);
        expect(output['message'], contains('reset'));
      });
    });

    group('main command', () {
      test('returns error when no subcommand provided', () async {
        final (exitCode, output) = await runCli(['progress']);

        // Exit code 64 is for usage errors (missing subcommand)
        expect(exitCode, equals(64));
        expect(output['success'], isFalse);
        expect(output['error']['type'], equals('usage_error'));
      });
    });

    group('JSON output format', () {
      test('get returns valid JSON-serializable output', () async {
        final progressData = {
          'levels': {
            '0': {'completed': true, 'stars': 3, 'bestTimeMs': 5000},
          },
        };
        await File(progressFilePath).writeAsString(jsonEncode(progressData));

        final (exitCode, output) = await runCli([
          'progress',
          'get',
          '-f',
          progressFilePath,
        ]);

        expect(exitCode, equals(0));
        // Should be serializable to JSON without errors
        final jsonString = jsonEncode(output);
        expect(jsonString, isNotEmpty);

        // Should be parseable back to the same structure
        final parsed = jsonDecode(jsonString);
        expect(parsed['totalStars'], equals(3));
      });

      test('set returns valid JSON-serializable output', () async {
        final (exitCode, output) = await runCli([
          'progress',
          'set',
          '-f',
          progressFilePath,
          '-l',
          '0',
          '-s',
          '2',
        ]);

        expect(exitCode, equals(0));
        final jsonString = jsonEncode(output);
        expect(jsonString, isNotEmpty);

        final parsed = jsonDecode(jsonString);
        expect(parsed['levelIndex'], equals(0));
      });
    });
  });
}
