import 'dart:convert';
import 'dart:io';

/// Log levels for structured logging.
enum LogLevel {
  debug,
  info,
  warn,
  error;

  bool operator >=(LogLevel other) => index >= other.index;
}

/// A structured JSON logger for AI agent analysis.
///
/// Outputs logs in JSON format with timestamp, level, component, event, and context.
class Logger {
  /// Creates a logger for a specific component.
  Logger(this.component, {LogLevel? minLevel, StringSink? output})
    : _minLevel = minLevel ?? LogLevel.debug,
      _output = output;

  /// The component name for this logger.
  final String component;

  /// Minimum log level to output.
  final LogLevel _minLevel;

  /// Custom output sink (defaults to stdout).
  final StringSink? _output;

  /// Logs a debug message.
  void debug(String event, [Map<String, dynamic>? context]) {
    _log(LogLevel.debug, event, context);
  }

  /// Logs an info message.
  void info(String event, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, event, context);
  }

  /// Logs a warning message.
  void warn(String event, [Map<String, dynamic>? context]) {
    _log(LogLevel.warn, event, context);
  }

  /// Logs an error message.
  void error(String event, [Map<String, dynamic>? context]) {
    _log(LogLevel.error, event, context);
  }

  void _log(LogLevel level, String event, Map<String, dynamic>? context) {
    if (level >= _minLevel) {
      final entry = LogEntry(
        timestamp: DateTime.now().toUtc(),
        level: level,
        component: component,
        event: event,
        context: context,
      );
      final output = _output ?? stdout;
      output.writeln(entry.toJson());
    }
  }
}

/// A single log entry with all structured fields.
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.event,
    this.context,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String component;
  final String event;
  final Map<String, dynamic>? context;

  /// Converts the entry to a JSON string.
  String toJson() {
    final map = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'component': component,
      'event': event,
    };
    if (context != null && context!.isNotEmpty) {
      map['context'] = context;
    }
    return jsonEncode(map);
  }
}

/// Global logger factory for creating component loggers.
class LoggerFactory {
  LoggerFactory._();

  static LogLevel _globalMinLevel = LogLevel.debug;
  static StringSink? _globalOutput;

  /// Sets the global minimum log level.
  static void setMinLevel(LogLevel level) {
    _globalMinLevel = level;
  }

  /// Sets the global output sink.
  static void setOutput(StringSink output) {
    _globalOutput = output;
  }

  /// Resets to default configuration.
  static void reset() {
    _globalMinLevel = LogLevel.debug;
    _globalOutput = null;
  }

  /// Creates a logger for the given component.
  static Logger create(String component) {
    return Logger(component, minLevel: _globalMinLevel, output: _globalOutput);
  }
}

/// Global application logger.
final Logger appLogger = LoggerFactory.create('app');
