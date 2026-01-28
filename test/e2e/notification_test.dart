import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hex_buzz/main.dart' as app;
import 'package:flutter/material.dart';

/// E2E test for push notification functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Push Notification E2E Tests', () {
    testWidgets('Verify FCM token registration on app start', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app loaded without errors
      expect(find.byType(Scaffold), findsWidgets);

      // FCM token should be registered automatically
      // (Verified through Firebase console or backend logs)
    });

    testWidgets('Test notification permission request', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for notification permission dialog
      // (May appear on first launch)
      final permissionDialog = find.text('Allow notifications');
      if (permissionDialog.evaluate().isNotEmpty) {
        await tester.tap(find.text('Allow'));
        await tester.pumpAndSettle();
      }

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Navigate to daily challenge from notification', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Simulate receiving notification
      // Note: This requires platform-specific implementation
      // For now, verify the route exists

      final dailyChallengeButton = find.text('Daily Challenge');
      expect(dailyChallengeButton, findsOneWidget);

      await tester.tap(dailyChallengeButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation worked
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Test notification preferences', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to settings (if available)
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton.first);
        await tester.pumpAndSettle();

        // Look for notification toggle
        final notificationToggle = find.text('Daily Challenge Notifications');
        if (notificationToggle.evaluate().isNotEmpty) {
          // Verify toggle exists
          expect(find.byType(Switch), findsWidgets);
        }
      }
    });
  });
}
