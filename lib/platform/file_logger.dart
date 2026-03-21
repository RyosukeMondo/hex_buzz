import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hex_buzz/core/logging/logger.dart';

/// A rolling file logger that writes JSON-line logs to disk.
///
/// Features:
/// - Writes one JSON object per line (JSONL format)
/// - Rotates files when they exceed [maxFileSizeBytes]
/// - Retains only [maxFileCount] log files
/// - Thread-safe writes via [IOSink] with periodic flush
/// - Falls back to print() if file writing fails
class FileLogger {
  /// Creates a file logger that writes to [logDirectory].
  FileLogger({
    required this.logDirectory,
    this.maxFileSizeBytes = 1024 * 1024,
    this.maxFileCount = 5,
  });

  /// Directory where log files are stored.
  final String logDirectory;

  /// Maximum size of a single log file before rotation (default 1MB).
  final int maxFileSizeBytes;

  /// Maximum number of log files to retain (default 5).
  final int maxFileCount;

  IOSink? _currentSink;
  File? _currentFile;
  int _currentFileSize = 0;
  bool _initialized = false;
  final _logger = LoggerFactory.create('file-logger');

  /// Stream controller that broadcasts log entries for SSE consumers.
  final StreamController<Map<String, dynamic>> _logStream =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of log entries for real-time consumers (e.g., SSE).
  Stream<Map<String, dynamic>> get logStream => _logStream.stream;

  /// Whether the logger has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes the logger by creating the log directory and opening a file.
  Future<void> initialize() async {
    try {
      final dir = Directory(logDirectory);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      await _openCurrentLogFile();
      _initialized = true;
      _logger.info('file_logger_initialized', {
        'directory': logDirectory,
        'maxFileSizeBytes': maxFileSizeBytes,
        'maxFileCount': maxFileCount,
      });
    } catch (e) {
      _logger.error('file_logger_init_failed', {'error': e.toString()});
    }
  }

  /// Writes a log entry to the current log file.
  ///
  /// If the file exceeds [maxFileSizeBytes], triggers rotation.
  /// Falls back to print() if writing fails.
  void write(Map<String, dynamic> logEntry) {
    // Broadcast to SSE stream regardless of file state
    if (!_logStream.isClosed) {
      _logStream.add(logEntry);
    }

    if (!_initialized || _currentSink == null) {
      _fallbackPrint(logEntry);
      return;
    }

    try {
      final line = jsonEncode(logEntry);
      final lineBytes = utf8.encode('$line\n').length;

      if (_currentFileSize + lineBytes > maxFileSizeBytes) {
        _rotateSync();
      }

      _currentSink!.writeln(line);
      _currentFileSize += lineBytes;
    } catch (e) {
      _fallbackPrint(logEntry);
    }
  }

  /// Reads log entries from current and rotated files.
  ///
  /// Returns at most [limit] entries, newest first.
  Future<List<Map<String, dynamic>>> readLogs({
    int limit = 100,
    String? level,
    String? event,
    DateTime? since,
  }) async {
    final results = <Map<String, dynamic>>[];
    final files = await getLogFiles();

    for (final filename in files) {
      if (results.length >= limit) break;

      try {
        final content = await getLogContent(filename);
        final lines = content.split('\n').where((l) => l.trim().isNotEmpty);

        for (final line in lines.toList().reversed) {
          if (results.length >= limit) break;

          try {
            final entry = jsonDecode(line) as Map<String, dynamic>;
            if (_matchesFilter(entry, level: level, event: event, since: since)) {
              results.add(entry);
            }
          } catch (_) {
            // Skip malformed lines
          }
        }
      } catch (_) {
        // Skip unreadable files
      }
    }

    return results;
  }

  /// Returns sorted list of log filenames (newest first).
  Future<List<String>> getLogFiles() async {
    try {
      final dir = Directory(logDirectory);
      if (!dir.existsSync()) return [];

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList();

      files.sort((a, b) => b.path.compareTo(a.path));
      return files.map((f) => f.uri.pathSegments.last).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns metadata for all log files.
  Future<List<Map<String, dynamic>>> getLogFilesWithMeta() async {
    try {
      final dir = Directory(logDirectory);
      if (!dir.existsSync()) return [];

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList();

      files.sort((a, b) => b.path.compareTo(a.path));

      return files.map((f) {
        final stat = f.statSync();
        return <String, dynamic>{
          'filename': f.uri.pathSegments.last,
          'sizeBytes': stat.size,
          'modified': stat.modified.toUtc().toIso8601String(),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Rotates log files: closes current file, deletes excess files.
  Future<void> rotateLogs() async {
    await _closeSink();
    await _pruneOldFiles();
    await _openCurrentLogFile();
  }

  /// Returns the raw content of a specific log file.
  Future<String> getLogContent(String filename) async {
    _currentSink?.flush();

    final file = File('$logDirectory/$filename');
    if (!file.existsSync()) {
      throw FileSystemException('Log file not found', file.path);
    }
    return file.readAsString();
  }

  /// Returns aggregate statistics from log files.
  Future<Map<String, dynamic>> getStats() async {
    final countByLevel = <String, int>{};
    final countByEvent = <String, int>{};
    int total = 0;
    int errors = 0;
    DateTime? oldest;
    DateTime? newest;

    final files = await getLogFiles();
    for (final filename in files) {
      try {
        final content = await getLogContent(filename);
        for (final line in content.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final entry = jsonDecode(line) as Map<String, dynamic>;
            total++;

            final level = entry['level'] as String? ?? 'unknown';
            countByLevel[level] = (countByLevel[level] ?? 0) + 1;
            if (level == 'error') errors++;

            final eventName = entry['event'] as String? ?? 'unknown';
            countByEvent[eventName] = (countByEvent[eventName] ?? 0) + 1;

            final ts = DateTime.tryParse(entry['timestamp'] as String? ?? '');
            if (ts != null) {
              if (oldest == null || ts.isBefore(oldest)) oldest = ts;
              if (newest == null || ts.isAfter(newest)) newest = ts;
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    final topEvents = countByEvent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double errorsPerMinute = 0;
    if (oldest != null && newest != null) {
      final minutes = newest.difference(oldest).inMinutes;
      if (minutes > 0) {
        errorsPerMinute = errors / minutes;
      }
    }

    return {
      'totalEntries': total,
      'countByLevel': countByLevel,
      'topEvents': Map.fromEntries(topEvents.take(10)),
      'errorsPerMinute': errorsPerMinute,
      'oldestEntry': oldest?.toIso8601String(),
      'newestEntry': newest?.toIso8601String(),
      'fileCount': files.length,
    };
  }

  /// Clears all log files.
  Future<void> clearAll() async {
    await _closeSink();

    final dir = Directory(logDirectory);
    if (dir.existsSync()) {
      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.jsonl')) {
          await file.delete();
        }
      }
    }

    await _openCurrentLogFile();
  }

  /// Releases resources (closes file sink and stream controller).
  void dispose() {
    _closeSinkSync();
    _logStream.close();
    _initialized = false;
  }

  // -- Private helpers --

  String _todayFilename() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'hexbuzz_$y-$m-$d.jsonl';
  }

  Future<void> _openCurrentLogFile() async {
    final filename = _todayFilename();
    final file = File('$logDirectory/$filename');

    _currentFileSize = file.existsSync() ? file.lengthSync() : 0;
    _currentFile = file;
    _currentSink = file.openWrite(mode: FileMode.append);
  }

  void _rotateSync() {
    _closeSinkSync();

    final filename = _todayFilename();
    final file = File('$logDirectory/$filename');

    // Rename current file with a sequence suffix so a fresh file is opened.
    // We rely on the in-memory _currentFileSize rather than disk length
    // because the IOSink may not have flushed all data yet.
    if (file.existsSync()) {
      final baseName = filename.replaceAll('.jsonl', '');
      var seq = 1;
      var newName = '${baseName}_$seq.jsonl';
      while (File('$logDirectory/$newName').existsSync()) {
        seq++;
        newName = '${baseName}_$seq.jsonl';
      }
      file.renameSync('$logDirectory/$newName');
    }

    _pruneOldFilesSync();

    _currentFile = File('$logDirectory/$filename');
    _currentSink = _currentFile!.openWrite(mode: FileMode.append);
    _currentFileSize = 0;
  }

  Future<void> _closeSink() async {
    try {
      await _currentSink?.flush();
      await _currentSink?.close();
    } catch (_) {}
    _currentSink = null;
  }

  void _closeSinkSync() {
    try {
      _currentSink?.close();
    } catch (_) {}
    _currentSink = null;
  }

  Future<void> _pruneOldFiles() async {
    _pruneOldFilesSync();
  }

  void _pruneOldFilesSync() {
    try {
      final dir = Directory(logDirectory);
      if (!dir.existsSync()) return;

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList();

      files.sort((a, b) => b.path.compareTo(a.path));

      if (files.length >= maxFileCount) {
        for (var i = maxFileCount - 1; i < files.length; i++) {
          files[i].deleteSync();
        }
      }
    } catch (_) {}
  }

  bool _matchesFilter(
    Map<String, dynamic> entry, {
    String? level,
    String? event,
    DateTime? since,
  }) {
    if (level != null && entry['level'] != level) return false;
    if (event != null) {
      final entryEvent = entry['event'] as String? ?? '';
      if (!entryEvent.toLowerCase().contains(event.toLowerCase())) {
        return false;
      }
    }
    if (since != null) {
      final ts = DateTime.tryParse(entry['timestamp'] as String? ?? '');
      if (ts == null || ts.isBefore(since)) return false;
    }
    return true;
  }

  void _fallbackPrint(Map<String, dynamic> logEntry) {
    try {
      // ignore: avoid_print
      print(jsonEncode(logEntry));
    } catch (_) {}
  }
}
