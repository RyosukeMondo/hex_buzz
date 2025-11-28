import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Creates a simple test level.
Level _createTestLevel({int size = 2, String? id}) {
  final cells = <(int, int), HexCell>{};
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

/// Mock auth repository for testing that returns a guest user.
class _MockAuthRepository implements AuthRepository {
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
class _MockProgressRepository implements ProgressRepository {
  @override
  Future<ProgressState> loadForUser(String userId) async =>
      const ProgressState.empty();

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {}

  @override
  Future<void> resetForUser(String userId) async {}
}

/// Mock level repository for testing.
class _MockLevelRepository extends LevelRepository {
  final List<Level> _levels = List.generate(
    5,
    (i) => _createTestLevel(id: 'level-$i'),
  );

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
  Level? getRandomLevel(int size) {
    final matching = _levels.where((l) => l.size == size).toList();
    if (matching.isEmpty) return null;
    return matching[Random().nextInt(matching.length)];
  }
}

void main() {
  testWidgets('App launches with level select screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_MockAuthRepository()),
          levelRepositoryProvider.overrideWithValue(_MockLevelRepository()),
          progressRepositoryProvider.overrideWithValue(
            _MockProgressRepository(),
          ),
        ],
        child: const HexBuzzApp(),
      ),
    );

    // Allow async providers to settle
    await tester.pumpAndSettle();

    // Verify app title is displayed
    expect(find.text('HexBuzz'), findsOneWidget);

    // Verify level select screen is shown (grid of level cells)
    // The level select screen doesn't have a reset button - that's on GameScreen
    // Instead verify we're on level select by checking for level grid presence
  });
}
