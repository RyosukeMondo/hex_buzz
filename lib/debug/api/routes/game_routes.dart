import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/models/hex_cell.dart';
import '../../../domain/services/game_engine.dart';

/// REST API routes for game state management.
///
/// Provides endpoints for AI agents to interact with the game:
/// - GET /api/game/state - Get current game state
/// - POST /api/game/move - Execute a move
/// - POST /api/game/reset - Reset the game
class GameRoutes {
  final GameEngine engine;

  GameRoutes({required this.engine});

  /// Creates a router with all game routes.
  Router get router {
    final router = Router();

    router.get('/state', _handleGetState);
    router.post('/move', _handleMove);
    router.post('/reset', _handleReset);

    return router;
  }

  /// GET /api/game/state
  ///
  /// Returns the current game state as JSON.
  Response _handleGetState(Request request) {
    final state = engine.state;
    return _jsonResponse(_buildStateResponse(state));
  }

  /// POST /api/game/move
  ///
  /// Executes a move to the specified cell.
  /// Request body: {"q": int, "r": int}
  /// Returns: {"success": bool, "state": GameState, "error"?: string, "isWin"?: bool}
  Future<Response> _handleMove(Request request) async {
    final body = await _parseJsonBody(request);
    if (body == null) {
      return _jsonResponse({
        'success': false,
        'error': 'invalid_json',
        'message': 'Request body must be valid JSON',
        'state': _buildStateResponse(engine.state),
      }, statusCode: 400);
    }

    final q = body['q'];
    final r = body['r'];

    if (q == null || r == null) {
      return _jsonResponse({
        'success': false,
        'error': 'missing_coordinates',
        'message': 'Request must include "q" and "r" coordinates',
        'state': _buildStateResponse(engine.state),
      }, statusCode: 400);
    }

    if (q is! int || r is! int) {
      return _jsonResponse({
        'success': false,
        'error': 'invalid_coordinates',
        'message': 'Coordinates "q" and "r" must be integers',
        'state': _buildStateResponse(engine.state),
      }, statusCode: 400);
    }

    final target = HexCell(q: q, r: r);
    final result = engine.tryMove(target);

    return _jsonResponse({
      'success': result.success,
      if (!result.success) 'error': 'move_rejected',
      if (!result.success) 'message': result.error,
      if (result.isWin) 'isWin': true,
      'state': _buildStateResponse(result.state),
    }, statusCode: result.success ? 200 : 400);
  }

  /// POST /api/game/reset
  ///
  /// Resets the game to its initial state.
  /// Returns: {"success": true, "state": GameState}
  Response _handleReset(Request request) {
    engine.reset();
    return _jsonResponse({
      'success': true,
      'state': _buildStateResponse(engine.state),
    });
  }

  /// Builds a response object from game state.
  Map<String, dynamic> _buildStateResponse(GameState state) {
    return {
      'level': {
        'id': state.level.id,
        'size': state.level.size,
        'checkpointCount': state.level.checkpointCount,
        'cells': state.level.cells.values.map((c) => c.toJson()).toList(),
        'walls': state.level.walls.map((w) => w.toJson()).toList(),
      },
      'mode': state.mode.name,
      'path': state.path.map((c) => {'q': c.q, 'r': c.r}).toList(),
      'nextCheckpoint': state.nextCheckpoint,
      'isStarted': state.isStarted,
      'isComplete': state.isComplete,
      'elapsedTimeMs': state.elapsedTime.inMilliseconds,
      'visitedCells': state.visitedCoordinates.map((c) => {'q': c.$1, 'r': c.$2}).toList(),
      'currentCell': state.currentCell != null
          ? {'q': state.currentCell!.q, 'r': state.currentCell!.r}
          : null,
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
