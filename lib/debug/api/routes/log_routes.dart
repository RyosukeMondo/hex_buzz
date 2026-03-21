import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/logging/diagnostic_logger.dart';

/// REST API routes for log inspection and real-time streaming.
///
/// Endpoints:
/// - GET  /                    Recent logs (query: limit, level, event, since)
/// - GET  /files               List log files with metadata
/// - GET  /files/`<filename>`  Read a specific log file
/// - GET  /stream              SSE stream of real-time logs
/// - GET  /stats               Log statistics
/// - DELETE /                  Clear all logs
class LogRoutes {
  /// Creates log routes backed by the [DiagnosticLogger] singleton.
  LogRoutes();

  /// Creates a [Router] with all log endpoints.
  Router get router {
    final router = Router();

    router.get('/', _handleGetLogs);
    router.get('/files', _handleListFiles);
    router.get('/files/<filename>', _handleReadFile);
    router.get('/stream', _handleStream);
    router.get('/stats', _handleStats);
    router.delete('/', _handleClear);

    return router;
  }

  /// GET /api/logs?limit=100&level=error&event=crash&since=2024-01-01
  Future<Response> _handleGetLogs(Request request) async {
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '') ?? 100;
    final level = params['level'];
    final event = params['event'];
    final sinceStr = params['since'];
    final since = sinceStr != null ? DateTime.tryParse(sinceStr) : null;

    final fileLogger = DiagnosticLogger.fileLogger;
    List<Map<String, dynamic>> logs;

    if (fileLogger != null && fileLogger.isInitialized) {
      logs = await fileLogger.readLogs(
        limit: limit,
        level: level,
        event: event,
        since: since,
      );
    } else {
      logs = _filterBufferedLogs(
        limit: limit,
        level: level,
        event: event,
        since: since,
      );
    }

    return _jsonResponse({
      'success': true,
      'count': logs.length,
      'source': fileLogger?.isInitialized == true ? 'file' : 'memory',
      'logs': logs,
    });
  }

  /// GET /api/logs/files
  Future<Response> _handleListFiles(Request request) async {
    final fileLogger = DiagnosticLogger.fileLogger;
    if (fileLogger == null || !fileLogger.isInitialized) {
      return _jsonResponse({
        'success': false,
        'error': 'file_logger_unavailable',
        'message': 'File logger is not initialized',
      }, statusCode: 503);
    }

    final files = await fileLogger.getLogFilesWithMeta();
    return _jsonResponse({
      'success': true,
      'count': files.length,
      'files': files,
    });
  }

  /// GET /api/logs/files/`<filename>`
  Future<Response> _handleReadFile(Request request, String filename) async {
    final fileLogger = DiagnosticLogger.fileLogger;
    if (fileLogger == null || !fileLogger.isInitialized) {
      return _jsonResponse({
        'success': false,
        'error': 'file_logger_unavailable',
        'message': 'File logger is not initialized',
      }, statusCode: 503);
    }

    // Prevent path traversal
    if (filename.contains('..') || filename.contains('/')) {
      return _jsonResponse({
        'success': false,
        'error': 'invalid_filename',
        'message': 'Filename must not contain path separators',
      }, statusCode: 400);
    }

    try {
      final content = await fileLogger.getLogContent(filename);
      return Response.ok(
        content,
        headers: {
          'content-type': 'text/plain; charset=utf-8',
          'content-disposition': 'inline; filename="$filename"',
        },
      );
    } catch (e) {
      return _jsonResponse({
        'success': false,
        'error': 'file_not_found',
        'message': 'Log file "$filename" not found',
      }, statusCode: 404);
    }
  }

  /// GET /api/logs/stream - Server-Sent Events stream.
  Response _handleStream(Request request) {
    final fileLogger = DiagnosticLogger.fileLogger;

    final controller = StreamController<List<int>>();
    StreamSubscription<Map<String, dynamic>>? subscription;

    // Send SSE keep-alive comment immediately
    controller.add(utf8.encode(': connected\n\n'));

    if (fileLogger != null) {
      subscription = fileLogger.logStream.listen(
        (entry) {
          try {
            final data = jsonEncode(entry);
            controller.add(utf8.encode('data: $data\n\n'));
          } catch (_) {}
        },
        onError: (_) {},
      );
    }

    controller.onCancel = () {
      subscription?.cancel();
    };

    return Response.ok(
      controller.stream,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
        'access-control-allow-origin': '*',
      },
    );
  }

  /// GET /api/logs/stats
  Future<Response> _handleStats(Request request) async {
    final fileLogger = DiagnosticLogger.fileLogger;
    if (fileLogger != null && fileLogger.isInitialized) {
      final stats = await fileLogger.getStats();
      return _jsonResponse({
        'success': true,
        'source': 'file',
        ...stats,
      });
    }

    // Fall back to in-memory stats
    final buffered = DiagnosticLogger.getBufferedLogs();
    final countByLevel = <String, int>{};
    for (final entry in buffered) {
      final level = entry['level'] as String? ?? 'unknown';
      countByLevel[level] = (countByLevel[level] ?? 0) + 1;
    }

    return _jsonResponse({
      'success': true,
      'source': 'memory',
      'totalEntries': buffered.length,
      'countByLevel': countByLevel,
    });
  }

  /// DELETE /api/logs
  Future<Response> _handleClear(Request request) async {
    await DiagnosticLogger.clearAll();
    return _jsonResponse({
      'success': true,
      'message': 'All logs cleared',
    });
  }

  // -- Helpers --

  List<Map<String, dynamic>> _filterBufferedLogs({
    required int limit,
    String? level,
    String? event,
    DateTime? since,
  }) {
    var logs = DiagnosticLogger.getBufferedLogs().reversed.toList();

    if (level != null) {
      logs = logs.where((e) => e['level'] == level).toList();
    }
    if (event != null) {
      final lower = event.toLowerCase();
      logs = logs
          .where((e) =>
              (e['event'] as String? ?? '').toLowerCase().contains(lower))
          .toList();
    }
    if (since != null) {
      logs = logs.where((e) {
        final ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null && !ts.isBefore(since);
      }).toList();
    }

    if (logs.length > limit) {
      logs = logs.sublist(0, limit);
    }
    return logs;
  }

  static Response _jsonResponse(
    Map<String, dynamic> data, {
    int statusCode = 200,
  }) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );
  }
}
