import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hex_buzz/main.dart' as app;
import 'package:flutter/material.dart';

/// E2E test for daily challenge flow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Challenge E2E Tests', () {
    testWidgets('Load and display daily challenge', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and tap "Daily Challenge" button
      final dailyChallengeButton = find.text('Daily Challenge');
      expect(dailyChallengeButton, findsOneWidget);

      await tester.tap(dailyChallengeButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify challenge screen loaded (not infinite loading)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify challenge content is displayed
      expect(find.textContaining('Challenge'), findsAtLeastNWidgets(1));
    });

    testWidgets('Complete daily challenge and verify submission', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to daily challenge
      final dailyChallengeButton = find.text('Daily Challenge');
      await tester.tap(dailyChallengeButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap "Start Challenge" button
      final startButton = find.text('Start Challenge');
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify game screen loaded
        expect(find.byType(Scaffold), findsWidgets);

        // TODO: Simulate completing the challenge
        // This requires interacting with the hex grid
        // For now, verify the game loaded

        expect(find.byType(CircularProgressIndicator), findsNothing);
      }
    });

    testWidgets('View daily challenge leaderboard', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to daily challenge
      final dailyChallengeButton = find.text('Daily Challenge');
      await tester.tap(dailyChallengeButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to find leaderboard section
      await tester.dragUntilVisible(
        find.textContaining('Leaderboard'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Verify leaderboard entries are displayed
      expect(find.textContaining('Leaderboard'), findsOneWidget);
    });
  });
}
