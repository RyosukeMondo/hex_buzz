import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hex_buzz/core/logging/logger.dart';

/// Autonomous diagnostic logger that sends logs to Firestore for remote debugging
class DiagnosticLogger {
  static final DiagnosticLogger _instance = DiagnosticLogger._internal();
  factory DiagnosticLogger() => _instance;
  DiagnosticLogger._internal();

  FirebaseFirestore? _firestore;
  final List<Map<String, dynamic>> _buffer = [];
  bool _enabled = true;
  String? _sessionId;
  static void Function(Map<String, dynamic>)? _testSink;

  /// Initialize with a unique session ID
  static void init() {
    _instance._sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      _instance._firestore = FirebaseFirestore.instance;
    } catch (e) {
      // Firebase not initialized, disable logging
      _instance._enabled = false;
    }
  }

  /// Configure test sink for testing
  static void configure({void Function(Map<String, dynamic>)? sink}) {
    _testSink = sink;
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

    // Send to Firestore asynchronously if enabled
    if (_instance._enabled && _instance._firestore != null) {
      // Ignore errors - don't let logging break the app
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

    // Also log to structured logger
    final logger = LoggerFactory.create('diagnostic');
    switch (level) {
      case LogLevel.debug:
        logger.debug(event, data);
        break;
      case LogLevel.info:
        logger.info(event, data);
        break;
      case LogLevel.warn:
        logger.warn(event, data);
        break;
      case LogLevel.error:
        logger.error(event, data);
        break;
    }
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

  /// Clear buffered logs
  static void clearBuffer() {
    _instance._buffer.clear();
  }
}
