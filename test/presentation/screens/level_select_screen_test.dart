import 'dart:math';

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
import 'package:hex_buzz/presentation/providers/auth_provider.dart';
import 'package:hex_buzz/presentation/providers/game_provider.dart';
import 'package:hex_buzz/presentation/providers/progress_provider.dart';
import 'package:hex_buzz/presentation/screens/game/game_screen.dart';
import 'package:hex_buzz/presentation/screens/level_select/level_select_screen.dart';
import 'package:hex_buzz/presentation/theme/honey_theme.dart';
import 'package:hex_buzz/presentation/widgets/level_cell/level_cell_widget.dart';

/// Mock auth repository for testing that returns a guest user.
class MockAuthRepository implements AuthRepository {
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

/// Mock progress repository for testing.
///
/// Stores progress per-user. Uses 'guest' as default for tests without auth.
class MockProgressRepository implements ProgressRepository {
  final Map<String, ProgressState> _userProgress = {};

  MockProgressRepository([ProgressState? initialState]) {
    if (initialState != null) {
      _userProgress['guest'] = initialState;
    }
  }

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
}

/// Mock level repository for testing.
class MockLevelRepository extends LevelRepository {
  final List<Level> _levels;

  MockLevelRepository(this._levels);

  @override
  bool get isLoaded => true; // Always loaded for tests

  @override
  int get totalLevelCount => _levels.length;

  @override
  Future<void> load() async {
    // No-op, already loaded
  }

  @override
  Level? getLevelByIndex(int index) {
    if (index < 0 || index >= _levels.length) return null;
    return _levels[index];
  }

  @override
  Level? getRandomLevel(int size) {
    final matching = _levels.where((l) => l.size == size).toList();
    if (matching.isEmpty) return null;
    return matching[Random().nextInt(matching.length)];
  }
}

/// Creates a simple test level.
Level createTestLevel({int size = 2, String? id}) {
  final cells = <(int, int), HexCell>{};
  // Simple 2-cell level with start and end
  cells[(0, 0)] = const HexCell(q: 0, r: 0, checkpoint: 1);
  cells[(1, 0)] = const HexCell(q: 1, r: 0, checkpoint: 2);

  return Level(
    id: id ?? 'test-level-${DateTime.now().millisecondsSinceEpoch}',
    size: size,
    cells: cells,
    walls: {},
    checkpointCount: 2,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelSelectScreen', () {
    late MockAuthRepository mockAuthRepo;
    late MockProgressRepository mockProgressRepo;
    late MockLevelRepository mockLevelRepo;
    late List<Level> testLevels;

    setUp(() {
      // Create 5 test levels
      testLevels = List.generate(5, (i) => createTestLevel(id: 'level-$i'));
      mockAuthRepo = MockAuthRepository();
      mockLevelRepo = MockLevelRepository(testLevels);
      mockProgressRepo = MockProgressRepository();
    });

    Widget createTestWidget({ProgressState? progressState}) {
      if (progressState != null) {
        mockProgressRepo = MockProgressRepository(progressState);
      }

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          progressRepositoryProvider.overrideWithValue(mockProgressRepo),
          levelRepositoryProvider.overrideWithValue(mockLevelRepo),
        ],
        child: MaterialApp(
          theme: HoneyTheme.lightTheme,
          home: const LevelSelectScreen(),
        ),
      );
    }

    group('Screen structure', () {
      testWidgets('displays header with title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('HexBuzz'), findsOneWidget);
      });

      testWidgets('displays scaffold with body', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('displays total stars in header', (tester) async {
        final progressState = const ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        // Total: 3 + 2 = 5 stars, Max: 5 levels * 3 = 15 stars
        expect(find.text('5 / 15'), findsOneWidget);
      });
    });

    group('Level grid display', () {
      testWidgets('displays correct number of level cells', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(LevelCellWidget), findsNWidgets(5));
      });

      testWidgets('displays level numbers correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Level numbers are 1-indexed
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays GridView for scrollable content', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('shows "No levels available" when repository is empty', (
        tester,
      ) async {
        mockLevelRepo = MockLevelRepository([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              progressRepositoryProvider.overrideWithValue(mockProgressRepo),
              levelRepositoryProvider.overrideWithValue(mockLevelRepo),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              home: const LevelSelectScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No levels available'), findsOneWidget);
      });
    });

    group('Lock states', () {
      testWidgets('level 1 is always unlocked', (tester) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        // Level 1 should not show lock icon
        final levelCells = tester.widgetList<LevelCellWidget>(
          find.byType(LevelCellWidget),
        );
        final level1 = levelCells.first;
        expect(level1.isUnlocked, isTrue);
      });

      testWidgets('level 2 is locked when level 1 is not completed', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        // Level 1 (index 0) should be unlocked
        expect(levelCells[0].isUnlocked, isTrue);
        // Level 2 (index 1) should be locked
        expect(levelCells[1].isUnlocked, isFalse);
      });

      testWidgets('level 2 is unlocked when level 1 is completed', (
        tester,
      ) async {
        final progressState = const ProgressState(
          levels: {0: LevelProgress(completed: true, stars: 2)},
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        expect(levelCells[0].isUnlocked, isTrue);
        expect(levelCells[1].isUnlocked, isTrue);
        expect(levelCells[2].isUnlocked, isFalse);
      });

      testWidgets('displays lock icon for locked levels', (tester) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        // Lock icons should appear for levels 2-5
        expect(find.byIcon(Icons.lock), findsNWidgets(4));
      });

      testWidgets('all levels unlocked when all previous completed', (
        tester,
      ) async {
        final progressState = const ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
            2: LevelProgress(completed: true, stars: 1),
            3: LevelProgress(completed: true, stars: 3),
          },
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        for (final cell in levelCells) {
          expect(cell.isUnlocked, isTrue);
        }

        // No lock icons should be visible
        expect(find.byIcon(Icons.lock), findsNothing);
      });
    });

    group('Stars display', () {
      testWidgets('displays correct stars for completed levels', (
        tester,
      ) async {
        final progressState = const ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
            2: LevelProgress(completed: true, stars: 1),
          },
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        expect(levelCells[0].stars, 3);
        expect(levelCells[1].stars, 2);
        expect(levelCells[2].stars, 1);
      });

      testWidgets('displays zero stars for uncompleted levels', (tester) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        for (final cell in levelCells) {
          expect(cell.stars, 0);
        }
      });
    });

    group('Loading state', () {
      testWidgets('displays loading indicator while progress loads', (
        tester,
      ) async {
        // Use a slow repository that takes time to load
        final slowRepo = _SlowProgressRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              progressRepositoryProvider.overrideWithValue(slowRepo),
              levelRepositoryProvider.overrideWithValue(mockLevelRepo),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              home: const LevelSelectScreen(),
            ),
          ),
        );
        // Don't wait for async to settle - check immediately
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Now let it settle
        await tester.pumpAndSettle();
      });
    });

    group('Error state', () {
      testWidgets('displays error message when progress fails to load', (
        tester,
      ) async {
        // Create a repository that throws
        final errorRepo = _ThrowingProgressRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              progressRepositoryProvider.overrideWithValue(errorRepo),
              levelRepositoryProvider.overrideWithValue(mockLevelRepo),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              home: const LevelSelectScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Error loading progress'), findsOneWidget);
      });

      testWidgets('displays retry button on error', (tester) async {
        final errorRepo = _ThrowingProgressRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              progressRepositoryProvider.overrideWithValue(errorRepo),
              levelRepositoryProvider.overrideWithValue(mockLevelRepo),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              home: const LevelSelectScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('tapping unlocked level navigates to GameScreen', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on level 1 (unlocked)
        await tester.tap(find.byType(LevelCellWidget).first);
        await tester.pumpAndSettle();

        // Should navigate to GameScreen
        expect(find.byType(GameScreen), findsOneWidget);
        expect(find.byType(LevelSelectScreen), findsNothing);
      });

      testWidgets('tapping locked level does not navigate', (tester) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        // Find and tap level 2 (locked)
        await tester.tap(find.byType(LevelCellWidget).at(1));
        await tester.pumpAndSettle();

        // Should still be on LevelSelectScreen
        expect(find.byType(LevelSelectScreen), findsOneWidget);
        expect(find.byType(GameScreen), findsNothing);
      });

      testWidgets('GameScreen receives correct level index', (tester) async {
        final progressState = const ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        // Tap on level 3 (index 2)
        await tester.tap(find.byType(LevelCellWidget).at(2));
        await tester.pumpAndSettle();

        final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
        expect(gameScreen.levelIndex, 2);
      });
    });

    group('Completed level styling', () {
      testWidgets('completed levels show isCompleted as true', (tester) async {
        final progressState = const ProgressState(
          levels: {
            0: LevelProgress(completed: true, stars: 3),
            1: LevelProgress(completed: true, stars: 2),
          },
        );

        await tester.pumpWidget(createTestWidget(progressState: progressState));
        await tester.pumpAndSettle();

        final levelCells = tester
            .widgetList<LevelCellWidget>(find.byType(LevelCellWidget))
            .toList();

        expect(levelCells[0].isCompleted, isTrue);
        expect(levelCells[1].isCompleted, isTrue);
        expect(levelCells[2].isCompleted, isFalse);
      });
    });

    group('Header styling', () {
      testWidgets('header displays star icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have a star icon in the header for total stars display
        expect(find.byIcon(Icons.star), findsWidgets);
      });

      testWidgets('header displays zero stars when no progress', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(progressState: const ProgressState.empty()),
        );
        await tester.pumpAndSettle();

        // 5 levels * 3 stars = 15 max, 0 collected
        expect(find.text('0 / 15'), findsOneWidget);
      });
    });

    group('Many levels', () {
      testWidgets('handles scrolling with many levels', (tester) async {
        // Create 20 levels
        final manyLevels = List.generate(
          20,
          (i) => createTestLevel(id: 'level-$i'),
        );
        mockLevelRepo = MockLevelRepository(manyLevels);

        // Complete first 10 levels so they're all unlocked
        final progressState = ProgressState(
          levels: {
            for (var i = 0; i < 19; i++)
              i: const LevelProgress(completed: true, stars: 2),
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              progressRepositoryProvider.overrideWithValue(
                MockProgressRepository(progressState),
              ),
              levelRepositoryProvider.overrideWithValue(mockLevelRepo),
            ],
            child: MaterialApp(
              theme: HoneyTheme.lightTheme,
              home: const LevelSelectScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LevelCellWidget), findsWidgets);
        expect(find.byType(GridView), findsOneWidget);

        // Scroll down
        await tester.drag(find.byType(GridView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // After scrolling, should still find level cells
        expect(find.byType(LevelCellWidget), findsWidgets);
      });
    });
  });
}

/// Repository that throws on load for error testing.
class _ThrowingProgressRepository implements ProgressRepository {
  @override
  Future<ProgressState> loadForUser(String userId) async {
    throw Exception('Failed to load progress');
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {}

  @override
  Future<void> resetForUser(String userId) async {}
}

/// Repository that takes time to load for testing loading state.
class _SlowProgressRepository implements ProgressRepository {
  @override
  Future<ProgressState> loadForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const ProgressState.empty();
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {}

  @override
  Future<void> resetForUser(String userId) async {}
}
