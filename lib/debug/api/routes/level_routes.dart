import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/level.dart';
import '../../../domain/services/level_validator.dart';

/// REST API routes for level validation.
///
/// Provides endpoints for AI agents to validate level designs:
/// - POST /api/level/validate - Validate a level JSON
class LevelRoutes {
  final LevelValidator validator;

  LevelRoutes({LevelValidator? validator})
      : validator = validator ?? const LevelValidator();

  /// Creates a router with all level routes.
  Router get router {
    final router = Router();
    router.post('/validate', _handleValidate);
    return router;
  }

  /// POST /api/level/validate
  ///
  /// Validates a level definition.
  /// Request body: Level JSON (see Level.fromJson for format)
  /// Returns: {"valid": bool, "solvable": bool, "solution"?: [...], "error"?: string}
  Future<Response> _handleValidate(Request request) async {
    final body = await _parseJsonBody(request);
    if (body == null) {
      return _jsonResponse({
        'valid': false,
        'solvable': false,
        'error': 'invalid_json',
        'message': 'Request body must be valid JSON',
      }, statusCode: 400);
    }

    // Parse level from JSON
    final Level level;
    try {
      level = Level.fromJson(body);
    } catch (e) {
      return _jsonResponse({
        'valid': false,
        'solvable': false,
        'error': 'invalid_level_format',
        'message': 'Failed to parse level: ${e.toString()}',
      }, statusCode: 400);
    }

    // Validate the level
    final result = validator.validate(level);

    return _jsonResponse({
      'valid': true,
      'solvable': result.isSolvable,
      if (result.solutionPath != null)
        'solution': result.solutionPath!.map((c) => {'q': c.q, 'r': c.r}).toList(),
      if (result.error != null) 'error': result.error,
      'levelId': level.id,
    });
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
