import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/core/logging/logger.dart';

void main() {
  group('LogLevel', () {
    test('levels are ordered correctly', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warn.index));
      expect(LogLevel.warn.index, lessThan(LogLevel.error.index));
    });

    test('comparison operator works correctly', () {
      expect(LogLevel.error >= LogLevel.debug, isTrue);
      expect(LogLevel.info >= LogLevel.info, isTrue);
      expect(LogLevel.debug >= LogLevel.warn, isFalse);
    });
  });

  group('LogEntry', () {
    test('toJson produces valid JSON', () {
      final timestamp = DateTime.utc(2025, 1, 15, 10, 30, 0);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        component: 'test-component',
        event: 'test-event',
      );

      final json = entry.toJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['timestamp'], '2025-01-15T10:30:00.000Z');
      expect(parsed['level'], 'info');
      expect(parsed['component'], 'test-component');
      expect(parsed['event'], 'test-event');
      expect(parsed.containsKey('context'), isFalse);
    });

    test('toJson includes context when provided', () {
      final timestamp = DateTime.utc(2025, 1, 15);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.error,
        component: 'game',
        event: 'move-failed',
        context: {
          'reason': 'wall-blocked',
          'cell': {'q': 1, 'r': 2},
        },
      );

      final json = entry.toJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['context']['reason'], 'wall-blocked');
      expect(parsed['context']['cell']['q'], 1);
      expect(parsed['context']['cell']['r'], 2);
    });

    test('toJson omits empty context', () {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        component: 'test',
        event: 'event',
        context: {},
      );

      final json = entry.toJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed.containsKey('context'), isFalse);
    });
  });

  group('Logger', () {
    test('logs messages at or above minimum level', () {
      final output = StringBuffer();
      final logger = Logger('test', minLevel: LogLevel.info, output: output);

      logger.debug('debug-message');
      logger.info('info-message');
      logger.warn('warn-message');
      logger.error('error-message');

      final lines = output.toString().trim().split('\n');
      expect(lines.length, 3);

      final parsed = lines
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
      expect(parsed[0]['level'], 'info');
      expect(parsed[1]['level'], 'warn');
      expect(parsed[2]['level'], 'error');
    });

    test('includes component name in all logs', () {
      final output = StringBuffer();
      final logger = Logger('my-component', output: output);

      logger.info('test-event');

      final parsed =
          jsonDecode(output.toString().trim()) as Map<String, dynamic>;
      expect(parsed['component'], 'my-component');
    });

    test('includes context when provided', () {
      final output = StringBuffer();
      final logger = Logger('test', output: output);

      logger.info('move', {'q': 1, 'r': 2, 'valid': true});

      final parsed =
          jsonDecode(output.toString().trim()) as Map<String, dynamic>;
      expect(parsed['context']['q'], 1);
      expect(parsed['context']['r'], 2);
      expect(parsed['context']['valid'], true);
    });

    test('debug method logs at debug level', () {
      final output = StringBuffer();
      final logger = Logger('test', output: output);

      logger.debug('debug-event');

      final parsed =
          jsonDecode(output.toString().trim()) as Map<String, dynamic>;
      expect(parsed['level'], 'debug');
      expect(parsed['event'], 'debug-event');
    });

    test('warn method logs at warn level', () {
      final output = StringBuffer();
      final logger = Logger('test', output: output);

      logger.warn('warn-event');

      final parsed =
          jsonDecode(output.toString().trim()) as Map<String, dynamic>;
      expect(parsed['level'], 'warn');
    });

    test('error method logs at error level', () {
      final output = StringBuffer();
      final logger = Logger('test', output: output);

      logger.error('error-event', {'code': 500});

      final parsed =
          jsonDecode(output.toString().trim()) as Map<String, dynamic>;
      expect(parsed['level'], 'error');
      expect(parsed['context']['code'], 500);
    });
  });

  group('LoggerFactory', () {
    tearDown(() {
      LoggerFactory.reset();
    });

    test('creates logger with global settings', () {
      final output = StringBuffer();
      LoggerFactory.setMinLevel(LogLevel.warn);
      LoggerFactory.setOutput(output);

      final logger = LoggerFactory.create('factory-test');
      logger.debug('should-not-appear');
      logger.info('should-not-appear');
      logger.warn('should-appear');

      final lines = output.toString().trim().split('\n');
      expect(lines.length, 1);

      final parsed = jsonDecode(lines[0]) as Map<String, dynamic>;
      expect(parsed['level'], 'warn');
      expect(parsed['component'], 'factory-test');
    });

    test('reset restores defaults', () {
      LoggerFactory.setMinLevel(LogLevel.error);
      LoggerFactory.reset();

      final output = StringBuffer();
      final logger = Logger('test', output: output);
      logger.debug('debug-message');

      expect(output.toString(), isNotEmpty);
    });
  });

  group('appLogger', () {
    test('is a valid logger instance', () {
      expect(appLogger, isA<Logger>());
      expect(appLogger.component, 'app');
    });
  });
}
