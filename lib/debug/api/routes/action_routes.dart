import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../domain/services/timed_challenge_service.dart';
import '../../../main.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/game_provider.dart';
import '../../../presentation/providers/hint_provider.dart';
import '../../../presentation/providers/tutorial_provider.dart';

/// REST API routes for invoking frontend actions programmatically.
///
/// Provides endpoints that trigger game/UI actions via Riverpod providers,
/// returning the resulting state as JSON. Only available in debug mode.
class ActionRoutes {
  final WidgetRef ref;
  final GlobalKey<NavigatorState> navigatorKey;

  ActionRoutes({required this.ref, required this.navigatorKey});

  /// Creates a router with all action routes.
  Router get router {
    assert(kDebugMode, 'ActionRoutes must only be used in debug builds');
    final router = Router();

    router.post('/hint', _handleHint);
    router.post('/undo', _handleUndo);
    router.post('/reset', _handleReset);
    router.post('/next-level', _handleNextLevel);
    router.post('/generate', _handleGenerate);
    router.post('/load-level', _handleLoadLevel);
    router.post('/start-timed', _handleStartTimed);
    router.post('/login-guest', _handleLoginGuest);
    router.post('/logout', _handleLogout);
    router.post('/complete-tutorial', _handleCompleteTutorial);

    return router;
  }

  /// POST /api/actions/hint - Request a hint for the current game.
  Response _handleHint(Request request) {
    try {
      ref.read(hintProvider.notifier).requestHint();
      final hintState = ref.read(hintProvider);

      return _jsonResponse({
        'success': true,
        'action': 'hint',
        'state': _buildHintState(hintState),
      });
    } catch (e) {
      return _errorResponse('hint_failed', e.toString());
    }
  }

  /// POST /api/actions/undo - Undo the last move.
  Response _handleUndo(Request request) {
    try {
      final success = ref.read(gameProvider.notifier).undo();
      final gameState = ref.read(gameProvider);

      return _jsonResponse({
        'success': success,
        'action': 'undo',
        'state': _buildGameState(gameState),
      });
    } catch (e) {
      return _errorResponse('undo_failed', e.toString());
    }
  }

  /// POST /api/actions/reset - Reset the current level.
  Response _handleReset(Request request) {
    try {
      ref.read(gameProvider.notifier).reset();
      final gameState = ref.read(gameProvider);

      return _jsonResponse({
        'success': true,
        'action': 'reset',
        'state': _buildGameState(gameState),
      });
    } catch (e) {
      return _errorResponse('reset_failed', e.toString());
    }
  }

  /// POST /api/actions/next-level - Load the next level.
  Response _handleNextLevel(Request request) {
    try {
      final notifier = ref.read(gameProvider.notifier);
      final currentIndex = notifier.currentLevelIndex;
      final nextIndex = (currentIndex ?? -1) + 1;
      final success = notifier.loadLevelByIndex(nextIndex);
      final gameState = ref.read(gameProvider);

      return _jsonResponse({
        'success': success,
        'action': 'next_level',
        'levelIndex': nextIndex,
        'state': _buildGameState(gameState),
      });
    } catch (e) {
      return _errorResponse('next_level_failed', e.toString());
    }
  }

  /// POST /api/actions/generate - Generate a new random level.
  /// Body: {"size": 3} (optional, defaults to current edge size)
  Future<Response> _handleGenerate(Request request) async {
    try {
      final body = await _parseJsonBody(request);
      final size = body?['size'] as int?;
      final success = ref.read(gameProvider.notifier).generateNewLevel(
        newEdgeSize: size,
      );
      final gameState = ref.read(gameProvider);

      return _jsonResponse({
        'success': success,
        'action': 'generate',
        'edgeSize': size ?? ref.read(gameProvider.notifier).edgeSize,
        'state': _buildGameState(gameState),
      });
    } catch (e) {
      return _errorResponse('generate_failed', e.toString());
    }
  }

  /// POST /api/actions/load-level - Load a specific level.
  /// Body: {"index": 0}
  Future<Response> _handleLoadLevel(Request request) async {
    try {
      final body = await _parseJsonBody(request);
      if (body == null || body['index'] == null) {
        return _jsonResponse({
          'success': false,
          'error': 'missing_index',
          'message': 'Request body must include "index" field',
        }, statusCode: 400);
      }

      final index = body['index'] as int;
      final success = ref.read(gameProvider.notifier).loadLevelByIndex(index);
      final gameState = ref.read(gameProvider);

      return _jsonResponse({
        'success': success,
        'action': 'load_level',
        'levelIndex': index,
        'state': _buildGameState(gameState),
      });
    } catch (e) {
      return _errorResponse('load_level_failed', e.toString());
    }
  }

  /// POST /api/actions/start-timed - Start a timed challenge.
  /// Body: {"config": "sprint"} (blitz, sprint, or marathon)
  Future<Response> _handleStartTimed(Request request) async {
    try {
      final body = await _parseJsonBody(request);
      final configName = body?['config'] as String? ?? 'sprint';

      final config = _resolveTimedConfig(configName);
      if (config == null) {
        return _jsonResponse({
          'success': false,
          'error': 'invalid_config',
          'message': 'Unknown config "$configName". '
              'Valid: blitz, sprint, marathon',
        }, statusCode: 400);
      }

      // Navigate to timed challenge screen
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed(AppRoutes.timedChallenge, arguments: config);
      }

      return _jsonResponse({
        'success': true,
        'action': 'start_timed',
        'config': {
          'id': config.id,
          'name': config.name,
          'timeLimitMs': config.timeLimit.inMilliseconds,
          'startingEdgeSize': config.startingEdgeSize,
          'bonusTimePerSolveMs': config.bonusTimePerSolve.inMilliseconds,
        },
      });
    } catch (e) {
      return _errorResponse('start_timed_failed', e.toString());
    }
  }

  /// POST /api/actions/login-guest - Login as a guest user.
  Future<Response> _handleLoginGuest(Request request) async {
    try {
      final result = await ref.read(authProvider.notifier).playAsGuest();
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;

      return _jsonResponse({
        'success': user != null,
        'action': 'login_guest',
        'result': result.toString(),
        'user': user != null
            ? {
                'id': user.id,
                'username': user.username,
                'isGuest': user.isGuest,
              }
            : null,
      });
    } catch (e) {
      return _errorResponse('login_guest_failed', e.toString());
    }
  }

  /// POST /api/actions/logout - Logout the current user.
  Future<Response> _handleLogout(Request request) async {
    try {
      await ref.read(authProvider.notifier).logout();

      return _jsonResponse({
        'success': true,
        'action': 'logout',
      });
    } catch (e) {
      return _errorResponse('logout_failed', e.toString());
    }
  }

  /// POST /api/actions/complete-tutorial - Skip/complete the tutorial.
  Response _handleCompleteTutorial(Request request) {
    try {
      ref.read(tutorialProvider.notifier).skip();
      final tutState = ref.read(tutorialProvider);

      return _jsonResponse({
        'success': true,
        'action': 'complete_tutorial',
        'state': tutState.toJson(),
      });
    } catch (e) {
      return _errorResponse('complete_tutorial_failed', e.toString());
    }
  }

  // -- Helpers --

  TimedChallengeConfig? _resolveTimedConfig(String name) {
    return switch (name.toLowerCase()) {
      'blitz' => TimedChallengeConfig.blitz,
      'sprint' => TimedChallengeConfig.sprint,
      'marathon' => TimedChallengeConfig.marathon,
      _ => null,
    };
  }

  Map<String, dynamic> _buildGameState(dynamic gameState) {
    return {
      'mode': gameState.mode.name,
      'isStarted': gameState.isStarted,
      'isComplete': gameState.isComplete,
      'pathLength': gameState.path.length,
      'nextCheckpoint': gameState.nextCheckpoint,
      'elapsedTimeMs': gameState.elapsedTime.inMilliseconds,
      'currentCell': gameState.currentCell != null
          ? {'q': gameState.currentCell!.q, 'r': gameState.currentCell!.r}
          : null,
    };
  }

  Map<String, dynamic> _buildHintState(HintState hintState) {
    return {
      'hintsRemaining': hintState.hintsRemaining,
      'maxHints': hintState.maxHints,
      'hasHintsRemaining': hintState.hasHintsRemaining,
      'isCalculating': hintState.isCalculating,
      'currentHint': hintState.currentHint?.toString(),
    };
  }

  Future<Map<String, dynamic>?> _parseJsonBody(Request request) async {
    try {
      final bodyString = await request.readAsString();
      if (bodyString.isEmpty) return null;
      return jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Response _errorResponse(String error, String message) {
    return _jsonResponse({
      'success': false,
      'error': error,
      'message': message,
    }, statusCode: 500);
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
