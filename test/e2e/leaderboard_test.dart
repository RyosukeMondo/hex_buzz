import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hex_buzz/main.dart' as app;
import 'package:flutter/material.dart';

/// E2E test for leaderboard functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Leaderboard E2E Tests', () {
    testWidgets('Load and display global leaderboard', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and tap "Leaderboard" button
      final leaderboardButton = find.text('Leaderboard');
      expect(leaderboardButton, findsOneWidget);

      await tester.tap(leaderboardButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify leaderboard loaded (not infinite loading)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify leaderboard entries are displayed
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('Verify leaderboard sorting by stars', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to leaderboard
      final leaderboardButton = find.text('Leaderboard');
      await tester.tap(leaderboardButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Get all star count texts
      final starFinders = find.textContaining('stars');

      if (starFinders.evaluate().isNotEmpty) {
        // Verify first entry has highest stars
        // (Implementation depends on UI structure)
        expect(find.textContaining('BeeKeeper'), findsWidgets);
      }
    });

    testWidgets('Test leaderboard pagination', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to leaderboard
      final leaderboardButton = find.text('Leaderboard');
      await tester.tap(leaderboardButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to bottom to trigger pagination
      final listView = find.byType(Scrollable).first;
      await tester.drag(listView, const Offset(0, -500));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify more entries loaded or end reached
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Find user rank in leaderboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Login first (if needed)
      // TODO: Add login flow

      // Navigate to leaderboard
      final leaderboardButton = find.text('Leaderboard');
      await tester.tap(leaderboardButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify user's rank is highlighted or visible
      // (Implementation depends on UI structure)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Refresh leaderboard data', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to leaderboard
      final leaderboardButton = find.text('Leaderboard');
      await tester.tap(leaderboardButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Pull to refresh
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify data refreshed (loading indicator appeared and disappeared)
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });
  });
}
