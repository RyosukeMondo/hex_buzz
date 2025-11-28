import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/progress_state.dart';
import '../../../domain/services/progress_repository.dart';
import '../../../domain/services/star_calculator.dart';

/// REST API routes for progress management.
///
/// Provides endpoints for AI agents to interact with player progress:
/// - GET /api/progress - Get current progress state
/// - POST /api/progress/complete - Mark a level as completed
/// - POST /api/progress/reset - Reset all progress
class ProgressRoutes {
  final ProgressRepository repository;

  ProgressRoutes({required this.repository});

  /// Creates a router with all progress routes.
  Router get router {
    final router = Router();

    router.get('/', _handleGetProgress);
    router.post('/complete', _handleComplete);
    router.post('/reset', _handleReset);

    return router;
  }

  /// GET /api/progress
  ///
  /// Returns the current progress state.
  /// Response: {"totalStars": int, "completedLevels": int, "levels": {...}}
  Future<Response> _handleGetProgress(Request request) async {
    final state = await repository.load();
    return _jsonResponse(_buildProgressResponse(state));
  }

  /// POST /api/progress/complete
  ///
  /// Marks a level as completed with a time.
  /// Request body: {"level": int, "timeMs": int}
  /// Returns: {"success": bool, "progress": ProgressState, "stars": int, "error"?: string}
  Future<Response> _handleComplete(Request request) async {
    final body = await _parseJsonBody(request);
    if (body == null) {
      return _errorResponse('invalid_json', 'Request body must be valid JSON');
    }

    final validationError = _validateCompleteRequest(body);
    if (validationError != null) return validationError;

    final level = body['level'] as int;
    final timeMs = body['timeMs'] as int;
    final time = Duration(milliseconds: timeMs);
    final stars = StarCalculator.calculateStars(time);
    final currentState = await repository.load();

    if (!currentState.isUnlocked(level)) {
      return _errorResponse(
        'level_locked',
        'Level $level is locked. Complete level ${level - 1} first.',
      );
    }

    final newState = currentState.withLevelCompleted(
      level,
      stars: stars,
      time: time,
    );
    await repository.save(newState);

    return _jsonResponse({
      'success': true,
      'stars': stars,
      'progress': _buildProgressResponse(newState),
    });
  }

  /// Validates the complete request body. Returns an error response if invalid.
  Response? _validateCompleteRequest(Map<String, dynamic> body) {
    final level = body['level'];
    final timeMs = body['timeMs'];

    if (level == null) {
      return _errorResponse(
        'missing_level',
        'Request must include "level" index',
      );
    }
    if (level is! int || level < 0) {
      return _errorResponse(
        'invalid_level',
        '"level" must be a non-negative integer',
      );
    }
    if (timeMs == null) {
      return _errorResponse('missing_time', 'Request must include "timeMs"');
    }
    if (timeMs is! int || timeMs < 0) {
      return _errorResponse(
        'invalid_time',
        '"timeMs" must be a non-negative integer',
      );
    }
    return null;
  }

  /// Creates an error response with consistent format.
  static Response _errorResponse(String error, String message) {
    return _jsonResponse({
      'success': false,
      'error': error,
      'message': message,
    }, statusCode: 400);
  }

  /// POST /api/progress/reset
  ///
  /// Resets all progress to initial state.
  /// Returns: {"success": true, "progress": ProgressState}
  Future<Response> _handleReset(Request request) async {
    await repository.reset();
    final state = await repository.load();

    return _jsonResponse({
      'success': true,
      'progress': _buildProgressResponse(state),
    });
  }

  /// Builds a response object from progress state.
  Map<String, dynamic> _buildProgressResponse(ProgressState state) {
    return {
      'totalStars': state.totalStars,
      'completedLevels': state.completedLevels,
      'highestUnlockedLevel': state.highestUnlockedLevel,
      'levels': state.levels.map(
        (key, value) => MapEntry(key.toString(), {
          'completed': value.completed,
          'stars': value.stars,
          if (value.bestTime != null)
            'bestTimeMs': value.bestTime!.inMilliseconds,
        }),
      ),
    };
  }

  /// Parses JSON from request body, returns null if invalid.
  Future<Map<String, dynamic>?> _parseJsonBody(Request request) async {
    try {
      final bodyString = await request.readAsString();
      if (bodyString.isEmpty) return null;
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
}
