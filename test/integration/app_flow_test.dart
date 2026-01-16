// Integration tests for complete user flows.
//
// To run: flutter test test/integration/app_flow_test.dart

// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/presentation/providers/progress_provider.dart';
import 'package:hex_buzz/presentation/screens/auth/auth_screen.dart';
import 'package:hex_buzz/presentation/screens/front/front_screen.dart';
import 'package:hex_buzz/presentation/screens/game/game_screen.dart';
import 'package:hex_buzz/presentation/screens/level_select/level_select_screen.dart';
import 'package:hex_buzz/presentation/widgets/completion_overlay/completion_overlay.dart';
import 'package:hex_buzz/presentation/widgets/level_cell/level_cell_widget.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepo;
  late MockProgressRepository progressRepo;
  late MockLevelRepository levelRepo;
  late List<Level> testLevels;

  setUp(() {
    testLevels = [
      createSimpleLevel(id: 'level-0'),
      createSimpleLevel(id: 'level-1'),
      createThreeCellLevel(id: 'level-2'),
    ];
    authRepo = MockAuthRepository();
    levelRepo = MockLevelRepository(testLevels);
    progressRepo = MockProgressRepository();
  });

  tearDown(() => authRepo.dispose());

  Widget buildApp() => createFullApp(
    authRepo: authRepo,
    progressRepo: progressRepo,
    levelRepo: levelRepo,
  );

  group('Full User Journey E2E', () {
    testWidgets('New user: Front → Play as Guest → Progress persists', (
      tester,
    ) async {
      print('=== Starting Full User Journey Test ===');
      await tester.pumpWidget(buildApp());
      await waitForProviders(tester);

      // Front screen
      expect(find.byType(FrontScreen), findsOneWidget);
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Auth screen - play as guest
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.tap(find.text('Play as Guest'));
      await tester.pumpAndSettle();

      // Level select
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      print('  - Started as guest');

      // Play level 1
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);
      final level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      // Completion
      expect(find.byType(CompletionOverlay), findsOneWidget);
      final progressState = container.read(progressProvider).valueOrNull;
      expect(progressState!.getProgress(0).completed, isTrue);
      print('  - Level completed, progress saved');

      // Back to levels, verify Level 2 unlocked
      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();
      final cells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(cells[1].isUnlocked, isTrue);
      print('  - Level 2 unlocked');

      // Logout and play as guest again to verify progress persists
      await tester.tap(find.byIcon(Icons.logout));
      await pumpFrames(tester);
      expect(find.byType(FrontScreen), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play as Guest'));
      await tester.pumpAndSettle();

      // Verify progress persisted for guest user
      final persistedCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(persistedCells[0].isCompleted, isTrue);
      expect(persistedCells[1].isUnlocked, isTrue);
      print('=== Full User Journey Test PASSED ===');
    });

    testWidgets('Guest flow: Play as Guest → Complete → Progress exists', (
      tester,
    ) async {
      print('=== Starting Guest Flow Test ===');
      await tester.pumpWidget(buildApp());
      await waitForProviders(tester);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Guest'));
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsOneWidget);
      print('  - Playing as guest');

      // Complete level
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);
      final level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      // Verify guest progress
      final authState = container.read(authProvider).valueOrNull;
      expect(authState!.isGuest, isTrue);
      final guestProgress = progressRepo.getStateForUser(authState.id);
      expect(guestProgress.getProgress(0).completed, isTrue);
      print('  - Guest progress saved');

      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();
      final cells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(cells[0].isCompleted, isTrue);
      print('=== Guest Flow Test PASSED ===');
    });

    testWidgets('Guest progress isolated from registered user', (tester) async {
      print('=== Starting Progress Isolation Test ===');
      await tester.pumpWidget(buildApp());
      await waitForProviders(tester);

      // Guest flow
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Guest'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      var container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      var gameNotifier = container.read(gameProvider.notifier);
      var level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      final guestId = container.read(authProvider).valueOrNull!.id;

      // Logout
      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await pumpFrames(tester);

      // Sign in with Google (simulated)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Verify isolation
      final cells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(cells[0].isCompleted, isFalse, reason: 'New user has no progress');
      expect(
        progressRepo.getStateForUser(guestId).getProgress(0).completed,
        isTrue,
      );
      print('=== Progress Isolation Test PASSED ===');
    });

    testWidgets('Navigation preserves progress display', (tester) async {
      print('=== Starting Navigation Test ===');
      await tester.pumpWidget(buildApp());
      await waitForProviders(tester);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Guest'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);
      final level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next Level'));
      await tester.pumpAndSettle();
      expect(find.text('Level 2'), findsOneWidget);

      Navigator.of(tester.element(find.byType(GameScreen))).pop();
      await tester.pumpAndSettle();

      final cells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(cells[0].isCompleted, isTrue);
      print('=== Navigation Test PASSED ===');
    });

    testWidgets('Rapid completion does not lose progress', (tester) async {
      print('=== Starting Rapid Completion Test ===');
      await tester.pumpWidget(buildApp());
      await waitForProviders(tester);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Guest'));
      await tester.pumpAndSettle();

      // Complete level 1
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();
      var container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      var gameNotifier = container.read(gameProvider.notifier);
      var level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      // Immediately complete level 2
      await tester.tap(find.text('Next Level'));
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      gameNotifier = container.read(gameProvider.notifier);
      level = container.read(gameProvider).level;
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();

      final cells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(cells[0].isCompleted, isTrue);
      expect(cells[1].isCompleted, isTrue);
      print('=== Rapid Completion Test PASSED ===');
    });
  });
}
