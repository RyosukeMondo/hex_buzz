import 'package:cloud_firestore/cloud_firestore.dart';

/// Autonomous diagnostic logger that sends logs to Firestore for remote debugging
class DiagnosticLogger {
  static final DiagnosticLogger _instance = DiagnosticLogger._internal();
  factory DiagnosticLogger() => _instance;
  DiagnosticLogger._internal();

  FirebaseFirestore? _firestore;
  final List<Map<String, dynamic>> _buffer = [];
  bool _enabled = true;
  String? _sessionId;

  /// Initialize with a unique session ID
  void init() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      // Firebase not initialized, disable logging
      _enabled = false;
    }
  }

  /// Log a message with automatic Firestore persistence
  Future<void> log(String level, String message, {Map<String, dynamic>? data}) async {
    if (!_enabled || _firestore == null) {
      // Just print locally if Firestore not available
      print('[$level] $message ${data != null ? data.toString() : ''}');
      return;
    }

    final logEntry = {
      'timestamp': FieldValue.serverTimestamp(),
      'level': level,
      'message': message,
      'sessionId': _sessionId,
      'clientTime': DateTime.now().toIso8601String(),
      if (data != null) 'data': data,
    };

    // Buffer for local viewing
    _buffer.add(logEntry);
    if (_buffer.length > 100) _buffer.removeAt(0);

    // Send to Firestore asynchronously (don't wait)
    _firestore!.collection('diagnosticLogs').add(logEntry).catchError((e) {
      print('Failed to send log to Firestore: $e');
    });

    // Also print locally
    print('[$level] $message ${data != null ? data.toString() : ''}');
  }

  Future<void> info(String message, {Map<String, dynamic>? data}) =>
      log('INFO', message, data: data);

  Future<void> warn(String message, {Map<String, dynamic>? data}) =>
      log('WARN', message, data: data);

  Future<void> error(String message, {Map<String, dynamic>? data}) =>
      log('ERROR', message, data: data);

  List<Map<String, dynamic>> getBufferedLogs() => List.from(_buffer);
}
