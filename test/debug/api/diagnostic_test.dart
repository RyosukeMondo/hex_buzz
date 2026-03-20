import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hex_buzz/debug/api/accessibility_auditor.dart';
import 'package:hex_buzz/debug/api/models/diagnostic_models.dart';
import 'package:hex_buzz/debug/api/navigation_validator.dart';
import 'package:hex_buzz/debug/api/screen_analyzer.dart';
import 'package:hex_buzz/debug/api/widget_inspector.dart';
import 'package:hex_buzz/debug/cli/diagnostic_runner.dart';

void main() {
  group('WidgetTreeInspector', () {
    late WidgetTreeInspector inspector;

    setUp(() {
      inspector = WidgetTreeInspector();
    });

    testWidgets('captureWidgetTree returns tree with type and depth',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Hello'),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final tree = inspector.captureWidgetTree(context, maxDepth: 5);

      expect(tree['type'], 'MaterialApp');
      expect(tree['depth'], 0);
      expect(tree.containsKey('children'), isTrue);
    });

    testWidgets('findWidgets locates widgets by type name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Text('First'),
                Text('Second'),
                Text('Third'),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final results = inspector.findWidgets(context, 'Text');

      // Should find at least the 3 Text widgets we created
      expect(results.length, greaterThanOrEqualTo(3));
      for (final result in results) {
        expect(result['type'], 'Text');
        expect(result.containsKey('depth'), isTrue);
      }
    });

    testWidgets('detectLayoutIssues finds zero-size widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Visible'),
                // SizedBox with zero size is intentionally ignored
                // but a Container with zero size should be detected
                // ignore: sized_box_for_whitespace
                Container(width: 0, height: 0),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final issues = inspector.detectLayoutIssues(context);

      // Should detect the zero-size Container
      final zeroSizeIssues = issues
          .where((i) => i.type == LayoutIssueType.zeroSize)
          .toList();
      expect(zeroSizeIssues, isNotEmpty);
    });

    testWidgets('getCurrentRoute returns current route name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/test',
          routes: {
            '/test': (_) => const Scaffold(body: Text('Test')),
          },
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final route = inspector.getCurrentRoute(context);

      expect(route, '/test');
    });

    testWidgets('getRegisteredRoutes returns known routes', (tester) async {
      final routes = inspector.getRegisteredRoutes();

      expect(routes, contains('/'));
      expect(routes, contains('/auth'));
      expect(routes, contains('/levels'));
      expect(routes, contains('/game'));
      expect(routes, contains('/daily-challenge'));
      expect(routes, contains('/leaderboard'));
    });
  });

  group('ScreenAnalyzer', () {
    late ScreenAnalyzer analyzer;

    setUp(() {
      analyzer = ScreenAnalyzer();
    });

    testWidgets('captureVisibleText finds all text on screen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Hello World'),
                Text('Another Text'),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final texts = analyzer.captureVisibleText(context);

      expect(texts, contains('Hello World'));
      expect(texts, contains('Another Text'));
    });

    testWidgets('captureTappableElements finds buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Click Me'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Another'),
                ),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final tappable = analyzer.captureTappableElements(context);

      // Should find at least the 2 buttons
      final buttons = tappable
          .where((t) =>
              t['type'] == 'ElevatedButton' || t['type'] == 'TextButton')
          .toList();
      expect(buttons.length, greaterThanOrEqualTo(2));
    });

    testWidgets('validateScreen detects missing text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Hello')),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final errors = analyzer.validateScreen(context, {
        'visibleTexts': ['Hello', 'Missing Text'],
      });

      expect(errors.length, 1);
      expect(errors[0].field, 'visibleText');
      expect(errors[0].expected, 'Missing Text');
    });

    testWidgets('validateScreen passes when all texts present',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Alpha'),
                Text('Beta'),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      final errors = analyzer.validateScreen(context, {
        'visibleTexts': ['Alpha', 'Beta'],
      });

      expect(errors, isEmpty);
    });
  });

  group('AccessibilityAuditor', () {
    late AccessibilityAuditor auditor;

    setUp(() {
      auditor = AccessibilityAuditor();
    });

    testWidgets('auditSemantics detects buttons without labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: Container(width: 50, height: 50, color: Colors.red),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final issues = auditor.auditSemantics(context);

      // GestureDetector without text child should be flagged
      final missingLabels = issues
          .where((i) => i.type == AccessibilityIssueType.missingLabel)
          .toList();
      expect(missingLabels, isNotEmpty);
    });

    testWidgets('auditSemantics passes for labeled buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final issues = auditor.auditSemantics(context);

      // ElevatedButton with Text child should pass
      final buttonIssues = issues
          .where((i) =>
              i.type == AccessibilityIssueType.missingLabel &&
              i.widgetType == 'ElevatedButton')
          .toList();
      expect(buttonIssues, isEmpty);
    });

    testWidgets('auditTouchTargets detects small targets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final issues = auditor.auditTouchTargets(context);

      final smallTargets = issues
          .where((i) => i.type == AccessibilityIssueType.smallTouchTarget)
          .toList();
      expect(smallTargets, isNotEmpty);
    });

    testWidgets('auditContrast detects low contrast text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              color: Colors.white,
              child: const Text(
                'Hard to read',
                style: TextStyle(color: Color(0xFFDDDDDD)),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final issues = auditor.auditContrast(context);

      final contrastIssues = issues
          .where((i) => i.type == AccessibilityIssueType.lowContrast)
          .toList();
      expect(contrastIssues, isNotEmpty);
    });
  });

  group('NavigationValidator', () {
    late NavigationValidator validator;

    setUp(() {
      validator = NavigationValidator();
    });

    testWidgets('validateAllRoutes returns results for all known routes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator));
      final results = await validator.validateAllRoutes(navigator);

      expect(results, isNotEmpty);
      expect(results.length, 6); // All known routes
      for (final result in results) {
        expect(result.route, isNotEmpty);
      }
    });

    testWidgets('getCurrentStack returns current route stack',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/test',
          routes: {
            '/test': (_) => const Scaffold(body: Text('Test')),
          },
        ),
      );

      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator));
      final stack = validator.getCurrentStack(navigator);

      expect(stack, contains('/test'));
    });

    test('findOrphanedRoutes returns empty list', () {
      final orphaned = validator.findOrphanedRoutes();
      expect(orphaned, isEmpty);
    });
  });

  group('DiagnosticRunner', () {
    testWidgets('runFullDiagnostic produces report with all sections',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Test App'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Action'),
                ),
                // Intentional issue: zero-size container
                // ignore: sized_box_for_whitespace
                Container(width: 0, height: 0),
                // Intentional issue: small touch target
                GestureDetector(
                  onTap: () {},
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final runner = DiagnosticRunner();
      final report = await runner.runFullDiagnostic(context);

      // Report should contain results
      expect(report.layoutIssues, isA<List<LayoutIssue>>());
      expect(report.accessibilityIssues, isA<List<AccessibilityIssue>>());
      expect(report.screenStates, isA<Map<String, dynamic>>());
      expect(report.routeResults, isA<List<RouteTestResult>>());

      // Should detect at least some issues from intentional problems
      expect(report.totalIssues, greaterThan(0));
    });

    testWidgets('report toJson produces valid structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Simple')),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final runner = DiagnosticRunner();
      final report = await runner.runFullDiagnostic(context);
      final json = report.toJson();

      expect(json.containsKey('timestamp'), isTrue);
      expect(json.containsKey('summary'), isTrue);
      expect(json.containsKey('layoutIssues'), isTrue);
      expect(json.containsKey('accessibilityIssues'), isTrue);
      expect(json.containsKey('screenStates'), isTrue);
      expect(json.containsKey('routeResults'), isTrue);

      final summary = json['summary'] as Map<String, dynamic>;
      expect(summary.containsKey('totalIssues'), isTrue);
      expect(summary.containsKey('criticalIssues'), isTrue);
    });

    testWidgets('report toHumanReadable produces readable output',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Test')),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final runner = DiagnosticRunner();
      final report = await runner.runFullDiagnostic(context);
      final readable = report.toHumanReadable();

      expect(readable, contains('Diagnostic Report'));
      expect(readable, contains('Total issues:'));
      expect(readable, contains('Critical issues:'));
    });
  });

}
