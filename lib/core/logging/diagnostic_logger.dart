import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hex_buzz/platform/file_logger.dart'
    if (dart.library.js_interop) 'package:hex_buzz/core/logging/file_logger_stub.dart';
import 'package:hex_buzz/core/logging/logger.dart';

/// Autonomous diagnostic logger that sends logs to Firestore and disk.
///
/// Writes to three destinations:
/// 1. In-memory buffer (100 entries, for quick inspection)
/// 2. File-based rolling log via [FileLogger]
/// 3. Firestore (when available, for remote debugging)
class DiagnosticLogger {
  static final DiagnosticLogger _instance = DiagnosticLogger._internal();
  factory DiagnosticLogger() => _instance;
  DiagnosticLogger._internal();

  FirebaseFirestore? _firestore;
  final List<Map<String, dynamic>> _buffer = [];
  bool _enabled = true;
  String? _sessionId;
  static void Function(Map<String, dynamic>)? _testSink;
  FileLogger? _fileLogger;

  /// The file logger instance, if initialized. Exposed for route handlers.
  static FileLogger? get fileLogger => _instance._fileLogger;

  /// Initialize with a unique session ID and optional file logging.
  static Future<void> init({String? logDirectory}) async {
    _instance._sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      _instance._firestore = FirebaseFirestore.instance;
    } catch (e) {
      // Firebase not initialized, disable Firestore logging
      _instance._enabled = false;
    }

    // Initialize file logger
    await _instance._initFileLogger(logDirectory);
  }

  /// Synchronous init for backward compatibility (skips file logger setup).
  static void initSync() {
    _instance._sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      _instance._firestore = FirebaseFirestore.instance;
    } catch (e) {
      _instance._enabled = false;
    }
  }

  /// Configure test sink for testing
  static void configure({
    void Function(Map<String, dynamic>)? sink,
    FileLogger? fileLogger,
  }) {
    _testSink = sink;
    if (fileLogger != null) {
      _instance._fileLogger = fileLogger;
    }
  }

  /// Log an event with structured data
  static void logEvent(
    String event, {
    Map<String, dynamic>? data,
    LogLevel level = LogLevel.info,
  }) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'event': event,
      'sessionId': _instance._sessionId,
      if (data != null) 'data': data,
    };

    // Send to test sink if configured
    if (_testSink != null) {
      _testSink!(logEntry);
      return;
    }

    // Buffer for local viewing
    _instance._buffer.add(logEntry);
    if (_instance._buffer.length > 100) {
      _instance._buffer.removeAt(0);
    }

    // Write to file logger
    _instance._fileLogger?.write(logEntry);

    _sendToFirestore(event, data, level);
    _sendToStructuredLogger(event, data, level);
  }

  /// Log an error with stack trace
  static void logError(
    String event, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final errorData = <String, dynamic>{
      'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (data != null) ...data,
    };

    logEvent(event, data: errorData, level: LogLevel.error);
  }

  /// Get buffered logs for inspection
  static List<Map<String, dynamic>> getBufferedLogs() =>
      List.from(_instance._buffer);

  /// Clear buffered logs and optionally persisted logs.
  static Future<void> clearAll() async {
    _instance._buffer.clear();
    await _instance._fileLogger?.clearAll();
  }

  /// Clear buffered logs
  static void clearBuffer() {
    _instance._buffer.clear();
  }

  /// Returns persisted logs from disk with optional filters.
  static Future<List<Map<String, dynamic>>> getPersistedLogs({
    int limit = 100,
    String? level,
    String? event,
    DateTime? since,
  }) async {
    final fl = _instance._fileLogger;
    if (fl == null) return [];
    return fl.readLogs(limit: limit, level: level, event: event, since: since);
  }

  /// Returns list of log filenames on disk.
  static Future<List<String>> getLogFiles() async {
    final fl = _instance._fileLogger;
    if (fl == null) return [];
    return fl.getLogFiles();
  }

  /// Reads a specific log file by name.
  static Future<String> readLogFile(String name) async {
    final fl = _instance._fileLogger;
    if (fl == null) {
      throw StateError('File logger not initialized');
    }
    return fl.getLogContent(name);
  }

  /// Dispose file logger resources.
  static void dispose() {
    _instance._fileLogger?.dispose();
    _instance._fileLogger = null;
  }

  // -- Private helpers --

  Future<void> _initFileLogger(String? logDirectory) async {
    if (kIsWeb) return; // File logging not available on web
    try {
      final dir = logDirectory ?? '/tmp/hexbuzz_logs';
      _fileLogger = FileLogger(logDirectory: dir);
      await _fileLogger!.initialize();
    } catch (e) {
      // File logging unavailable, continue with in-memory only
      _fileLogger = null;
    }
  }

  static void _sendToFirestore(
    String event,
    Map<String, dynamic>? data,
    LogLevel level,
  ) {
    if (_instance._enabled && _instance._firestore != null) {
      // ignore: unawaited_futures
      _instance._firestore!
          .collection('diagnosticLogs')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'level': level.name,
            'event': event,
            'sessionId': _instance._sessionId,
            'clientTime': DateTime.now().toIso8601String(),
            if (data != null) 'data': data,
          })
          .then((_) {}, onError: (_) {});
    }
  }

  static void _sendToStructuredLogger(
    String event,
    Map<String, dynamic>? data,
    LogLevel level,
  ) {
    final logger = LoggerFactory.create('diagnostic');
    switch (level) {
      case LogLevel.debug:
        logger.debug(event, data);
      case LogLevel.info:
        logger.info(event, data);
      case LogLevel.warn:
        logger.warn(event, data);
      case LogLevel.error:
        logger.error(event, data);
    }
  }
}
