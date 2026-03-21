import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/platform/file_logger.dart';

void main() {
  late Directory tempDir;
  late FileLogger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_logger_test_');
  });

  tearDown(() {
    logger.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Map<String, dynamic> makeEntry({
    String level = 'info',
    String event = 'test_event',
    Map<String, dynamic>? data,
  }) {
    return {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'event': event,
      'sessionId': 'test-session',
      if (data != null) 'data': data,
    };
  }

  group('FileLogger', () {
    test('writes log entry to file', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      final entry = makeEntry(event: 'hello_world');
      logger.write(entry);

      // Give sink time to flush
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final files = await logger.getLogFiles();
      expect(files, isNotEmpty);

      final content = await logger.getLogContent(files.first);
      expect(content, contains('hello_world'));

      final parsed = jsonDecode(content.trim().split('\n').last);
      expect(parsed['event'], 'hello_world');
      expect(parsed['level'], 'info');
    });

    test('rotates when size is exceeded', () async {
      logger = FileLogger(
        logDirectory: tempDir.path,
        maxFileSizeBytes: 200,
        maxFileCount: 10,
      );
      await logger.initialize();

      for (var i = 0; i < 10; i++) {
        logger.write(makeEntry(event: 'event_$i'));
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final files = await logger.getLogFiles();
      expect(files.length, greaterThan(1));
    });

    test('retains only maxFileCount files', () async {
      logger = FileLogger(
        logDirectory: tempDir.path,
        maxFileSizeBytes: 100,
        maxFileCount: 3,
      );
      await logger.initialize();

      for (var i = 0; i < 30; i++) {
        logger.write(makeEntry(event: 'flood_event_$i'));
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final files = await logger.getLogFiles();
      expect(files.length, lessThanOrEqualTo(3));
    });

    test('reads logs with level filter', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(level: 'info', event: 'info_event'));
      logger.write(makeEntry(level: 'error', event: 'error_event'));
      logger.write(makeEntry(level: 'debug', event: 'debug_event'));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final errors = await logger.readLogs(level: 'error');
      expect(errors.length, 1);
      expect(errors.first['event'], 'error_event');
    });

    test('reads logs with event filter', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(event: 'user_login'));
      logger.write(makeEntry(event: 'user_logout'));
      logger.write(makeEntry(event: 'game_start'));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final userLogs = await logger.readLogs(event: 'user');
      expect(userLogs.length, 2);
    });

    test('reads logs with limit', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      for (var i = 0; i < 20; i++) {
        logger.write(makeEntry(event: 'event_$i'));
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final limited = await logger.readLogs(limit: 5);
      expect(limited.length, 5);
    });

    test('handles missing directory gracefully', () async {
      final nonExistent = '${tempDir.path}/deeply/nested/path';
      logger = FileLogger(logDirectory: nonExistent);
      await logger.initialize();

      expect(logger.isInitialized, isTrue);
      expect(Directory(nonExistent).existsSync(), isTrue);
    });

    test('getLogFiles returns empty list when no files exist', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.dispose();
      for (final f in tempDir.listSync().whereType<File>()) {
        f.deleteSync();
      }

      // Re-create for tearDown
      logger = FileLogger(logDirectory: tempDir.path);
      final files = await logger.getLogFiles();
      expect(files, isEmpty);
    });

    test('getLogFilesWithMeta returns size and modified date', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(event: 'meta_test'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final meta = await logger.getLogFilesWithMeta();
      expect(meta, isNotEmpty);
      expect(meta.first['filename'], isA<String>());
      expect(meta.first['sizeBytes'], isA<int>());
      expect(meta.first['modified'], isA<String>());
    });

    test('clearAll removes all log files', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(event: 'before_clear'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await logger.clearAll();

      final files = await logger.getLogFiles();
      expect(files.length, 1);

      final content = await logger.getLogContent(files.first);
      expect(content.trim(), isEmpty);
    });

    test('getStats returns aggregate statistics', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(level: 'info', event: 'login'));
      logger.write(makeEntry(level: 'info', event: 'login'));
      logger.write(makeEntry(level: 'error', event: 'crash'));
      logger.write(makeEntry(level: 'warn', event: 'slow_query'));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final stats = await logger.getStats();
      expect(stats['totalEntries'], 4);
      expect(stats['countByLevel']['info'], 2);
      expect(stats['countByLevel']['error'], 1);
      expect(stats['countByLevel']['warn'], 1);
      expect((stats['topEvents'] as Map)['login'], 2);
    });

    test('logStream broadcasts entries for SSE consumers', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      final received = <Map<String, dynamic>>[];
      final sub = logger.logStream.listen(received.add);

      final entry = makeEntry(event: 'stream_test');
      logger.write(entry);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received, hasLength(1));
      expect(received.first['event'], 'stream_test');

      await sub.cancel();
    });

    test('filename follows hexbuzz_YYYY-MM-DD.jsonl format', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final files = await logger.getLogFiles();
      expect(
        files.first,
        matches(RegExp(r'^hexbuzz_\d{4}-\d{2}-\d{2}\.jsonl$')),
      );
    });

    test('falls back to print when not initialized', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      // Do NOT call initialize()

      // Should not throw
      logger.write(makeEntry(event: 'fallback_test'));
    });

    test('dispose prevents further writes to file', () async {
      logger = FileLogger(logDirectory: tempDir.path);
      await logger.initialize();

      logger.write(makeEntry(event: 'before_dispose'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      logger.dispose();

      // Re-create for tearDown
      logger = FileLogger(logDirectory: tempDir.path);
    });
  });
}
