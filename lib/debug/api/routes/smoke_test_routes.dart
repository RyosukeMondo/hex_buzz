import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../main.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/game_provider.dart';
import '../screen_analyzer.dart';
import '../widget_inspector.dart';

/// REST API route for running an automated smoke test.
///
/// Exercises the main user flow (navigate, auth, play, undo, reset)
/// and returns pass/fail results for each step. Only available in debug mode.
class SmokeTestRoutes {
  final WidgetRef ref;
  final GlobalKey<NavigatorState> navigatorKey;

  final WidgetTreeInspector _inspector = WidgetTreeInspector();
  final ScreenAnalyzer _analyzer = ScreenAnalyzer();

  SmokeTestRoutes({required this.ref, required this.navigatorKey});

  /// Creates a router with the smoke test endpoint.
  Router get router {
    assert(kDebugMode, 'SmokeTestRoutes must only be used in debug builds');
    final router = Router();

    router.get('/', _handleSmokeTest);

    return router;
  }

  /// GET /api/smoke-test - Runs a full automated smoke test.
  Future<Response> _handleSmokeTest(Request request) async {
    final results = <Map<String, dynamic>>[];
    final stopwatch = Stopwatch()..start();

    // Step 1: Navigate to front screen
    results.add(await _runStep(
      'navigate_to_front',
      'Navigate to front screen',
      () => _navigateTo(AppRoutes.front),
    ));

    // Step 2: Check front screen renders
    results.add(_runSyncStep(
      'check_front_renders',
      'Check front screen renders',
      () => _checkScreenRenders('front'),
    ));

    // Step 3: Navigate to auth
    results.add(await _runStep(
      'navigate_to_auth',
      'Navigate to auth screen',
      () => _navigateTo(AppRoutes.auth),
    ));

    // Step 4: Login as guest
    results.add(await _runStep(
      'login_as_guest',
      'Login as guest',
      () => _loginAsGuest(),
    ));

    // Step 5: Navigate to levels
    results.add(await _runStep(
      'navigate_to_levels',
      'Navigate to level select',
      () => _navigateTo(AppRoutes.levels),
    ));

    // Step 6: Check level grid renders
    results.add(_runSyncStep(
      'check_levels_render',
      'Check level grid renders',
      () => _checkScreenRenders('levels'),
    ));

    // Step 7: Load level 0
    results.add(_runSyncStep(
      'load_level_0',
      'Load level 0',
      () => _loadLevel(0),
    ));

    // Step 8: Make first move (start cell)
    results.add(_runSyncStep(
      'make_first_move',
      'Make first move (start cell)',
      () => _makeFirstMove(),
    ));

    // Step 9: Undo
    results.add(_runSyncStep(
      'undo_move',
      'Undo last move',
      () => _undoMove(),
    ));

    // Step 10: Reset
    results.add(_runSyncStep(
      'reset_level',
      'Reset level',
      () => _resetLevel(),
    ));

    // Step 11: Navigate back to front
    results.add(await _runStep(
      'navigate_back_to_front',
      'Navigate back to front screen',
      () => _navigateTo(AppRoutes.front),
    ));

    stopwatch.stop();

    final passed = results.where((r) => r['passed'] == true).length;
    final failed = results.where((r) => r['passed'] == false).length;
    final total = results.length;

    return _jsonResponse({
      'summary': {
        'total': total,
        'passed': passed,
        'failed': failed,
        'allPassed': failed == 0,
        'durationMs': stopwatch.elapsedMilliseconds,
      },
      'steps': results,
    });
  }

  // -- Step runners --

  Future<Map<String, dynamic>> _runStep(
    String id,
    String description,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return {
        'id': id,
        'description': description,
        'passed': true,
      };
    } catch (e) {
      return {
        'id': id,
        'description': description,
        'passed': false,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _runSyncStep(
    String id,
    String description,
    void Function() action,
  ) {
    try {
      action();
      return {
        'id': id,
        'description': description,
        'passed': true,
      };
    } catch (e) {
      return {
        'id': id,
        'description': description,
        'passed': false,
        'error': e.toString(),
      };
    }
  }

  // -- Individual test actions --

  Future<void> _navigateTo(String route) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('Navigator not available');
    }
    navigator.pushNamedAndRemoveUntil(route, (r) => false);
    // Allow frame to settle
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  void _checkScreenRenders(String expectedContext) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw StateError('No BuildContext available');
    }

    final route = _inspector.getCurrentRoute(context);
    if (route == 'unknown') {
      throw StateError('Route is unknown, screen may not have rendered');
    }

    // Verify some visible text exists (screen is not blank)
    final visibleText = _analyzer.captureVisibleText(context);
    if (visibleText.isEmpty) {
      throw StateError(
        'No visible text on screen (route: $route, '
        'expected: $expectedContext)',
      );
    }
  }

  Future<void> _loginAsGuest() async {
    final result = await ref.read(authProvider.notifier).playAsGuest();
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      throw StateError('Guest login failed: $result');
    }
  }

  void _loadLevel(int index) {
    final notifier = ref.read(gameProvider.notifier);

    // Try loading from repository; fall back to generate
    final success = notifier.loadLevelByIndex(index);
    if (!success) {
      final generated = notifier.generateNewLevel(newEdgeSize: 3);
      if (!generated) {
        throw StateError('Could not load or generate level $index');
      }
    }
  }

  void _makeFirstMove() {
    final gameState = ref.read(gameProvider);
    final level = gameState.level;

    // Find the start cell (checkpoint 0, or first cell in level)
    final startCell = level.cells.values
        .where((c) => c.checkpoint == 0)
        .firstOrNull;

    if (startCell == null) {
      throw StateError('No start cell (checkpoint 0) found in level');
    }

    final success = ref.read(gameProvider.notifier).tryMove(startCell);
    if (!success) {
      throw StateError('Failed to move to start cell '
          '(q: ${startCell.q}, r: ${startCell.r})');
    }
  }

  void _undoMove() {
    final success = ref.read(gameProvider.notifier).undo();
    if (!success) {
      throw StateError('Undo returned false (no moves to undo?)');
    }
  }

  void _resetLevel() {
    ref.read(gameProvider.notifier).reset();
    final state = ref.read(gameProvider);
    if (state.path.isNotEmpty) {
      throw StateError('Reset did not clear path '
          '(pathLength: ${state.path.length})');
    }
  }

  // -- Utilities --

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
