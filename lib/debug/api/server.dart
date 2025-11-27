import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../core/logging/logger.dart';
import '../../domain/services/game_engine.dart';

/// Debug REST API server for AI agent interaction.
///
/// Provides HTTP endpoints for game state management and level validation.
/// Intended for localhost development use only.
class DebugApiServer {
  DebugApiServer({required this.engine, this.port = 8080, Logger? logger})
    : _logger = logger ?? LoggerFactory.create('api-server');

  /// The game engine to expose via API.
  final GameEngine engine;

  /// The port to listen on.
  final int port;

  final Logger _logger;
  HttpServer? _server;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Starts the HTTP server.
  ///
  /// Returns a Future that completes when the server is ready to accept
  /// connections.
  Future<void> start() async {
    if (_server != null) {
      _logger.warn('server_already_running', {'port': port});
      return;
    }

    final handler = _buildHandler();
    _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, port);

    _logger.info('server_started', {
      'port': port,
      'address': 'http://localhost:$port',
    });
  }

  /// Stops the HTTP server gracefully.
  ///
  /// Waits for active connections to complete before closing.
  Future<void> stop() async {
    if (_server == null) {
      _logger.warn('server_not_running');
      return;
    }

    await _server!.close();
    _server = null;
    _logger.info('server_stopped');
  }

  Handler _buildHandler() {
    final router = Router();

    // Health check endpoint
    router.get('/api/health', _handleHealth);

    // Placeholder for game routes (to be added in task 4.4)
    router.get('/api/game/state', _placeholderHandler);
    router.post('/api/game/move', _placeholderHandler);
    router.post('/api/game/reset', _placeholderHandler);

    // Placeholder for level routes (to be added in task 4.5)
    router.post('/api/level/validate', _placeholderHandler);

    final pipeline = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_jsonMiddleware())
        .addMiddleware(_loggingMiddleware())
        .addHandler(router.call);

    return pipeline;
  }

  Response _handleHealth(Request request) {
    return _jsonResponse({
      'status': 'ok',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Response _placeholderHandler(Request request) {
    return _jsonResponse({
      'error': 'not_implemented',
      'message': 'This endpoint is not yet implemented',
    }, statusCode: 501);
  }

  /// Creates a JSON response with proper content type.
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

  /// CORS middleware for local development.
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Handle preflight requests
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };

  /// Middleware to ensure JSON content type on requests.
  Middleware _jsonMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // For POST/PUT requests, validate content type
        if ((request.method == 'POST' || request.method == 'PUT') &&
            request.headers['content-type'] != null &&
            !request.headers['content-type']!.contains('application/json')) {
          return _jsonResponse({
            'error': 'invalid_content_type',
            'message': 'Content-Type must be application/json',
          }, statusCode: 415);
        }
        return innerHandler(request);
      };
    };
  }

  /// Middleware for request/response logging.
  Middleware _loggingMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        _logger.debug('request_received', {
          'method': request.method,
          'path': request.url.path,
        });

        final response = await innerHandler(request);
        stopwatch.stop();

        _logger.info('request_completed', {
          'method': request.method,
          'path': request.url.path,
          'status': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });

        return response;
      };
    };
  }
}

/// Starts the debug API server with the given engine.
///
/// Returns a [DebugApiServer] instance that can be used to stop the server.
Future<DebugApiServer> startServer(int port, GameEngine engine) async {
  final server = DebugApiServer(engine: engine, port: port);
  await server.start();
  return server;
}
