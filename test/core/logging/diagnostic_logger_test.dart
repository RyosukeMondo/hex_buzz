import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/logging/diagnostic_logger.dart';
import 'package:hex_buzz/core/logging/logger.dart';

void main() {
  group('DiagnosticLogger', () {
    setUp(() {
      // Clear buffer before each test
      DiagnosticLogger.clearBuffer();
    });

    tearDown(() {
      // Reset test sink after each test
      DiagnosticLogger.configure(sink: null);
      DiagnosticLogger.clearBuffer();
    });

    test('logEvent captures event with data', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent(
        'test_event',
        data: {'key': 'value', 'count': 42},
        level: LogLevel.info,
      );

      expect(logs, hasLength(1));
      expect(logs[0]['event'], 'test_event');
      expect(logs[0]['level'], 'info');
      expect(logs[0]['data'], {'key': 'value', 'count': 42});
      expect(logs[0]['timestamp'], isA<String>());
    });

    test('logEvent captures event without data', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent('simple_event', level: LogLevel.debug);

      expect(logs, hasLength(1));
      expect(logs[0]['event'], 'simple_event');
      expect(logs[0]['level'], 'debug');
      expect(logs[0]['data'], isNull);
    });

    test('logEvent defaults to info level', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent('default_level_event');

      expect(logs, hasLength(1));
      expect(logs[0]['level'], 'info');
    });

    test('logError captures error with stack trace', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      DiagnosticLogger.logError(
        'error_event',
        error: error,
        stackTrace: stackTrace,
        data: {'context': 'test'},
      );

      expect(logs, hasLength(1));
      expect(logs[0]['event'], 'error_event');
      expect(logs[0]['level'], 'error');
      expect(logs[0]['data']['error'], contains('Test error'));
      expect(logs[0]['data']['stackTrace'], isA<String>());
      expect(logs[0]['data']['context'], 'test');
    });

    test('logError captures error without stack trace', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      final error = Exception('Test error');

      DiagnosticLogger.logError(
        'error_event',
        error: error,
        data: {'userId': '123'},
      );

      expect(logs, hasLength(1));
      expect(logs[0]['event'], 'error_event');
      expect(logs[0]['level'], 'error');
      expect(logs[0]['data']['error'], contains('Test error'));
      expect(logs[0]['data']['userId'], '123');
    });

    test('buffered logs can be retrieved', () {
      DiagnosticLogger.logEvent('event1', level: LogLevel.info);
      DiagnosticLogger.logEvent('event2', level: LogLevel.debug);
      DiagnosticLogger.logEvent('event3', level: LogLevel.warn);

      final buffered = DiagnosticLogger.getBufferedLogs();

      expect(buffered, hasLength(3));
      expect(buffered[0]['event'], 'event1');
      expect(buffered[1]['event'], 'event2');
      expect(buffered[2]['event'], 'event3');
    });

    test('buffer can be cleared', () {
      DiagnosticLogger.logEvent('event1', level: LogLevel.info);
      DiagnosticLogger.logEvent('event2', level: LogLevel.info);

      expect(DiagnosticLogger.getBufferedLogs(), hasLength(2));

      DiagnosticLogger.clearBuffer();

      expect(DiagnosticLogger.getBufferedLogs(), isEmpty);
    });

    test('buffer limits to 100 entries', () {
      // Add more than 100 events
      for (int i = 0; i < 150; i++) {
        DiagnosticLogger.logEvent('event_$i', level: LogLevel.info);
      }

      final buffered = DiagnosticLogger.getBufferedLogs();

      // Should only keep the last 100
      expect(buffered, hasLength(100));
      // First event should be event_50 (0-49 were removed)
      expect(buffered[0]['event'], 'event_50');
      // Last event should be event_149
      expect(buffered[99]['event'], 'event_149');
    });

    test('all log levels are supported', () {
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent('debug_event', level: LogLevel.debug);
      DiagnosticLogger.logEvent('info_event', level: LogLevel.info);
      DiagnosticLogger.logEvent('warn_event', level: LogLevel.warn);
      DiagnosticLogger.logEvent('error_event', level: LogLevel.error);

      expect(logs, hasLength(4));
      expect(logs[0]['level'], 'debug');
      expect(logs[1]['level'], 'info');
      expect(logs[2]['level'], 'warn');
      expect(logs[3]['level'], 'error');
    });

    test('session ID is included in logs', () {
      DiagnosticLogger.init();
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent('test_event', level: LogLevel.info);

      expect(logs, hasLength(1));
      expect(logs[0]['sessionId'], isNotNull);
      expect(logs[0]['sessionId'], isA<String>());
    });

    test('multiple events share same session ID', () {
      DiagnosticLogger.init();
      final logs = <Map<String, dynamic>>[];
      DiagnosticLogger.configure(sink: logs.add);

      DiagnosticLogger.logEvent('event1', level: LogLevel.info);
      DiagnosticLogger.logEvent('event2', level: LogLevel.info);

      expect(logs, hasLength(2));
      expect(logs[0]['sessionId'], equals(logs[1]['sessionId']));
    });
  });
}
