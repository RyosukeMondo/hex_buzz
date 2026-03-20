// Data models for the diagnostic system.
//
// Defines issues, reports, and results used across the
// widget inspector, screen analyzer, accessibility auditor,
// and navigation validator.

/// A detected layout issue in the widget tree.
class LayoutIssue {
  final String type;
  final String widgetType;
  final String details;
  final Map<String, dynamic> location;

  const LayoutIssue({
    required this.type,
    required this.widgetType,
    required this.details,
    this.location = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'widgetType': widgetType,
        'details': details,
        'location': location,
      };
}

/// Layout issue type constants.
class LayoutIssueType {
  static const String overflow = 'overflow';
  static const String offscreen = 'offscreen';
  static const String zeroSize = 'zero_size';
  static const String unbounded = 'unbounded';
  static const String textOverflow = 'text_overflow';

  LayoutIssueType._();
}

/// An accessibility issue detected during audit.
class AccessibilityIssue {
  final String type;
  final String widgetType;
  final String details;
  final String severity;
  final Map<String, dynamic> location;

  const AccessibilityIssue({
    required this.type,
    required this.widgetType,
    required this.details,
    this.severity = 'warning',
    this.location = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'widgetType': widgetType,
        'details': details,
        'severity': severity,
        'location': location,
      };
}

/// Accessibility issue type constants.
class AccessibilityIssueType {
  static const String missingLabel = 'missing_semantic_label';
  static const String lowContrast = 'low_contrast';
  static const String smallTouchTarget = 'small_touch_target';

  AccessibilityIssueType._();
}

/// Result from testing a single route.
class RouteTestResult {
  final String route;
  final bool reachable;
  final bool rendersWithoutError;
  final String? error;

  const RouteTestResult({
    required this.route,
    required this.reachable,
    required this.rendersWithoutError,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'route': route,
        'reachable': reachable,
        'rendersWithoutError': rendersWithoutError,
        if (error != null) 'error': error,
      };
}

/// A validation error when screen state doesn't match expectations.
class ValidationError {
  final String field;
  final String expected;
  final String actual;

  const ValidationError({
    required this.field,
    required this.expected,
    required this.actual,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'expected': expected,
        'actual': actual,
      };
}

/// Comprehensive diagnostic report from a full scan.
class DiagnosticReport {
  final List<LayoutIssue> layoutIssues;
  final List<AccessibilityIssue> accessibilityIssues;
  final Map<String, dynamic> screenStates;
  final List<RouteTestResult> routeResults;
  final DateTime timestamp;

  DiagnosticReport({
    required this.layoutIssues,
    required this.accessibilityIssues,
    required this.screenStates,
    required this.routeResults,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Total count of all detected issues.
  int get totalIssues =>
      layoutIssues.length + accessibilityIssues.length + _routeErrors;

  /// Count of critical issues (overflow, render errors).
  int get criticalIssues => _criticalLayoutCount + _routeErrors;

  int get _criticalLayoutCount => layoutIssues
      .where((i) =>
          i.type == LayoutIssueType.overflow ||
          i.type == LayoutIssueType.unbounded)
      .length;

  int get _routeErrors =>
      routeResults.where((r) => !r.rendersWithoutError).length;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'summary': {
          'totalIssues': totalIssues,
          'criticalIssues': criticalIssues,
          'layoutIssueCount': layoutIssues.length,
          'accessibilityIssueCount': accessibilityIssues.length,
          'routeErrorCount': _routeErrors,
        },
        'layoutIssues': layoutIssues.map((i) => i.toJson()).toList(),
        'accessibilityIssues':
            accessibilityIssues.map((i) => i.toJson()).toList(),
        'screenStates': screenStates,
        'routeResults': routeResults.map((r) => r.toJson()).toList(),
      };

  /// Formats the report for human reading.
  String toHumanReadable() {
    final buffer = StringBuffer();
    buffer.writeln('=== Diagnostic Report ===');
    buffer.writeln('Time: ${timestamp.toIso8601String()}');
    buffer.writeln('Total issues: $totalIssues');
    buffer.writeln('Critical issues: $criticalIssues');
    buffer.writeln();

    if (layoutIssues.isNotEmpty) {
      buffer.writeln('--- Layout Issues (${layoutIssues.length}) ---');
      for (final issue in layoutIssues) {
        buffer.writeln(
            '  [${issue.type}] ${issue.widgetType}: ${issue.details}');
      }
      buffer.writeln();
    }

    if (accessibilityIssues.isNotEmpty) {
      buffer.writeln(
          '--- Accessibility Issues (${accessibilityIssues.length}) ---');
      for (final issue in accessibilityIssues) {
        buffer.writeln(
            '  [${issue.severity}] ${issue.widgetType}: ${issue.details}');
      }
      buffer.writeln();
    }

    if (routeResults.isNotEmpty) {
      buffer.writeln('--- Route Results (${routeResults.length}) ---');
      for (final result in routeResults) {
        final status = result.rendersWithoutError ? 'OK' : 'FAIL';
        buffer.writeln('  [$status] ${result.route}');
        if (result.error != null) {
          buffer.writeln('    Error: ${result.error}');
        }
      }
    }

    return buffer.toString();
  }
}
