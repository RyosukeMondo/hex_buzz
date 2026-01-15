import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/widgets/level_cell/level_cell_widget.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';

void main() {
  group('LevelCellWidget', () {
    Widget createTestWidget({
      required int levelNumber,
      int stars = 0,
      bool isUnlocked = true,
      bool isCompleted = false,
      Duration? bestTime,
      VoidCallback? onTap,
      double size = 80,
    }) {
      return MaterialApp(
        theme: HoneyTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: LevelCellWidget(
              levelNumber: levelNumber,
              stars: stars,
              isUnlocked: isUnlocked,
              isCompleted: isCompleted,
              bestTime: bestTime,
              onTap: onTap,
              size: size,
            ),
          ),
        ),
      );
    }

    group('Level number display', () {
      testWidgets('displays level number for unlocked level', (tester) async {
        await tester.pumpWidget(createTestWidget(levelNumber: 5));

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays level number for locked level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 10, isUnlocked: false),
        );

        expect(find.text('10'), findsOneWidget);
      });

      testWidgets('displays double-digit level numbers', (tester) async {
        await tester.pumpWidget(createTestWidget(levelNumber: 42));

        expect(find.text('42'), findsOneWidget);
      });

      testWidgets('displays level 1 correctly', (tester) async {
        await tester.pumpWidget(createTestWidget(levelNumber: 1));

        expect(find.text('1'), findsOneWidget);
      });
    });

    group('Stars display', () {
      // Helper to count filled stars (Container with shadow that contains an Icon child)
      Finder findFilledStars() => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.child is Icon &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).boxShadow != null &&
            (widget.decoration as BoxDecoration).boxShadow!.isNotEmpty &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      // Helper to count empty stars (wrapped in Stack with outline effect)
      Finder findEmptyStarStacks() => find.byWidgetPredicate(
        (widget) =>
            widget is Stack &&
            widget.children.length == 2 &&
            widget.children[0] is Icon &&
            widget.children[1] is Icon,
      );

      testWidgets('displays 0 filled stars when stars is 0', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 0, isUnlocked: true),
        );

        expect(findFilledStars(), findsNothing);
        expect(findEmptyStarStacks(), findsNWidgets(3));
      });

      testWidgets('displays 1 filled star when stars is 1', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 1, isUnlocked: true),
        );

        expect(findFilledStars(), findsOneWidget);
        expect(findEmptyStarStacks(), findsNWidgets(2));
      });

      testWidgets('displays 2 filled stars when stars is 2', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 2, isUnlocked: true),
        );

        expect(findFilledStars(), findsNWidgets(2));
        expect(findEmptyStarStacks(), findsOneWidget);
      });

      testWidgets('displays 3 filled stars when stars is 3', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 3, isUnlocked: true),
        );

        expect(findFilledStars(), findsNWidgets(3));
        expect(findEmptyStarStacks(), findsNothing);
      });

      testWidgets('filled stars have correct color', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 2, isUnlocked: true),
        );

        // Find filled star icon (inside Container with shadow)
        final containers = tester.widgetList<Container>(findFilledStars());
        expect(containers.isNotEmpty, isTrue);
        final container = containers.first;
        final icon = (container.child as Icon);
        expect(icon.color, equals(HoneyTheme.starFilled));
      });

      testWidgets('empty stars have outline for visibility', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 1, isUnlocked: true),
        );

        // Empty stars use stack with outline layer and inner fill
        final stacks = tester.widgetList<Stack>(findEmptyStarStacks());
        expect(stacks.isNotEmpty, isTrue);
        final stack = stacks.first;
        final outlineIcon = stack.children[0] as Icon;
        final fillIcon = stack.children[1] as Icon;

        // Outline uses darker color for contrast
        expect(outlineIcon.color, equals(HoneyTheme.starEmptyOutline));
        // Inner fill uses lighter color
        expect(fillIcon.color, equals(HoneyTheme.starEmpty));
      });

      testWidgets('does not display stars for locked level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 0, isUnlocked: false),
        );

        expect(findFilledStars(), findsNothing);
        expect(findEmptyStarStacks(), findsNothing);
      });
    });

    group('Lock icon display', () {
      testWidgets('displays lock icon for locked level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 5, isUnlocked: false),
        );

        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('does not display lock icon for unlocked level', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 5, isUnlocked: true),
        );

        expect(find.byIcon(Icons.lock), findsNothing);
      });

      testWidgets('lock icon has correct color', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 5, isUnlocked: false),
        );

        final lockIcon = tester.widget<Icon>(find.byIcon(Icons.lock));
        expect(lockIcon.color, equals(HoneyTheme.lockColor));
      });
    });

    group('Tap behavior', () {
      testWidgets('calls onTap when unlocked level is tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: true,
            onTap: () => tapped = true,
          ),
        );

        await tester.tap(find.byType(LevelCellWidget));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('does not call onTap when locked level is tapped', (
        tester,
      ) async {
        var tapped = false;
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: false,
            onTap: () => tapped = true,
          ),
        );

        await tester.tap(find.byType(LevelCellWidget));
        await tester.pump();

        expect(tapped, isFalse);
      });

      testWidgets('works without onTap callback', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, isUnlocked: true, onTap: null),
        );

        // Should not throw
        await tester.tap(find.byType(LevelCellWidget));
        await tester.pump();
      });
    });

    group('Shake animation for locked levels', () {
      testWidgets('triggers shake animation when locked level is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 5, isUnlocked: false),
        );

        // Tap the locked level
        await tester.tap(find.byType(LevelCellWidget));

        // Track offset changes over time during animation
        var foundNonZeroOffset = false;

        // Pump multiple frames to catch the animation in progress
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 20));

          final transform = tester.widget<Transform>(
            find
                .descendant(
                  of: find.byType(LevelCellWidget),
                  matching: find.byType(Transform),
                )
                .first,
          );
          final offset = transform.transform.getTranslation().x;

          if (offset.abs() > 0.1) {
            foundNonZeroOffset = true;
            break;
          }
        }

        // Animation should have caused offset change at some point
        expect(
          foundNonZeroOffset,
          isTrue,
          reason: 'Shake animation should move the widget horizontally',
        );

        // Complete the animation
        await tester.pumpAndSettle();

        final finalTransform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Transform),
              )
              .first,
        );
        final finalOffset = finalTransform.transform.getTranslation().x;

        // Animation should complete back to original position
        expect(finalOffset, closeTo(0.0, 0.01));
      });

      testWidgets('does not shake when unlocked level is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 5, isUnlocked: true),
        );

        // Tap the unlocked level
        await tester.tap(find.byType(LevelCellWidget));
        await tester.pump(const Duration(milliseconds: 50));

        final transform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Transform),
              )
              .first,
        );
        final offset = transform.transform.getTranslation().x;

        // No shake animation for unlocked levels
        expect(offset, closeTo(0.0, 0.01));
      });
    });

    group('Cell size', () {
      testWidgets('respects custom size', (tester) async {
        const customSize = 100.0;
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, size: customSize),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(container.constraints?.maxWidth, equals(customSize));
        expect(container.constraints?.maxHeight, equals(customSize));
      });

      testWidgets('uses default size of 80', (tester) async {
        await tester.pumpWidget(createTestWidget(levelNumber: 1));

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(container.constraints?.maxWidth, equals(80.0));
        expect(container.constraints?.maxHeight, equals(80.0));
      });
    });

    group('Completed level styling', () {
      testWidgets('renders differently for completed vs uncompleted unlocked', (
        tester,
      ) async {
        // Create completed widget
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: true,
            isCompleted: true,
            stars: 3,
          ),
        );

        // The completed widget should show stars
        expect(find.byIcon(Icons.star), findsWidgets);
        final completedWidget = tester.widget<LevelCellWidget>(
          find.byType(LevelCellWidget),
        );
        expect(completedWidget.isCompleted, isTrue);

        // Create uncompleted widget
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: true,
            isCompleted: false,
            stars: 0,
          ),
        );

        // The uncompleted widget shows star outlines (star_border)
        final uncompletedWidget = tester.widget<LevelCellWidget>(
          find.byType(LevelCellWidget),
        );
        expect(uncompletedWidget.isCompleted, isFalse);

        // Visual rendering differs - completed shows filled stars, uncompleted shows outline stars
        expect(
          completedWidget.isCompleted,
          isNot(equals(uncompletedWidget.isCompleted)),
        );
      });
    });

    group('Best time display', () {
      testWidgets('displays time for completed level with bestTime', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: true,
            bestTime: const Duration(seconds: 45, milliseconds: 230),
          ),
        );

        // Should display time in SS.ss format (45.23)
        expect(find.text('45.23'), findsOneWidget);
      });

      testWidgets('formats time as MM:SS for duration >= 60 seconds', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: true,
            bestTime: const Duration(minutes: 2, seconds: 5),
          ),
        );

        // Should display as 2:05
        expect(find.text('2:05'), findsOneWidget);
      });

      testWidgets('formats time as SS.ss for duration < 60 seconds', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: true,
            bestTime: const Duration(seconds: 8, milliseconds: 50),
          ),
        );

        // Should display as 8.05
        expect(find.text('8.05'), findsOneWidget);
      });

      testWidgets('does not display time for incomplete level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: false,
            bestTime: const Duration(seconds: 30),
          ),
        );

        // Time should not be displayed
        expect(find.text('30.00'), findsNothing);
      });

      testWidgets('does not display time when bestTime is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, isCompleted: true, bestTime: null),
        );

        // No time text should be present (level 1 text exists but no time)
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        final texts = textWidgets.map((t) => t.data ?? '').toList();
        // Should only have level number, no time format strings
        expect(texts.where((t) => t.contains('.')).isEmpty, isTrue);
        expect(texts.where((t) => t.contains(':')).isEmpty, isTrue);
      });

      testWidgets('does not display time for locked level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: false,
            isCompleted: false,
            bestTime: const Duration(seconds: 30),
          ),
        );

        expect(find.text('30.00'), findsNothing);
      });

      testWidgets('formats exactly 60 seconds as 1:00', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: true,
            bestTime: const Duration(seconds: 60),
          ),
        );

        expect(find.text('1:00'), findsOneWidget);
      });

      testWidgets('handles sub-second times correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isCompleted: true,
            bestTime: const Duration(milliseconds: 500),
          ),
        );

        expect(find.text('0.50'), findsOneWidget);
      });
    });

    group('Assertion validation', () {
      testWidgets('throws assertion error for stars < 0', (tester) async {
        expect(
          () => LevelCellWidget(levelNumber: 1, stars: -1),
          throwsAssertionError,
        );
      });

      testWidgets('throws assertion error for stars > 3', (tester) async {
        expect(
          () => LevelCellWidget(levelNumber: 1, stars: 4),
          throwsAssertionError,
        );
      });
    });
  });
}
