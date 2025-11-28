import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/presentation/widgets/level_cell/level_cell_widget.dart';
import 'package:honeycomb_one_pass/presentation/theme/honey_theme.dart';

void main() {
  group('LevelCellWidget', () {
    Widget createTestWidget({
      required int levelNumber,
      int stars = 0,
      bool isUnlocked = true,
      bool isCompleted = false,
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
      testWidgets('displays 0 filled stars when stars is 0', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 0, isUnlocked: true),
        );

        final starIcons = find.byIcon(Icons.star);
        final emptyStarIcons = find.byIcon(Icons.star_border);

        expect(starIcons, findsNothing);
        expect(emptyStarIcons, findsNWidgets(3));
      });

      testWidgets('displays 1 filled star when stars is 1', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 1, isUnlocked: true),
        );

        final starIcons = find.byIcon(Icons.star);
        final emptyStarIcons = find.byIcon(Icons.star_border);

        expect(starIcons, findsOneWidget);
        expect(emptyStarIcons, findsNWidgets(2));
      });

      testWidgets('displays 2 filled stars when stars is 2', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 2, isUnlocked: true),
        );

        final starIcons = find.byIcon(Icons.star);
        final emptyStarIcons = find.byIcon(Icons.star_border);

        expect(starIcons, findsNWidgets(2));
        expect(emptyStarIcons, findsOneWidget);
      });

      testWidgets('displays 3 filled stars when stars is 3', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 3, isUnlocked: true),
        );

        final starIcons = find.byIcon(Icons.star);
        final emptyStarIcons = find.byIcon(Icons.star_border);

        expect(starIcons, findsNWidgets(3));
        expect(emptyStarIcons, findsNothing);
      });

      testWidgets('filled stars have correct color', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 2, isUnlocked: true),
        );

        final starIcon = tester.widget<Icon>(find.byIcon(Icons.star).first);
        expect(starIcon.color, equals(HoneyTheme.starFilled));
      });

      testWidgets('empty stars have correct color', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 1, isUnlocked: true),
        );

        final emptyIcon = tester.widget<Icon>(
          find.byIcon(Icons.star_border).first,
        );
        expect(emptyIcon.color, equals(HoneyTheme.starEmpty));
      });

      testWidgets('does not display stars for locked level', (tester) async {
        await tester.pumpWidget(
          createTestWidget(levelNumber: 1, stars: 0, isUnlocked: false),
        );

        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.byIcon(Icons.star_border), findsNothing);
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

        final completedContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Container),
              )
              .first,
        );
        final completedDecoration =
            completedContainer.decoration as BoxDecoration;
        final completedColor = completedDecoration.color;

        // Create uncompleted widget
        await tester.pumpWidget(
          createTestWidget(
            levelNumber: 1,
            isUnlocked: true,
            isCompleted: false,
            stars: 0,
          ),
        );

        final uncompletedContainer = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(LevelCellWidget),
                matching: find.byType(Container),
              )
              .first,
        );
        final uncompletedDecoration =
            uncompletedContainer.decoration as BoxDecoration;
        final uncompletedColor = uncompletedDecoration.color;

        // Colors should be different
        expect(completedColor, isNot(equals(uncompletedColor)));
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
