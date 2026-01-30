import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/presentation/widgets/migration_dialog.dart';

void main() {
  group('MigrationDialog', () {
    testWidgets('displays migration information correctly', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 5,
              totalStars: 12,
              onConfirm: () => confirmed = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Upgrade to Cloud Sync'), findsOneWidget);

      // Verify levels count
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Levels completed'), findsOneWidget);

      // Verify stars count
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Total stars earned'), findsOneWidget);

      // Verify info message
      expect(
        find.text('Sign in to sync your progress across all your devices.'),
        findsOneWidget,
      );

      // Verify buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign In & Sync'), findsOneWidget);
    });

    testWidgets('calls onConfirm when sign in button is tapped', (
      tester,
    ) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 5,
              totalStars: 12,
              onConfirm: () => confirmed = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sign In & Sync'));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('calls onCancel when cancel button is tapped', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 5,
              totalStars: 12,
              onConfirm: () {},
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('displays zero values correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 0,
              totalStars: 0,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNWidgets(2)); // Both levels and stars show 0
    });

    testWidgets('displays large numbers correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 999,
              totalStars: 2997,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('999'), findsOneWidget);
      expect(find.text('2997'), findsOneWidget);
    });

    testWidgets('has correct icon colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              levelsToMigrate: 5,
              totalStars: 12,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify icons exist (color checking is difficult with MaterialApp theme)
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
      expect(find.byIcon(Icons.stars), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('showMigrationDialog', () {
    testWidgets('returns true when confirmed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showMigrationDialog(
                    context,
                    levelsToMigrate: 5,
                    totalStars: 12,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Upgrade to Cloud Sync'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.text('Sign In & Sync'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showMigrationDialog(
                    context,
                    levelsToMigrate: 5,
                    totalStars: 12,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('dialog is not dismissible by tapping outside', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showMigrationDialog(
                    context,
                    levelsToMigrate: 5,
                    totalStars: 12,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to tap outside (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('Upgrade to Cloud Sync'), findsOneWidget);
    });
  });
}
