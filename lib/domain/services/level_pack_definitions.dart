import '../models/level_pack.dart';

/// Built-in level pack definitions with curated difficulty progressions.
///
/// Each pack defines the grid sizes for its levels, creating a smooth
/// difficulty curve within and across packs.
class LevelPackDefinitions {
  LevelPackDefinitions._();

  static List<LevelPackMeta> get allPacks => const [
    LevelPackMeta(
      id: 'beginner_basics',
      name: 'Beginner Basics',
      description: 'Learn the fundamentals',
      difficulty: LevelPackDifficulty.beginner,
      levelCount: 10,
      iconName: 'school',
      sizes: [2, 2, 2, 3, 3, 3, 3, 3, 3, 3],
    ),
    LevelPackMeta(
      id: 'checkpoint_master',
      name: 'Checkpoint Master',
      description: 'Master checkpoint navigation',
      difficulty: LevelPackDifficulty.intermediate,
      levelCount: 10,
      iconName: 'flag',
      sizes: [3, 3, 3, 4, 4, 4, 4, 4, 4, 5],
    ),
    LevelPackMeta(
      id: 'wall_walker',
      name: 'Wall Walker',
      description: 'Navigate tricky walls',
      difficulty: LevelPackDifficulty.advanced,
      levelCount: 10,
      iconName: 'wall',
      sizes: [4, 4, 4, 4, 5, 5, 5, 5, 5, 5],
    ),
    LevelPackMeta(
      id: 'hex_expert',
      name: 'Hex Expert',
      description: 'Only for the brave',
      difficulty: LevelPackDifficulty.expert,
      levelCount: 10,
      iconName: 'military_tech',
      sizes: [5, 5, 5, 5, 5, 6, 6, 6, 6, 6],
    ),
  ];

  /// Gets a pack definition by ID.
  static LevelPackMeta? getById(String id) {
    for (final pack in allPacks) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}
