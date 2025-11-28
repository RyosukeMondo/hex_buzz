import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';
import 'package:hex_buzz/domain/models/game_state.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';

void main() {
  late Level testLevel;

  setUp(() {
    // Create a simple 2x2 test level with 2 checkpoints
    final cells = <(int, int), HexCell>{
      (0, 0): HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): HexCell(q: 1, r: 0),
      (0, 1): HexCell(q: 0, r: 1),
      (1, 1): HexCell(q: 1, r: 1, checkpoint: 2),
    };
    testLevel = Level(
      size: 2,
      cells: cells,
      walls: <HexEdge>{},
      checkpointCount: 2,
    );
  });

  group('GameState', () {
    group('construction', () {
      test('creates with required parameters', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);

        expect(state.level, testLevel);
        expect(state.mode, GameMode.daily);
        expect(state.path, isEmpty);
        expect(state.nextCheckpoint, 1);
        expect(state.startTime, isNull);
        expect(state.endTime, isNull);
      });

      test('initial factory creates default state', () {
        final state = GameState.initial(
          level: testLevel,
          mode: GameMode.practice,
        );

        expect(state.level, testLevel);
        expect(state.mode, GameMode.practice);
        expect(state.path, isEmpty);
        expect(state.nextCheckpoint, 1);
        expect(state.isStarted, false);
        expect(state.isComplete, false);
      });
    });

    group('computed properties', () {
      test('isStarted returns false when startTime is null', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        expect(state.isStarted, false);
      });

      test('isStarted returns true when startTime is set', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: DateTime.now(),
        );
        expect(state.isStarted, true);
      });

      test('isComplete returns false when endTime is null', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: DateTime.now(),
        );
        expect(state.isComplete, false);
      });

      test('isComplete returns true when endTime is set', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(state.isComplete, true);
      });

      test('elapsedTime returns zero when not started', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        expect(state.elapsedTime, Duration.zero);
      });

      test('elapsedTime calculates correct duration when complete', () {
        final start = DateTime(2024, 1, 1, 10, 0, 0);
        final end = DateTime(2024, 1, 1, 10, 1, 30);
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: start,
          endTime: end,
        );
        expect(state.elapsedTime, const Duration(minutes: 1, seconds: 30));
      });

      test('canSubmitToLeaderboard true for completed daily', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(state.canSubmitToLeaderboard, true);
      });

      test('canSubmitToLeaderboard false for incomplete daily', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: DateTime.now(),
        );
        expect(state.canSubmitToLeaderboard, false);
      });

      test('canSubmitToLeaderboard false for completed practice', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.practice,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(state.canSubmitToLeaderboard, false);
      });

      test('currentCell returns null when path is empty', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        expect(state.currentCell, isNull);
      });

      test('currentCell returns last cell in path', () {
        final cell1 = HexCell(q: 0, r: 0);
        final cell2 = HexCell(q: 1, r: 0);
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: [cell1, cell2],
        );
        expect(state.currentCell, cell2);
      });

      test('visitedCoordinates returns set of path coordinates', () {
        final cell1 = HexCell(q: 0, r: 0);
        final cell2 = HexCell(q: 1, r: 0);
        final cell3 = HexCell(q: 1, r: 1);
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: [cell1, cell2, cell3],
        );
        expect(state.visitedCoordinates, {(0, 0), (1, 0), (1, 1)});
      });
    });

    group('copyWith', () {
      test('copies with new mode', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        final copy = state.copyWith(mode: GameMode.practice);

        expect(copy.mode, GameMode.practice);
        expect(copy.level, testLevel);
      });

      test('copies with new path', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        final newPath = [HexCell(q: 0, r: 0), HexCell(q: 1, r: 0)];
        final copy = state.copyWith(path: newPath);

        expect(copy.path, newPath);
        expect(copy.path.length, 2);
      });

      test('copies with new nextCheckpoint', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        final copy = state.copyWith(nextCheckpoint: 2);

        expect(copy.nextCheckpoint, 2);
      });

      test('copies with new startTime', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        final now = DateTime.now();
        final copy = state.copyWith(startTime: now);

        expect(copy.startTime, now);
        expect(copy.isStarted, true);
      });

      test('copies with new endTime', () {
        final now = DateTime.now();
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: now,
        );
        final copy = state.copyWith(endTime: now);

        expect(copy.endTime, now);
        expect(copy.isComplete, true);
      });

      test('clears startTime when clearStartTime is true', () {
        final now = DateTime.now();
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: now,
        );
        final copy = state.copyWith(clearStartTime: true);

        expect(copy.startTime, isNull);
        expect(copy.isStarted, false);
      });

      test('clears endTime when clearEndTime is true', () {
        final now = DateTime.now();
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          startTime: now,
          endTime: now,
        );
        final copy = state.copyWith(clearEndTime: true);

        expect(copy.endTime, isNull);
        expect(copy.isComplete, false);
        expect(copy.startTime, now); // startTime preserved
      });

      test('preserves all fields when no changes specified', () {
        final now = DateTime.now();
        final path = [HexCell(q: 0, r: 0)];
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: path,
          nextCheckpoint: 2,
          startTime: now,
          endTime: now,
        );
        final copy = state.copyWith();

        expect(copy.level, testLevel);
        expect(copy.mode, GameMode.daily);
        expect(copy.path, path);
        expect(copy.nextCheckpoint, 2);
        expect(copy.startTime, now);
        expect(copy.endTime, now);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final startTime = DateTime(2024, 1, 1, 10, 0, 0);
        final endTime = DateTime(2024, 1, 1, 10, 1, 0);
        final path = [HexCell(q: 0, r: 0), HexCell(q: 1, r: 0)];
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: path,
          nextCheckpoint: 2,
          startTime: startTime,
          endTime: endTime,
        );
        final json = state.toJson();

        expect(json['level'], isNotNull);
        expect(json['mode'], 'daily');
        expect(json['path'], hasLength(2));
        expect(json['nextCheckpoint'], 2);
        expect(json['startTime'], startTime.toIso8601String());
        expect(json['endTime'], endTime.toIso8601String());
      });

      test('toJson excludes null times', () {
        final state = GameState(level: testLevel, mode: GameMode.practice);
        final json = state.toJson();

        expect(json.containsKey('startTime'), false);
        expect(json.containsKey('endTime'), false);
      });

      test('fromJson creates correct state', () {
        final startTime = DateTime(2024, 1, 1, 10, 0, 0);
        final endTime = DateTime(2024, 1, 1, 10, 1, 0);
        final path = [HexCell(q: 0, r: 0), HexCell(q: 1, r: 0)];
        final original = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: path,
          nextCheckpoint: 2,
          startTime: startTime,
          endTime: endTime,
        );
        final json = original.toJson();
        final restored = GameState.fromJson(json);

        expect(restored.level.id, testLevel.id);
        expect(restored.mode, GameMode.daily);
        expect(restored.path.length, 2);
        expect(restored.nextCheckpoint, 2);
        expect(restored.startTime, startTime);
        expect(restored.endTime, endTime);
      });

      test('fromJson handles missing optional times', () {
        final json = {
          'level': testLevel.toJson(),
          'mode': 'practice',
          'path': <Map<String, dynamic>>[],
          'nextCheckpoint': 1,
        };
        final state = GameState.fromJson(json);

        expect(state.startTime, isNull);
        expect(state.endTime, isNull);
        expect(state.isStarted, false);
        expect(state.isComplete, false);
      });

      test('JSON round-trip preserves data', () {
        final startTime = DateTime(2024, 1, 1, 10, 0, 0);
        final path = [HexCell(q: 0, r: 0, checkpoint: 1)];
        final original = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: path,
          nextCheckpoint: 2,
          startTime: startTime,
        );
        final json = original.toJson();
        final restored = GameState.fromJson(json);

        expect(restored.level.id, original.level.id);
        expect(restored.mode, original.mode);
        expect(restored.path.length, original.path.length);
        expect(restored.path.first.q, original.path.first.q);
        expect(restored.path.first.r, original.path.first.r);
        expect(restored.nextCheckpoint, original.nextCheckpoint);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
      });
    });

    group('toString', () {
      test('not started state', () {
        final state = GameState(level: testLevel, mode: GameMode.daily);
        expect(state.toString(), contains('not-started'));
        expect(state.toString(), contains('path: 0'));
      });

      test('in-progress state', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: [HexCell(q: 0, r: 0)],
          startTime: DateTime.now(),
        );
        expect(state.toString(), contains('in-progress'));
        expect(state.toString(), contains('path: 1'));
      });

      test('complete state', () {
        final state = GameState(
          level: testLevel,
          mode: GameMode.daily,
          path: [HexCell(q: 0, r: 0), HexCell(q: 1, r: 0)],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(state.toString(), contains('complete'));
        expect(state.toString(), contains('path: 2'));
      });
    });
  });
}
