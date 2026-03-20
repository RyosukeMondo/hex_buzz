import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/accessibility_auditor.dart';
import '../api/models/diagnostic_models.dart';
import '../api/navigation_validator.dart';
import '../api/screen_analyzer.dart';
import '../api/widget_inspector.dart';

/// Runs all diagnostics programmatically and produces a report.
///
/// Can be used from tests, CI, or the CLI to perform a full
/// diagnostic scan of the running application.
class DiagnosticRunner {
  final WidgetTreeInspector _inspector;
  final ScreenAnalyzer _analyzer;
  final AccessibilityAuditor _auditor;
  final NavigationValidator _navValidator;

  DiagnosticRunner({
    WidgetTreeInspector? inspector,
    ScreenAnalyzer? analyzer,
    AccessibilityAuditor? auditor,
    NavigationValidator? navValidator,
  })  : _inspector = inspector ?? WidgetTreeInspector(),
        _analyzer = analyzer ?? ScreenAnalyzer(),
        _auditor = auditor ?? AccessibilityAuditor(),
        _navValidator = navValidator ?? NavigationValidator();

  /// Runs all diagnostics and returns a comprehensive report.
  ///
  /// Performs layout issue detection, accessibility audit,
  /// screen state capture, and route validation.
  Future<DiagnosticReport> runFullDiagnostic(
    BuildContext context, {
    WidgetRef? ref,
    NavigatorState? navigator,
  }) async {
    final layoutIssues = _runLayoutCheck(context);
    final accessibilityIssues = _runAccessibilityAudit(context);
    final screenStates = _captureScreenStates(context, ref);
    final routeResults = await _runRouteValidation(navigator);

    return DiagnosticReport(
      layoutIssues: layoutIssues,
      accessibilityIssues: accessibilityIssues,
      screenStates: screenStates,
      routeResults: routeResults,
    );
  }

  List<LayoutIssue> _runLayoutCheck(BuildContext context) {
    try {
      return _inspector.detectLayoutIssues(context);
    } catch (e) {
      return [
        LayoutIssue(
          type: 'error',
          widgetType: 'DiagnosticRunner',
          details: 'Layout check failed: $e',
        ),
      ];
    }
  }

  List<AccessibilityIssue> _runAccessibilityAudit(BuildContext context) {
    try {
      return _auditor.runFullAudit(context);
    } catch (e) {
      return [
        AccessibilityIssue(
          type: 'error',
          widgetType: 'DiagnosticRunner',
          details: 'Accessibility audit failed: $e',
          severity: 'error',
        ),
      ];
    }
  }

  Map<String, dynamic> _captureScreenStates(
    BuildContext context,
    WidgetRef? ref,
  ) {
    final states = <String, dynamic>{};

    try {
      states['currentRoute'] = _inspector.getCurrentRoute(context);
    } catch (e) {
      states['currentRoute'] = 'error: $e';
    }

    try {
      states['visibleText'] = _analyzer.captureVisibleText(context);
    } catch (e) {
      states['visibleText'] = 'error: $e';
    }

    try {
      states['tappableElements'] =
          _analyzer.captureTappableElements(context);
    } catch (e) {
      states['tappableElements'] = 'error: $e';
    }

    if (ref != null) {
      try {
        states['providers'] = _analyzer.captureProviderStates(ref);
      } catch (e) {
        states['providers'] = 'error: $e';
      }
    }

    return states;
  }

  Future<List<RouteTestResult>> _runRouteValidation(
    NavigatorState? navigator,
  ) async {
    if (navigator == null) return [];

    try {
      return await _navValidator.validateAllRoutes(navigator);
    } catch (e) {
      return [
        RouteTestResult(
          route: '*',
          reachable: false,
          rendersWithoutError: false,
          error: 'Route validation failed: $e',
        ),
      ];
    }
  }
}
