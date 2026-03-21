import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../core/logging/logger.dart';
import '../../domain/services/auth_repository.dart';
import '../../domain/services/daily_challenge_repository.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/leaderboard_repository.dart';
import '../../domain/services/progress_repository.dart';
import 'routes/auth_routes.dart';
import 'routes/daily_challenge_routes.dart';
import 'routes/diagnostic_routes.dart';
import 'routes/game_routes.dart';
import 'routes/leaderboard_routes.dart';
import 'routes/level_routes.dart';
import 'routes/log_routes.dart';
import 'routes/progress_routes.dart';

/// Debug REST API server for AI agent interaction.
///
/// Provides HTTP endpoints for game state management and level validation.
/// Intended for localhost development use only.
class DebugApiServer {
  DebugApiServer({
    required this.engine,
    this.progressRepository,
    this.authRepository,
    this.leaderboardRepository,
    this.dailyChallengeRepository,
    this.navigatorKey,
    this.ref,
    this.port = 8080,
    Logger? logger,
  }) : _logger = logger ?? LoggerFactory.create('api-server');

  /// The game engine to expose via API.
  final GameEngine engine;

  /// Optional progress repository for progress API endpoints.
  final ProgressRepository? progressRepository;

  /// Optional auth repository for authentication API endpoints.
  final AuthRepository? authRepository;

  /// Optional leaderboard repository for leaderboard API endpoints.
  final LeaderboardRepository? leaderboardRepository;

  /// Optional daily challenge repository for daily challenge API endpoints.
  final DailyChallengeRepository? dailyChallengeRepository;

  /// Navigator key for accessing the widget tree in diagnostic endpoints.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Widget ref for accessing provider states in diagnostic endpoints.
  final WidgetRef? ref;

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
    router.get('/api/health', _handleHealth);
    _mountRoutes(router);

    return const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_jsonMiddleware())
        .addMiddleware(_loggingMiddleware())
        .addHandler(router.call);
  }

  void _mountRoutes(Router router) {
    router.mount('/api/game/', GameRoutes(engine: engine).router.call);
    router.mount('/api/level/', LevelRoutes().router.call);

    if (progressRepository != null) {
      router.mount(
        '/api/progress/',
        ProgressRoutes(repository: progressRepository!).router.call,
      );
    }
    if (authRepository != null) {
      router.mount(
        '/api/auth/',
        AuthRoutes(repository: authRepository!).router.call,
      );
    }
    if (leaderboardRepository != null && authRepository != null) {
      router.mount(
        '/api/leaderboard/',
        LeaderboardRoutes(
          repository: leaderboardRepository!,
          authRepository: authRepository!,
        ).router.call,
      );
    }
    if (dailyChallengeRepository != null && authRepository != null) {
      router.mount(
        '/api/daily-challenge/',
        DailyChallengeRoutes(
          repository: dailyChallengeRepository!,
          authRepository: authRepository!,
        ).router.call,
      );
    }
    if (navigatorKey != null) {
      router.mount(
        '/api/debug/',
        DiagnosticRoutes(
          navigatorKey: navigatorKey!,
          ref: ref,
        ).router.call,
      );
    }
    router.mount('/api/logs/', LogRoutes().router.call);
  }

  Response _handleHealth(Request request) {
    return _jsonResponse({
      'status': 'ok',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
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
/// Optionally accepts repositories to enable various API endpoints:
/// - [ProgressRepository] for progress API endpoints
/// - [AuthRepository] for authentication API endpoints
/// - [LeaderboardRepository] for leaderboard API endpoints
/// - [DailyChallengeRepository] for daily challenge API endpoints
///
/// Returns a [DebugApiServer] instance that can be used to stop the server.
Future<DebugApiServer> startServer(
  int port,
  GameEngine engine, {
  ProgressRepository? progressRepository,
  AuthRepository? authRepository,
  LeaderboardRepository? leaderboardRepository,
  DailyChallengeRepository? dailyChallengeRepository,
  GlobalKey<NavigatorState>? navigatorKey,
  WidgetRef? ref,
}) async {
  final server = DebugApiServer(
    engine: engine,
    port: port,
    progressRepository: progressRepository,
    authRepository: authRepository,
    leaderboardRepository: leaderboardRepository,
    dailyChallengeRepository: dailyChallengeRepository,
    navigatorKey: navigatorKey,
    ref: ref,
  );
  await server.start();
  return server;
}
