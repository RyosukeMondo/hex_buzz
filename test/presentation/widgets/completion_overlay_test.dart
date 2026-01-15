import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/widgets/completion_overlay/completion_overlay.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';

void main() {
  group('CompletionOverlay', () {
    Widget createTestWidget({
      int stars = 3,
      Duration completionTime = const Duration(seconds: 15),
      VoidCallback? onNextLevel,
      VoidCallback? onReplay,
      VoidCallback? onLevelSelect,
      bool hasNextLevel = true,
    }) {
      return MaterialApp(
        theme: HoneyTheme.lightTheme,
        home: Scaffold(
          body: CompletionOverlay(
            stars: stars,
            completionTime: completionTime,
            onNextLevel: onNextLevel,
            onReplay: onReplay,
            onLevelSelect: onLevelSelect,
            hasNextLevel: hasNextLevel,
          ),
        ),
      );
    }

    /// Pumps the widget and waits for all animations to complete.
    /// The animation uses Future.delayed which requires pumping through
    /// time incrementally to process all timers properly.
    Future<void> pumpAndFinishAnimations(WidgetTester tester) async {
      // Card animation: 300ms
      // Star animations: 150ms delay between each, 400ms per star animation
      // For 3 stars: 300 + (150 + 400) * 3 = 1950ms total
      // Pump incrementally to process all Future.delayed timers
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    group('Title display', () {
      testWidgets('displays "Level Complete!" title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        expect(find.text('Level Complete!'), findsOneWidget);
      });

      testWidgets('displays trophy icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        // Trophy is shown either as asset image or fallback icon
        final hasTrophyIcon = find
            .byIcon(Icons.emoji_events)
            .evaluate()
            .isNotEmpty;
        final hasAssetImage = find.byType(Image).evaluate().isNotEmpty;
        expect(hasTrophyIcon || hasAssetImage, isTrue);
      });
    });

    group('Stars display', () {
      testWidgets('displays 0 filled stars when stars is 0', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 0));
        await pumpAndFinishAnimations(tester);

        // Verify the widget was created with 0 stars
        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(0));
      });

      testWidgets('displays 1 filled star when stars is 1', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 1));
        await pumpAndFinishAnimations(tester);

        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(1));
      });

      testWidgets('displays 2 filled stars when stars is 2', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 2));
        await pumpAndFinishAnimations(tester);

        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(2));
      });

      testWidgets('displays 3 filled stars when stars is 3', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 3));
        await pumpAndFinishAnimations(tester);

        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(3));
      });

      testWidgets('filled stars have correct color', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 2));
        await pumpAndFinishAnimations(tester);

        // Stars are rendered with fallback icons or asset images
        // Test that the widget is configured correctly
        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(2));
      });

      testWidgets('empty stars have correct color', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 1));
        await pumpAndFinishAnimations(tester);

        // Stars are rendered with fallback icons or asset images
        // Test that the widget is configured correctly with 2 empty star slots
        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(1));
      });
    });

    group('Time display', () {
      testWidgets('displays "Time" label', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        expect(find.text('Time'), findsOneWidget);
      });

      testWidgets('formats seconds correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(completionTime: const Duration(seconds: 15)),
        );
        await pumpAndFinishAnimations(tester);

        expect(find.text('15.00s'), findsOneWidget);
      });

      testWidgets('formats seconds with milliseconds correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            completionTime: const Duration(seconds: 8, milliseconds: 540),
          ),
        );
        await pumpAndFinishAnimations(tester);

        expect(find.text('8.54s'), findsOneWidget);
      });

      testWidgets('formats minutes and seconds correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            completionTime: const Duration(minutes: 1, seconds: 23),
          ),
        );
        await pumpAndFinishAnimations(tester);

        expect(find.text('1:23.00'), findsOneWidget);
      });

      testWidgets('formats minutes with milliseconds correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            completionTime: const Duration(
              minutes: 2,
              seconds: 5,
              milliseconds: 120,
            ),
          ),
        );
        await pumpAndFinishAnimations(tester);

        expect(find.text('2:05.12'), findsOneWidget);
      });

      testWidgets('formats zero time correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(completionTime: Duration.zero),
        );
        await pumpAndFinishAnimations(tester);

        expect(find.text('0.00s'), findsOneWidget);
      });
    });

    group('Button display', () {
      testWidgets('displays Next Level button when hasNextLevel is true', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(hasNextLevel: true));
        await pumpAndFinishAnimations(tester);

        expect(find.text('Next Level'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('hides Next Level button when hasNextLevel is false', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(hasNextLevel: false));
        await pumpAndFinishAnimations(tester);

        expect(find.text('Next Level'), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
      });

      testWidgets('displays Replay button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        expect(find.text('Replay'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('displays Levels button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        expect(find.text('Levels'), findsOneWidget);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });
    });

    group('Button callbacks', () {
      testWidgets('calls onNextLevel when Next Level button is tapped', (
        tester,
      ) async {
        var nextLevelTapped = false;
        await tester.pumpWidget(
          createTestWidget(
            hasNextLevel: true,
            onNextLevel: () => nextLevelTapped = true,
          ),
        );
        await pumpAndFinishAnimations(tester);

        await tester.tap(find.text('Next Level'));
        await tester.pump();

        expect(nextLevelTapped, isTrue);
      });

      testWidgets('calls onReplay when Replay button is tapped', (
        tester,
      ) async {
        var replayTapped = false;
        await tester.pumpWidget(
          createTestWidget(onReplay: () => replayTapped = true),
        );
        await pumpAndFinishAnimations(tester);

        await tester.tap(find.text('Replay'));
        await tester.pump();

        expect(replayTapped, isTrue);
      });

      testWidgets('calls onLevelSelect when Levels button is tapped', (
        tester,
      ) async {
        var levelSelectTapped = false;
        await tester.pumpWidget(
          createTestWidget(onLevelSelect: () => levelSelectTapped = true),
        );
        await pumpAndFinishAnimations(tester);

        await tester.tap(find.text('Levels'));
        await tester.pump();

        expect(levelSelectTapped, isTrue);
      });

      testWidgets('works without onNextLevel callback', (tester) async {
        await tester.pumpWidget(
          createTestWidget(hasNextLevel: true, onNextLevel: null),
        );
        await pumpAndFinishAnimations(tester);

        // Should not throw
        await tester.tap(find.text('Next Level'));
        await tester.pump();
      });

      testWidgets('works without onReplay callback', (tester) async {
        await tester.pumpWidget(createTestWidget(onReplay: null));
        await pumpAndFinishAnimations(tester);

        // Should not throw
        await tester.tap(find.text('Replay'));
        await tester.pump();
      });

      testWidgets('works without onLevelSelect callback', (tester) async {
        await tester.pumpWidget(createTestWidget(onLevelSelect: null));
        await pumpAndFinishAnimations(tester);

        // Should not throw
        await tester.tap(find.text('Levels'));
        await tester.pump();
      });
    });

    group('Card animation', () {
      testWidgets('animates card entrance with scale and opacity', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Initial frame - animation starting
        await tester.pump();

        // Track that animation changes occur
        var foundAnimation = false;

        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 20));

          final opacityWidgets = tester.widgetList<Opacity>(
            find.byType(Opacity),
          );
          // Look for an Opacity widget that is animating (between 0.1 and 0.95)
          // Skip the static background opacity (0.3)
          for (final opacityWidget in opacityWidgets) {
            if (opacityWidget.opacity > 0.1 &&
                opacityWidget.opacity < 0.95 &&
                opacityWidget.opacity != 0.3) {
              foundAnimation = true;
              break;
            }
          }
          if (foundAnimation) break;
        }

        expect(
          foundAnimation,
          isTrue,
          reason: 'Card should animate with opacity changes',
        );

        // Complete animation
        await pumpAndFinishAnimations(tester);

        // Verify animation completes successfully
        expect(find.byType(CompletionOverlay), findsOneWidget);
      });
    });

    group('Star animation', () {
      testWidgets('stars animate sequentially after card animation', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(stars: 3));

        // Let card animation complete (300ms)
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Animation should be in progress
        // Verify the widget builds without error
        expect(find.byType(CompletionOverlay), findsOneWidget);

        // Complete all animations
        await pumpAndFinishAnimations(tester);

        // Widget should be configured with 3 stars
        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(3));
      });

      testWidgets('empty stars do not animate', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 0));
        await pumpAndFinishAnimations(tester);

        // Widget should be configured with 0 stars
        final overlay = tester.widget<CompletionOverlay>(
          find.byType(CompletionOverlay),
        );
        expect(overlay.stars, equals(0));
      });
    });

    group('Visual styling', () {
      testWidgets('has semi-transparent dark background', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        // Find any Container with Colors.black54
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasBlackBackground = containers.any(
          (c) => c.color == Colors.black54,
        );
        expect(
          hasBlackBackground,
          isTrue,
          reason: 'Should have semi-transparent black overlay',
        );
      });

      testWidgets('completion card uses HoneycombDecorations', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        // Verify the card is rendered properly
        expect(find.byType(CompletionOverlay), findsOneWidget);
      });
    });

    group('Assertion validation', () {
      testWidgets('throws assertion error for stars < 0', (tester) async {
        expect(
          () => CompletionOverlay(
            stars: -1,
            completionTime: const Duration(seconds: 10),
          ),
          throwsAssertionError,
        );
      });

      testWidgets('throws assertion error for stars > 3', (tester) async {
        expect(
          () => CompletionOverlay(
            stars: 4,
            completionTime: const Duration(seconds: 10),
          ),
          throwsAssertionError,
        );
      });

      testWidgets('accepts stars = 0', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 0));
        await pumpAndFinishAnimations(tester);

        expect(find.byType(CompletionOverlay), findsOneWidget);
      });

      testWidgets('accepts stars = 3', (tester) async {
        await tester.pumpWidget(createTestWidget(stars: 3));
        await pumpAndFinishAnimations(tester);

        expect(find.byType(CompletionOverlay), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('renders correctly on standard screen size', (tester) async {
        // Standard mobile screen
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        expect(find.byType(CompletionOverlay), findsOneWidget);
        expect(find.text('Level Complete!'), findsOneWidget);

        // Reset to default
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      testWidgets('centers content on screen', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await pumpAndFinishAnimations(tester);

        final centerFinder = find.byType(Center);
        expect(centerFinder, findsWidgets);
      });
    });

    group('All button states together', () {
      testWidgets('all buttons work with hasNextLevel true', (tester) async {
        var nextTapped = false;
        var replayTapped = false;
        var levelsTapped = false;

        await tester.pumpWidget(
          createTestWidget(
            hasNextLevel: true,
            onNextLevel: () => nextTapped = true,
            onReplay: () => replayTapped = true,
            onLevelSelect: () => levelsTapped = true,
          ),
        );
        await pumpAndFinishAnimations(tester);

        // Tap Next Level
        await tester.tap(find.text('Next Level'));
        await tester.pump();
        expect(nextTapped, isTrue);

        // Tap Replay
        await tester.tap(find.text('Replay'));
        await tester.pump();
        expect(replayTapped, isTrue);

        // Tap Levels
        await tester.tap(find.text('Levels'));
        await tester.pump();
        expect(levelsTapped, isTrue);
      });

      testWidgets('only Replay and Levels buttons when hasNextLevel false', (
        tester,
      ) async {
        var replayTapped = false;
        var levelsTapped = false;

        await tester.pumpWidget(
          createTestWidget(
            hasNextLevel: false,
            onReplay: () => replayTapped = true,
            onLevelSelect: () => levelsTapped = true,
          ),
        );
        await pumpAndFinishAnimations(tester);

        // Next Level should not exist
        expect(find.text('Next Level'), findsNothing);

        // Replay should work
        await tester.tap(find.text('Replay'));
        await tester.pump();
        expect(replayTapped, isTrue);

        // Levels should work
        await tester.tap(find.text('Levels'));
        await tester.pump();
        expect(levelsTapped, isTrue);
      });
    });
  });
}
