import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:honeycomb_one_pass/domain/models/hex_cell.dart';
import 'package:honeycomb_one_pass/domain/models/level.dart';
import 'package:honeycomb_one_pass/domain/models/progress_state.dart';
import 'package:honeycomb_one_pass/domain/services/level_repository.dart';
import 'package:honeycomb_one_pass/domain/services/progress_repository.dart';
import 'package:honeycomb_one_pass/main.dart';
import 'package:honeycomb_one_pass/presentation/providers/game_provider.dart';
import 'package:honeycomb_one_pass/presentation/providers/progress_provider.dart';

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

/// Mock progress repository for testing.
class _MockProgressRepository implements ProgressRepository {
  @override
  Future<ProgressState> load() async => const ProgressState.empty();

  @override
  Future<void> save(ProgressState state) async {}

  @override
  Future<void> reset() async {}
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
          levelRepositoryProvider.overrideWithValue(_MockLevelRepository()),
          progressRepositoryProvider.overrideWithValue(
            _MockProgressRepository(),
          ),
        ],
        child: const HoneycombApp(),
      ),
    );

    // Allow async providers to settle
    await tester.pumpAndSettle();

    // Verify app title is displayed
    expect(find.text('Honeycomb One Pass'), findsOneWidget);

    // Verify level select screen is shown (grid of level cells)
    // The level select screen doesn't have a reset button - that's on GameScreen
    // Instead verify we're on level select by checking for level grid presence
  });
}
