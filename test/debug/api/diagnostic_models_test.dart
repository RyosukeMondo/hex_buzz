import 'package:flutter_test/flutter_test.dart';

import 'package:hex_buzz/debug/api/models/diagnostic_models.dart';

void main() {
  group('LayoutIssue', () {
    test('toJson includes all fields', () {
      const issue = LayoutIssue(
        type: LayoutIssueType.overflow,
        widgetType: 'Column',
        details: 'Overflow by 20px',
        location: {'x': 0, 'y': 100},
      );

      final json = issue.toJson();
      expect(json['type'], 'overflow');
      expect(json['widgetType'], 'Column');
      expect(json['details'], 'Overflow by 20px');
      expect(json['location'], {'x': 0, 'y': 100});
    });

    test('toJson includes empty location by default', () {
      const issue = LayoutIssue(
        type: LayoutIssueType.zeroSize,
        widgetType: 'Container',
        details: 'zero size',
      );

      final json = issue.toJson();
      expect(json['location'], isEmpty);
    });
  });

  group('AccessibilityIssue', () {
    test('toJson includes severity', () {
      const issue = AccessibilityIssue(
        type: AccessibilityIssueType.lowContrast,
        widgetType: 'Text',
        details: 'Ratio 2.1:1',
        severity: 'error',
      );

      final json = issue.toJson();
      expect(json['type'], 'low_contrast');
      expect(json['severity'], 'error');
    });

    test('defaults to warning severity', () {
      const issue = AccessibilityIssue(
        type: AccessibilityIssueType.missingLabel,
        widgetType: 'Button',
        details: 'no label',
      );

      expect(issue.severity, 'warning');
    });
  });

  group('RouteTestResult', () {
    test('toJson includes error when present', () {
      const result = RouteTestResult(
        route: '/settings',
        reachable: false,
        rendersWithoutError: false,
        error: 'Route not found',
      );

      final json = result.toJson();
      expect(json['route'], '/settings');
      expect(json['reachable'], isFalse);
      expect(json['error'], 'Route not found');
    });

    test('toJson omits error when null', () {
      const result = RouteTestResult(
        route: '/',
        reachable: true,
        rendersWithoutError: true,
      );

      final json = result.toJson();
      expect(json.containsKey('error'), isFalse);
    });
  });

  group('ValidationError', () {
    test('toJson includes all fields', () {
      const error = ValidationError(
        field: 'route',
        expected: '/home',
        actual: '/login',
      );

      final json = error.toJson();
      expect(json['field'], 'route');
      expect(json['expected'], '/home');
      expect(json['actual'], '/login');
    });
  });

  group('DiagnosticReport', () {
    test('calculates totalIssues correctly', () {
      final report = DiagnosticReport(
        layoutIssues: const [
          LayoutIssue(
            type: LayoutIssueType.overflow,
            widgetType: 'Column',
            details: 'overflow',
          ),
          LayoutIssue(
            type: LayoutIssueType.zeroSize,
            widgetType: 'Container',
            details: 'zero size',
          ),
        ],
        accessibilityIssues: const [
          AccessibilityIssue(
            type: AccessibilityIssueType.missingLabel,
            widgetType: 'Button',
            details: 'missing label',
          ),
        ],
        screenStates: const {},
        routeResults: const [
          RouteTestResult(
            route: '/',
            reachable: true,
            rendersWithoutError: true,
          ),
          RouteTestResult(
            route: '/broken',
            reachable: false,
            rendersWithoutError: false,
            error: 'not found',
          ),
        ],
      );

      // 2 layout + 1 accessibility + 1 route error = 4
      expect(report.totalIssues, 4);
      // 1 overflow (critical layout) + 1 route error = 2
      expect(report.criticalIssues, 2);
    });

    test('toJson produces valid structure', () {
      final report = DiagnosticReport(
        layoutIssues: const [],
        accessibilityIssues: const [],
        screenStates: const {'route': '/'},
        routeResults: const [],
      );

      final json = report.toJson();
      expect(json.containsKey('timestamp'), isTrue);
      expect(json.containsKey('summary'), isTrue);
      expect(json['summary']['totalIssues'], 0);
      expect(json['summary']['criticalIssues'], 0);
    });

    test('toHumanReadable contains report header', () {
      final report = DiagnosticReport(
        layoutIssues: const [
          LayoutIssue(
            type: LayoutIssueType.overflow,
            widgetType: 'Row',
            details: 'overflow detected',
          ),
        ],
        accessibilityIssues: const [],
        screenStates: const {},
        routeResults: const [],
      );

      final readable = report.toHumanReadable();
      expect(readable, contains('Diagnostic Report'));
      expect(readable, contains('Total issues:'));
      expect(readable, contains('Layout Issues'));
    });

    test('empty report produces clean output', () {
      final report = DiagnosticReport(
        layoutIssues: const [],
        accessibilityIssues: const [],
        screenStates: const {},
        routeResults: const [],
      );

      expect(report.totalIssues, 0);
      expect(report.criticalIssues, 0);

      final readable = report.toHumanReadable();
      expect(readable, contains('Total issues: 0'));
    });
  });
}
