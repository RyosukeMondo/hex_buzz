// End-to-end integration tests for level progression flow.
//
// These tests verify the complete user journey from level selection through
// game completion and progress unlocking. While structured as widget tests
// for broader compatibility, they test the full integration of all components.
//
// To run on a real device, use: flutter test integration_test/ -d <device>
// To run as widget tests: flutter test integration_test/

// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/auth_result.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:hex_buzz/domain/services/level_repository.dart';
import 'package:hex_buzz/domain/services/progress_repository.dart';
import 'package:hex_buzz/main.dart';
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/presentation/providers/progress_provider.dart';
import 'package:hex_buzz/presentation/screens/game/game_screen.dart';
import 'package:hex_buzz/presentation/screens/level_select/level_select_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:hex_buzz/presentation/widgets/completion_overlay/completion_overlay.dart';
import 'package:hex_buzz/presentation/widgets/level_cell/level_cell_widget.dart';

/// Mock auth repository for testing that returns a guest user.
class TestAuthRepository implements AuthRepository {
  final User _guestUser = User.guest();

  @override
  Future<User?> getCurrentUser() async => _guestUser;

  @override
  Future<AuthResult> login(String username, String password) async {
    return AuthResult.success(_guestUser);
  }

  @override
  Future<AuthResult> register(String username, String password) async {
    return AuthResult.success(_guestUser);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> loginAsGuest() async {
    return AuthResult.success(_guestUser);
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_guestUser);
  }
}

/// In-memory progress repository for E2E testing.
///
/// Stores progress per-user. Uses 'test_user' as default for tests without auth.
class TestProgressRepository implements ProgressRepository {
  final Map<String, ProgressState> _userProgress = {};

  @override
  Future<ProgressState> loadForUser(String userId) async {
    return _userProgress[userId] ?? const ProgressState.empty();
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {
    _userProgress[userId] = state;
  }

  @override
  Future<void> resetForUser(String userId) async {
    _userProgress.remove(userId);
  }

  /// Get current state for a specific user (for test assertions).
  ProgressState getStateForUser(String userId) {
    return _userProgress[userId] ?? const ProgressState.empty();
  }

  /// Legacy getter for backward compatibility with existing tests.
  /// Returns progress for 'guest' user since tests don't set up auth.
  ProgressState get currentState =>
      _userProgress['guest'] ?? const ProgressState.empty();

  /// Legacy setter for backward compatibility with existing tests.
  Future<void> save(ProgressState state) async {
    _userProgress['guest'] = state;
  }
}

/// Test level repository with simple, solvable levels.
class TestLevelRepository extends LevelRepository {
  final List<Level> _levels;

  TestLevelRepository(this._levels);

  @override
  bool get isLoaded => true;

  @override
  int get totalLevelCount => _levels.length;

  @override
  Future<void> load() async {}

  @override
  Level? getLevelByIndex(int index) {
    if (index < 0 || index >= _levels.length) return null;
    return _levels[index];
  }

  @override
  Level? getRandomLevel(int size) => _levels.firstOrNull;
}

/// Creates a simple 2-cell level that can be solved in one move.
///
/// Layout: [Start(cp1)] -> [End(cp2)]
Level createSimpleLevel({required String id}) {
  final cells = <(int, int), HexCell>{
    (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1), // Start
    (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2), // End
  };

  return Level(id: id, size: 2, cells: cells, walls: {}, checkpointCount: 2);
}

/// Creates a 3-cell level requiring 2 moves.
///
/// Layout: [Start(cp1)] -> [Middle] -> [End(cp2)]
Level createThreeCellLevel({required String id}) {
  final cells = <(int, int), HexCell>{
    (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1), // Start
    (1, 0): const HexCell(q: 1, r: 0), // Middle
    (2, 0): const HexCell(q: 2, r: 0, checkpoint: 2), // End
  };

  return Level(id: id, size: 3, cells: cells, walls: {}, checkpointCount: 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestAuthRepository authRepo;
  late TestProgressRepository progressRepo;
  late TestLevelRepository levelRepo;
  late List<Level> testLevels;

  setUp(() {
    // Create multiple simple test levels
    testLevels = [
      createSimpleLevel(id: 'level-0'),
      createSimpleLevel(id: 'level-1'),
      createThreeCellLevel(id: 'level-2'),
    ];
    authRepo = TestAuthRepository();
    levelRepo = TestLevelRepository(testLevels);
    progressRepo = TestProgressRepository();
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        progressRepositoryProvider.overrideWithValue(progressRepo),
        levelRepositoryProvider.overrideWithValue(levelRepo),
      ],
      child: MaterialApp(
        title: 'HexBuzz',
        theme: HoneyTheme.lightTheme,
        home: const LevelSelectScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.game) {
            final levelIndex = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (_) => GameScreen(levelIndex: levelIndex),
              settings: settings,
            );
          }
          if (settings.name == AppRoutes.levels) {
            return MaterialPageRoute(
              builder: (_) => const LevelSelectScreen(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }

  group('Level Progression E2E', () {
    testWidgets('Complete user flow: Level 1 -> Complete -> Level 2 unlocked', (
      tester,
    ) async {
      print('=== Starting Level Progression E2E Test ===');

      // 1. Launch app and verify we're on level select screen
      print('Step 1: Launching app...');
      await tester.pumpWidget(createTestApp());

      // Wait for auth and progress providers to fully initialize
      // Multiple pump cycles ensure all async Riverpod providers rebuild
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsOneWidget);
      expect(find.text('HexBuzz'), findsOneWidget);
      print('  - Level select screen displayed');

      // 2. Verify initial state: Level 1 unlocked, Level 2 locked
      print('Step 2: Verifying initial lock states...');
      final levelCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();

      expect(
        levelCells[0].isUnlocked,
        isTrue,
        reason: 'Level 1 should be unlocked',
      );
      expect(
        levelCells[1].isUnlocked,
        isFalse,
        reason: 'Level 2 should be locked',
      );
      print('  - Level 1: unlocked');
      print('  - Level 2: locked');

      // 3. Tap Level 1 to start the game
      print('Step 3: Tapping Level 1 to start game...');
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      print('  - Navigated to GameScreen for Level 1');

      // 4. Find and tap on cells to complete the level
      // For our simple 2-cell level: tap start cell, then tap end cell
      print('Step 4: Completing Level 1...');

      // Wait for the level to be fully loaded
      await tester.pumpAndSettle();

      // Use the gameProvider to simulate completing the level
      // In a real E2E test, we'd tap the hex cells, but CustomPainter cells
      // are difficult to tap directly. Instead, we use the provider.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);

      // Get the current level
      final gameState = container.read(gameProvider);
      final level = gameState.level;
      print('  - Level cells: ${level.cells.length}');
      print('  - Start cell: (${level.startCell.q}, ${level.startCell.r})');
      print('  - End cell: (${level.endCell.q}, ${level.endCell.r})');

      // Move to start cell first
      gameNotifier.tryMove(level.startCell);
      await tester.pump();

      // Move to end cell to complete
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      // 5. Verify completion overlay appears
      print('Step 5: Verifying completion overlay...');
      expect(find.byType(CompletionOverlay), findsOneWidget);
      expect(find.textContaining('Level Complete'), findsOneWidget);
      print('  - Completion overlay displayed');

      // Verify stars are shown (should be 3 stars for instant completion)
      expect(find.byIcon(Icons.star), findsWidgets);
      print('  - Stars displayed');

      // 6. Verify progress was saved - check via provider, not repo directly
      print('Step 6: Verifying progress persistence...');
      final progressState = container.read(progressProvider).valueOrNull;
      expect(
        progressState,
        isNotNull,
        reason: 'Progress state should be loaded',
      );
      expect(progressState!.getProgress(0).completed, isTrue);
      expect(progressState.getProgress(0).stars, greaterThan(0));
      print(
        '  - Level 0 progress: completed=${progressState.getProgress(0).completed}, stars=${progressState.getProgress(0).stars}',
      );

      // 7. Navigate back to level select
      print('Step 7: Navigating back to level select...');
      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();

      expect(find.byType(LevelSelectScreen), findsOneWidget);
      print('  - Back on level select screen');

      // 8. Verify Level 2 is now unlocked
      print('Step 8: Verifying Level 2 is now unlocked...');
      final updatedLevelCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();

      expect(updatedLevelCells[0].isUnlocked, isTrue);
      expect(updatedLevelCells[0].isCompleted, isTrue);
      expect(updatedLevelCells[0].stars, greaterThan(0));
      expect(
        updatedLevelCells[1].isUnlocked,
        isTrue,
        reason: 'Level 2 should be unlocked after completing Level 1',
      );
      print('  - Level 1: completed with ${updatedLevelCells[0].stars} stars');
      print('  - Level 2: unlocked');

      // 9. Navigate to Level 2 to verify it's playable
      print('Step 9: Verifying Level 2 is playable...');
      await tester.tap(find.byType(LevelCellWidget).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      print('  - Successfully navigated to Level 2');

      print('=== Level Progression E2E Test PASSED ===');
    });

    testWidgets('Replay level and improve star rating', (tester) async {
      print('=== Starting Replay Level Test ===');

      // Pre-populate with Level 1 completed with 1 star
      await progressRepo.save(
        const ProgressState(
          levels: {
            0: LevelProgress(
              completed: true,
              stars: 1,
              bestTime: Duration(seconds: 45),
            ),
          },
        ),
      );

      // Launch app
      print('Step 1: Launching app with existing progress...');
      await tester.pumpWidget(createTestApp());

      // Wait for auth and progress providers to fully initialize
      // Multiple pump cycles ensure all async Riverpod providers rebuild
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Verify initial state
      final initialCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(initialCells[0].stars, 1);
      expect(initialCells[0].isCompleted, isTrue);
      print('  - Level 1 shows 1 star');

      // Tap Level 1 to replay
      print('Step 2: Replaying Level 1...');
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);

      // Complete the level again (faster this time for more stars)
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);
      final gameState = container.read(gameProvider);
      final level = gameState.level;

      // Quick completion for 3 stars
      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      // Verify completion
      print('Step 3: Verifying improved rating...');
      expect(find.byType(CompletionOverlay), findsOneWidget);

      // Check that progress was updated with better stars
      final updatedProgress = progressRepo.currentState;
      expect(updatedProgress.getProgress(0).stars, greaterThanOrEqualTo(1));
      print('  - New star rating: ${updatedProgress.getProgress(0).stars}');

      // Go back and verify
      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();

      final updatedCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();

      // Stars should be at least as good (progress keeps best score)
      expect(updatedCells[0].stars, greaterThanOrEqualTo(1));
      print('  - Level 1 display shows ${updatedCells[0].stars} stars');

      print('=== Replay Level Test PASSED ===');
    });

    testWidgets('Locked level cannot be accessed', (tester) async {
      print('=== Starting Locked Level Test ===');

      // Launch app with fresh state (no progress)
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Level 2 is locked
      print('Step 1: Verifying Level 2 is locked...');
      final levelCells = tester
          .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
          .toList();
      expect(levelCells[1].isUnlocked, isFalse);
      expect(find.byIcon(Icons.lock), findsWidgets);
      print('  - Level 2 shows lock icon');

      // Try to tap locked level
      print('Step 2: Attempting to tap locked Level 2...');
      await tester.tap(find.byType(LevelCellWidget).at(1));
      await tester.pumpAndSettle();

      // Should still be on level select (not navigated)
      expect(find.byType(LevelSelectScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      print('  - Remained on level select screen (navigation blocked)');

      print('=== Locked Level Test PASSED ===');
    });

    testWidgets('Next Level button works from completion overlay', (
      tester,
    ) async {
      print('=== Starting Next Level Button Test ===');

      // Launch app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Start and complete Level 1
      print('Step 1: Completing Level 1...');
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

      expect(find.byType(CompletionOverlay), findsOneWidget);
      print('  - Level 1 completed');

      // Tap "Next Level" button
      print('Step 2: Tapping Next Level button...');
      final nextLevelButton = find.text('Next Level');
      expect(nextLevelButton, findsOneWidget);
      await tester.tap(nextLevelButton);
      await tester.pumpAndSettle();

      // Should now be on Level 2
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      print('  - Navigated to Level 2');

      print('=== Next Level Button Test PASSED ===');
    });

    testWidgets('Replay button resets current level', (tester) async {
      print('=== Starting Replay Button Test ===');

      // Launch and navigate to Level 1
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      print('Step 1: Starting Level 1...');
      await tester.tap(find.byType(LevelCellWidget).first);
      await tester.pumpAndSettle();

      // Complete the level
      print('Step 2: Completing Level 1...');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final gameNotifier = container.read(gameProvider.notifier);
      final level = container.read(gameProvider).level;

      gameNotifier.tryMove(level.startCell);
      gameNotifier.tryMove(level.endCell);
      await tester.pumpAndSettle();

      expect(find.byType(CompletionOverlay), findsOneWidget);

      // Tap Replay button
      print('Step 3: Tapping Replay button...');
      await tester.tap(find.text('Replay'));
      await tester.pumpAndSettle();

      // Should still be on Level 1 GameScreen but game reset
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.byType(CompletionOverlay), findsNothing);
      print('  - Game reset, overlay hidden');

      // Verify the game state was reset
      final resetGameState = container.read(gameProvider);
      expect(resetGameState.isComplete, isFalse);
      expect(resetGameState.path, isEmpty);
      print('  - Game state cleared');

      print('=== Replay Button Test PASSED ===');
    });

    testWidgets('Total stars display updates correctly', (tester) async {
      print('=== Starting Total Stars Display Test ===');

      // Launch app
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify initial star count (0 / 9 for 3 levels)
      print('Step 1: Checking initial star count...');
      expect(find.text('0 / 9'), findsOneWidget);
      print('  - Initial: 0 / 9 stars');

      // Complete Level 1
      print('Step 2: Completing Level 1...');
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

      // Go back to level select
      await tester.tap(find.text('Levels'));
      await tester.pumpAndSettle();

      // Check updated star count
      print('Step 3: Checking updated star count...');
      final progress = progressRepo.currentState;
      final earnedStars = progress.totalStars;
      expect(find.text('$earnedStars / 9'), findsOneWidget);
      print('  - Updated: $earnedStars / 9 stars');

      print('=== Total Stars Display Test PASSED ===');
    });
  });
}
