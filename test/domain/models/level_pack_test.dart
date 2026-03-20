import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/level.dart';
import 'package:hex_buzz/domain/models/level_pack.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/progress_state.dart';
import 'package:hex_buzz/domain/services/level_pack_definitions.dart';
import 'package:hex_buzz/domain/services/level_pack_generator.dart';

void main() {
  group('LevelPackDifficulty', () {
    test('displayName returns human-readable names', () {
      expect(LevelPackDifficulty.beginner.displayName, 'Beginner');
      expect(LevelPackDifficulty.intermediate.displayName, 'Intermediate');
      expect(LevelPackDifficulty.advanced.displayName, 'Advanced');
      expect(LevelPackDifficulty.expert.displayName, 'Expert');
    });
  });

  group('LevelPack', () {
    late Level testLevel;

    setUp(() {
      testLevel = _createTestLevel();
    });

    test('serializes to JSON and back', () {
      final pack = LevelPack(
        id: 'test_pack',
        name: 'Test Pack',
        description: 'A test pack',
        difficulty: LevelPackDifficulty.beginner,
        levelCount: 1,
        iconName: 'school',
        isBuiltIn: true,
        levels: [testLevel],
      );

      final json = pack.toJson();
      final restored = LevelPack.fromJson(json);

      expect(restored.id, pack.id);
      expect(restored.name, pack.name);
      expect(restored.description, pack.description);
      expect(restored.difficulty, pack.difficulty);
      expect(restored.levelCount, pack.levelCount);
      expect(restored.iconName, pack.iconName);
      expect(restored.isBuiltIn, pack.isBuiltIn);
      expect(restored.levels.length, pack.levels.length);
      expect(restored.levels.first.id, testLevel.id);
    });

    test('JSON roundtrip preserves all fields through encode/decode', () {
      final pack = LevelPack(
        id: 'roundtrip_pack',
        name: 'Roundtrip',
        description: 'Testing roundtrip',
        difficulty: LevelPackDifficulty.expert,
        levelCount: 1,
        iconName: 'military_tech',
        isBuiltIn: false,
        levels: [testLevel],
      );

      final jsonString = jsonEncode(pack.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = LevelPack.fromJson(decoded);

      expect(restored.id, 'roundtrip_pack');
      expect(restored.difficulty, LevelPackDifficulty.expert);
      expect(restored.isBuiltIn, false);
    });

    test('equality is based on id', () {
      final pack1 = LevelPack(
        id: 'same_id',
        name: 'Pack 1',
        description: 'Desc 1',
        difficulty: LevelPackDifficulty.beginner,
        levelCount: 1,
        iconName: 'school',
        levels: [testLevel],
      );

      final pack2 = LevelPack(
        id: 'same_id',
        name: 'Pack 2',
        description: 'Desc 2',
        difficulty: LevelPackDifficulty.expert,
        levelCount: 1,
        iconName: 'flag',
        levels: [testLevel],
      );

      expect(pack1, equals(pack2));
      expect(pack1.hashCode, equals(pack2.hashCode));
    });
  });

  group('LevelPackProgress', () {
    test('empty progress has zero stats', () {
      const progress = LevelPackProgress(packId: 'test');

      expect(progress.completedCount, 0);
      expect(progress.totalStars, 0);
      expect(progress.completionPercentage(10), 0.0);
    });

    test('completedCount counts completed levels', () {
      final progress = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
          1: const LevelProgress(completed: true, stars: 2),
          2: const LevelProgress(completed: false, stars: 0),
        },
      );

      expect(progress.completedCount, 2);
    });

    test('totalStars sums all star ratings', () {
      final progress = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
          1: const LevelProgress(completed: true, stars: 2),
          2: const LevelProgress(completed: true, stars: 1),
        },
      );

      expect(progress.totalStars, 6);
    });

    test('completionPercentage calculates correctly', () {
      final progress = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
          1: const LevelProgress(completed: true, stars: 2),
        },
      );

      expect(progress.completionPercentage(10), 0.2);
      expect(progress.completionPercentage(2), 1.0);
    });

    test('completionPercentage handles zero total levels', () {
      const progress = LevelPackProgress(packId: 'test');
      expect(progress.completionPercentage(0), 0.0);
    });

    test('isUnlocked follows sequential unlock logic', () {
      final progress = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 2),
          1: const LevelProgress(completed: true, stars: 1),
        },
      );

      expect(progress.isUnlocked(0), true); // Always unlocked
      expect(progress.isUnlocked(1), true); // Level 0 completed
      expect(progress.isUnlocked(2), true); // Level 1 completed
      expect(progress.isUnlocked(3), false); // Level 2 not completed
    });

    test('withLevelCompleted keeps better results', () {
      final initial = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 20),
          ),
        },
      );

      // Better stars should update
      final updated = initial.withLevelCompleted(
        0,
        stars: 3,
        time: const Duration(seconds: 25),
      );
      expect(updated.getProgress(0).stars, 3);

      // Worse stars should keep original
      final updated2 = initial.withLevelCompleted(
        0,
        stars: 1,
        time: const Duration(seconds: 5),
      );
      expect(updated2.getProgress(0).stars, 2);
    });

    test('withLevelCompleted records best time on improvement', () {
      final initial = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 2,
            bestTime: Duration(seconds: 20),
          ),
        },
      );

      // Same stars, better time -> keep better time
      final updated = initial.withLevelCompleted(
        0,
        stars: 2,
        time: const Duration(seconds: 15),
      );
      expect(updated.getProgress(0).bestTime, const Duration(seconds: 15));

      // Same stars, worse time -> keep original time
      final updated2 = initial.withLevelCompleted(
        0,
        stars: 2,
        time: const Duration(seconds: 30),
      );
      expect(updated2.getProgress(0).bestTime, const Duration(seconds: 20));
    });

    test('serializes to JSON and back', () {
      final progress = LevelPackProgress(
        packId: 'test_pack',
        levels: {
          0: const LevelProgress(
            completed: true,
            stars: 3,
            bestTime: Duration(seconds: 8),
          ),
          1: const LevelProgress(completed: false, stars: 0),
        },
      );

      final json = progress.toJson();
      final restored = LevelPackProgress.fromJson(json);

      expect(restored.packId, progress.packId);
      expect(restored.completedCount, progress.completedCount);
      expect(restored.totalStars, progress.totalStars);
      expect(restored.getProgress(0).bestTime, const Duration(seconds: 8));
    });

    test('equality checks all fields', () {
      final a = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
        },
      );

      final b = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 3),
        },
      );

      final c = LevelPackProgress(
        packId: 'test',
        levels: {
          0: const LevelProgress(completed: true, stars: 2),
        },
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('LevelPackDefinitions', () {
    test('has exactly 4 built-in packs', () {
      expect(LevelPackDefinitions.allPacks.length, 4);
    });

    test('packs have correct IDs', () {
      final ids = LevelPackDefinitions.allPacks.map((p) => p.id).toList();
      expect(ids, [
        'beginner_basics',
        'checkpoint_master',
        'wall_walker',
        'hex_expert',
      ]);
    });

    test('each pack has 10 levels', () {
      for (final pack in LevelPackDefinitions.allPacks) {
        expect(pack.levelCount, 10, reason: 'Pack ${pack.id} has wrong count');
        expect(pack.sizes.length, 10,
            reason: 'Pack ${pack.id} sizes mismatch');
      }
    });

    test('packs have increasing difficulty', () {
      final difficulties = LevelPackDefinitions.allPacks
          .map((p) => p.difficulty)
          .toList();
      expect(difficulties, [
        LevelPackDifficulty.beginner,
        LevelPackDifficulty.intermediate,
        LevelPackDifficulty.advanced,
        LevelPackDifficulty.expert,
      ]);
    });

    test('getById returns correct pack', () {
      final pack = LevelPackDefinitions.getById('wall_walker');
      expect(pack, isNotNull);
      expect(pack!.name, 'Wall Walker');
    });

    test('getById returns null for unknown ID', () {
      expect(LevelPackDefinitions.getById('nonexistent'), isNull);
    });

    test('all sizes are within valid range (2-6)', () {
      for (final pack in LevelPackDefinitions.allPacks) {
        for (final size in pack.sizes) {
          expect(size, greaterThanOrEqualTo(2),
              reason: 'Pack ${pack.id} has invalid size $size');
          expect(size, lessThanOrEqualTo(6),
              reason: 'Pack ${pack.id} has invalid size $size');
        }
      }
    });
  });

  group('LevelPackGenerator', () {
    // Use a small custom meta for tests to avoid long generation times.
    // The beginner pack uses sizes 2-3 which generate quickly.
    const smallMeta = LevelPackMeta(
      id: 'test_small',
      name: 'Test Small',
      description: 'Small test pack',
      difficulty: LevelPackDifficulty.beginner,
      levelCount: 3,
      iconName: 'school',
      sizes: [2, 2, 3],
    );

    const smallMeta2 = LevelPackMeta(
      id: 'test_small_2',
      name: 'Test Small 2',
      description: 'Another small test pack',
      difficulty: LevelPackDifficulty.intermediate,
      levelCount: 3,
      iconName: 'flag',
      sizes: [2, 3, 3],
    );

    test('generates correct number of levels', () {
      final generator = LevelPackGenerator();
      final levels = generator.generatePack(smallMeta);
      expect(levels.length, smallMeta.levelCount);
    });

    test('generated levels match requested sizes', () {
      final generator = LevelPackGenerator();
      final levels = generator.generatePack(smallMeta);

      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].size, smallMeta.sizes[i],
            reason: 'Level $i has wrong size');
      }
    });

    test('generation is deterministic (same pack always same levels)', () {
      final generator1 = LevelPackGenerator();
      final generator2 = LevelPackGenerator();

      final levels1 = generator1.generatePack(smallMeta);
      final levels2 = generator2.generatePack(smallMeta);

      expect(levels1.length, levels2.length);
      for (var i = 0; i < levels1.length; i++) {
        expect(levels1[i].id, levels2[i].id,
            reason: 'Level $i IDs differ between generations');
      }
    });

    test('different packs produce different levels', () {
      final generator = LevelPackGenerator();

      final levels1 = generator.generatePack(smallMeta);
      final levels2 = generator.generatePack(smallMeta2);

      // At least some levels should differ
      final ids1 = levels1.map((l) => l.id).toSet();
      final ids2 = levels2.map((l) => l.id).toSet();
      expect(ids1.intersection(ids2).length, lessThan(levels1.length));
    });

    test('all generated levels have valid structure', () {
      final generator = LevelPackGenerator();
      final levels = generator.generatePack(smallMeta);

      for (final level in levels) {
        expect(level.cells.isNotEmpty, true);
        expect(level.checkpointCount, greaterThanOrEqualTo(2));

        // Has start and end cells
        final startCells = level.cells.values
            .where((c) => c.checkpoint == 1)
            .toList();
        expect(startCells.length, 1,
            reason: 'Level should have exactly 1 start cell');

        final endCells = level.cells.values
            .where((c) => c.checkpoint == level.checkpointCount)
            .toList();
        expect(endCells.length, 1,
            reason: 'Level should have exactly 1 end cell');
      }
    });
  });

  group('LevelPackMeta', () {
    test('stores all properties correctly', () {
      const meta = LevelPackMeta(
        id: 'test',
        name: 'Test',
        description: 'Desc',
        difficulty: LevelPackDifficulty.intermediate,
        levelCount: 5,
        iconName: 'flag',
        sizes: [3, 3, 4, 4, 5],
      );

      expect(meta.id, 'test');
      expect(meta.name, 'Test');
      expect(meta.description, 'Desc');
      expect(meta.difficulty, LevelPackDifficulty.intermediate);
      expect(meta.levelCount, 5);
      expect(meta.iconName, 'flag');
      expect(meta.sizes, [3, 3, 4, 4, 5]);
    });
  });
}

/// Creates a minimal valid test level for serialization tests.
Level _createTestLevel() {
  final cells = <(int, int), HexCell>{
    (0, -1): const HexCell(q: 0, r: -1, checkpoint: 1),
    (0, 0): const HexCell(q: 0, r: 0),
    (1, -1): const HexCell(q: 1, r: -1),
    (1, 0): const HexCell(q: 1, r: 0),
    (-1, 0): const HexCell(q: -1, r: 0),
    (-1, 1): const HexCell(q: -1, r: 1),
    (0, 1): const HexCell(q: 0, r: 1, checkpoint: 2),
  };

  final walls = <HexEdge>{
    HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
  };

  return Level(
    size: 2,
    cells: cells,
    walls: walls,
    checkpointCount: 2,
  );
}
