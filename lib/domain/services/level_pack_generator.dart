import 'dart:math';

import '../models/level.dart';
import '../models/level_pack.dart';
import 'level_generator.dart';

/// Generates deterministic levels for level packs.
///
/// Uses seeded Random instances to ensure the same pack definition
/// always produces the same levels, providing a consistent experience
/// across app reinstalls and devices.
class LevelPackGenerator {
  final LevelGenerator Function({Random? random}) _generatorFactory;

  /// Creates a LevelPackGenerator.
  ///
  /// [generatorFactory] allows injection of a custom LevelGenerator factory
  /// for testing. Defaults to creating standard LevelGenerator instances.
  LevelPackGenerator({
    LevelGenerator Function({Random? random})? generatorFactory,
  }) : _generatorFactory = generatorFactory ??
           (({Random? random}) => LevelGenerator(random: random));

  /// Generates all levels for a pack definition.
  ///
  /// Uses deterministic seeds derived from the pack ID and level index,
  /// so the same pack always has the same levels.
  ///
  /// Returns a list of [Level] objects matching the pack's level count
  /// and size specifications.
  List<Level> generatePack(LevelPackMeta meta) {
    final levels = <Level>[];

    for (var i = 0; i < meta.levelCount; i++) {
      final level = _generatePackLevel(meta, i);
      levels.add(level);
    }

    return levels;
  }

  /// Generates a single level for a pack at the given index.
  ///
  /// Tries multiple seed offsets if the initial seed fails to produce
  /// a valid level.
  Level _generatePackLevel(LevelPackMeta meta, int levelIndex) {
    final size = levelIndex < meta.sizes.length
        ? meta.sizes[levelIndex]
        : meta.sizes.last;

    // Try multiple seeds to handle generation failures
    for (var seedOffset = 0; seedOffset < 100; seedOffset++) {
      final seed = _computeSeed(meta.id, levelIndex, seedOffset);
      final random = Random(seed);
      final generator = _generatorFactory(random: random);
      final result = generator.generate(size);

      if (result.success && result.level != null) {
        return result.level!;
      }
    }

    // This should not happen with 100 attempts, but fail clearly
    throw StateError(
      'Failed to generate level $levelIndex for pack "${meta.id}" '
      'with size $size after 100 seed attempts',
    );
  }

  /// Computes a deterministic seed from pack ID, level index, and offset.
  ///
  /// Combines the hash of the pack ID with the level index and offset
  /// to create a unique but reproducible seed for each level.
  static int _computeSeed(String packId, int levelIndex, int seedOffset) {
    // Use a simple but effective hash combination
    var hash = packId.hashCode;
    hash = hash ^ (levelIndex * 31);
    hash = hash ^ (seedOffset * 997);
    // Ensure positive seed value
    return hash.abs();
  }
}
