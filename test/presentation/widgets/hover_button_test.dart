import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/widgets/hover_button.dart';

void main() {
  group('HoverButton', () {
    testWidgets('renders child correctly', (tester) async {
      const testText = 'Test Button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverButton(onPressed: () {}, child: const Text(testText)),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('has MouseRegion for hover detection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverButton(onPressed: () {}, child: const Text('Button')),
          ),
        ),
      );

      // Verify MouseRegion exists for hover detection
      expect(find.byType(MouseRegion), findsWidgets);
    });

    testWidgets('respects enabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverButton(onPressed: null, child: const Text('Button')),
          ),
        ),
      );

      // Verify widget is created even when disabled
      expect(find.byType(HoverButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverButton(
              onPressed: () => tapped = true,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HoverButton));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('HoverTextButton', () {
    testWidgets('renders child correctly', (tester) async {
      const testText = 'Text Button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverTextButton(
              onPressed: () {},
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverTextButton(
              onPressed: () => tapped = true,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HoverTextButton));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('HoverIconButton', () {
    testWidgets('renders icon correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverIconButton(icon: Icons.star, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      const tooltipText = 'Star Button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverIconButton(
              icon: Icons.star,
              onPressed: () {},
              tooltip: tooltipText,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoverIconButton(
              icon: Icons.star,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HoverIconButton));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });
}
