import 'dart:convert';

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../accessibility_auditor.dart';
import '../navigation_validator.dart';
import '../screen_analyzer.dart';
import '../widget_inspector.dart';

/// REST API routes for runtime diagnostics.
///
/// Provides endpoints for inspecting widget tree, screen state,
/// layout issues, accessibility, and navigation.
///
/// All endpoints require a [GlobalKey<NavigatorState>] to access
/// the live widget tree, and optionally a [WidgetRef] for provider states.
class DiagnosticRoutes {
  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetRef? ref;

  final WidgetTreeInspector _inspector = WidgetTreeInspector();
  final ScreenAnalyzer _analyzer = ScreenAnalyzer();
  final AccessibilityAuditor _auditor = AccessibilityAuditor();
  final NavigationValidator _navValidator = NavigationValidator();

  DiagnosticRoutes({
    required this.navigatorKey,
    this.ref,
  });

  /// Creates a router with all diagnostic routes.
  Router get router {
    final router = Router();

    router.get('/screen', _handleScreen);
    router.get('/widget-tree', _handleWidgetTree);
    router.get('/layout-issues', _handleLayoutIssues);
    router.get('/accessibility', _handleAccessibility);
    router.get('/providers', _handleProviders);
    router.get('/routes', _handleRoutes);
    router.get('/validate-all', _handleValidateAll);
    router.post('/navigate', _handleNavigate);
    router.post('/tap', _handleTap);

    return router;
  }

  /// GET /api/debug/screen
  ///
  /// Returns current screen info: route, visible text, tappable elements.
  Response _handleScreen(Request request) {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final route = _inspector.getCurrentRoute(context);
    final visibleText = _analyzer.captureVisibleText(context);
    final tappable = _analyzer.captureTappableElements(context);

    return _jsonResponse({
      'route': route,
      'visibleText': visibleText,
      'tappableElements': tappable,
      'tappableCount': tappable.length,
    });
  }

  /// GET /api/debug/widget-tree
  ///
  /// Returns the full widget tree. Query param `depth` limits depth (default 10).
  Response _handleWidgetTree(Request request) {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final depthParam = request.url.queryParameters['depth'];
    final maxDepth = int.tryParse(depthParam ?? '') ?? 10;

    final tree = _inspector.captureWidgetTree(context, maxDepth: maxDepth);

    return _jsonResponse({
      'tree': tree,
      'maxDepth': maxDepth,
    });
  }

  /// GET /api/debug/layout-issues
  ///
  /// Detects layout problems (overflow, zero size, off-screen, etc).
  Response _handleLayoutIssues(Request request) {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final issues = _inspector.detectLayoutIssues(context);

    return _jsonResponse({
      'issueCount': issues.length,
      'issues': issues.map((i) => i.toJson()).toList(),
    });
  }

  /// GET /api/debug/accessibility
  ///
  /// Runs accessibility audit (semantics, contrast, touch targets).
  Response _handleAccessibility(Request request) {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final issues = _auditor.runFullAudit(context);

    return _jsonResponse({
      'issueCount': issues.length,
      'issues': issues.map((i) => i.toJson()).toList(),
    });
  }

  /// GET /api/debug/providers
  ///
  /// Returns all provider states as JSON.
  Response _handleProviders(Request request) {
    if (ref == null) {
      return _jsonResponse({
        'error': 'no_ref',
        'message': 'WidgetRef not available for provider inspection',
      }, statusCode: 503);
    }

    final states = _analyzer.captureProviderStates(ref!);

    return _jsonResponse({
      'providers': states,
    });
  }

  /// GET /api/debug/routes
  ///
  /// Lists all known routes and their status.
  Response _handleRoutes(Request request) {
    final navigator = navigatorKey.currentState;
    final knownRoutes = _inspector.getRegisteredRoutes();

    final currentStack =
        navigator != null ? _navValidator.getCurrentStack(navigator) : [];

    return _jsonResponse({
      'knownRoutes': knownRoutes,
      'currentStack': currentStack,
      'routeCount': knownRoutes.length,
    });
  }

  /// GET /api/debug/validate-all
  ///
  /// Runs comprehensive validation across all diagnostics.
  Future<Response> _handleValidateAll(Request request) async {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final layoutIssues = _inspector.detectLayoutIssues(context);
    final accessibilityIssues = _auditor.runFullAudit(context);
    final visibleText = _analyzer.captureVisibleText(context);
    final tappable = _analyzer.captureTappableElements(context);

    final navigator = navigatorKey.currentState;
    List<Map<String, dynamic>> routeResults = [];
    if (navigator != null) {
      final results = await _navValidator.validateAllRoutes(navigator);
      routeResults = results.map((r) => r.toJson()).toList();
    }

    Map<String, dynamic>? providerStates;
    if (ref != null) {
      providerStates = _analyzer.captureProviderStates(ref!);
    }

    final totalIssues =
        layoutIssues.length + accessibilityIssues.length;

    return _jsonResponse({
      'summary': {
        'totalIssues': totalIssues,
        'layoutIssueCount': layoutIssues.length,
        'accessibilityIssueCount': accessibilityIssues.length,
        'visibleTextCount': visibleText.length,
        'tappableElementCount': tappable.length,
        'routeCount': routeResults.length,
      },
      'layoutIssues': layoutIssues.map((i) => i.toJson()).toList(),
      'accessibilityIssues':
          accessibilityIssues.map((i) => i.toJson()).toList(),
      'routeResults': routeResults,
      if (providerStates != null) 'providerStates': providerStates,
    });
  }

  /// POST /api/debug/navigate
  ///
  /// Navigates to a specific route.
  /// Request body: {"route": "/settings"}
  Future<Response> _handleNavigate(Request request) async {
    final body = await _parseJsonBody(request);
    if (body == null) {
      return _jsonResponse({
        'success': false,
        'error': 'invalid_json',
        'message': 'Request body must be valid JSON',
      }, statusCode: 400);
    }

    final route = body['route'] as String?;
    if (route == null || route.isEmpty) {
      return _jsonResponse({
        'success': false,
        'error': 'missing_route',
        'message': 'Request must include "route" field',
      }, statusCode: 400);
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return _noContextResponse();
    }

    try {
      navigator.pushNamed(route);
      return _jsonResponse({
        'success': true,
        'navigatedTo': route,
      });
    } catch (e) {
      return _jsonResponse({
        'success': false,
        'error': 'navigation_failed',
        'message': e.toString(),
      }, statusCode: 500);
    }
  }

  /// POST /api/debug/tap
  ///
  /// Taps a widget by text or type.
  /// Request body: {"text": "Start"} or {"type": "ElevatedButton", "index": 0}
  Future<Response> _handleTap(Request request) async {
    final body = await _parseJsonBody(request);
    if (body == null) {
      return _jsonResponse({
        'success': false,
        'error': 'invalid_json',
        'message': 'Request body must be valid JSON',
      }, statusCode: 400);
    }

    return _processTapRequest(body);
  }

  Response _processTapRequest(Map<String, dynamic> body) {
    final context = _getContext();
    if (context == null) return _noContextResponse();

    final text = body['text'] as String?;
    final type = body['type'] as String?;
    final index = (body['index'] as int?) ?? 0;

    if (text == null && type == null) {
      return _jsonResponse({
        'success': false,
        'error': 'missing_target',
        'message': 'Request must include "text" or "type" field',
      }, statusCode: 400);
    }

    if (text != null) {
      return _tapByText(context, text);
    }

    return _tapByType(context, type!, index);
  }

  Response _tapByText(BuildContext context, String text) {
    final tappable = _analyzer.captureTappableElements(context);
    final match = tappable.where((t) => t['label'] == text).toList();

    if (match.isEmpty) {
      return _jsonResponse({
        'success': false,
        'error': 'not_found',
        'message': 'No tappable element with text "$text"',
        'availableLabels':
            tappable.map((t) => t['label']).where((l) => l != null).toList(),
      }, statusCode: 404);
    }

    return _jsonResponse({
      'success': true,
      'tapped': match.first,
      'message': 'Widget found. Use Flutter test framework for actual taps.',
    });
  }

  Response _tapByType(BuildContext context, String type, int index) {
    final widgets = _inspector.findWidgets(context, type);

    if (widgets.isEmpty) {
      return _jsonResponse({
        'success': false,
        'error': 'not_found',
        'message': 'No widget of type "$type" found',
      }, statusCode: 404);
    }

    if (index >= widgets.length) {
      return _jsonResponse({
        'success': false,
        'error': 'index_out_of_range',
        'message': 'Index $index out of range. '
            'Found ${widgets.length} widgets of type "$type"',
      }, statusCode: 400);
    }

    return _jsonResponse({
      'success': true,
      'tapped': widgets[index],
      'message': 'Widget found. Use Flutter test framework for actual taps.',
    });
  }

  // -- Utilities --

  BuildContext? _getContext() {
    return navigatorKey.currentContext;
  }

  Response _noContextResponse() {
    return _jsonResponse({
      'error': 'no_context',
      'message': 'No active BuildContext. Is the app running?',
    }, statusCode: 503);
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
