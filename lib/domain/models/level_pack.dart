import 'level.dart';
import 'progress_state.dart';

/// Difficulty levels for level packs.
enum LevelPackDifficulty {
  beginner,
  intermediate,
  advanced,
  expert;

  String get displayName {
    switch (this) {
      case LevelPackDifficulty.beginner:
        return 'Beginner';
      case LevelPackDifficulty.intermediate:
        return 'Intermediate';
      case LevelPackDifficulty.advanced:
        return 'Advanced';
      case LevelPackDifficulty.expert:
        return 'Expert';
    }
  }
}

/// Metadata for a level pack definition (before levels are generated).
class LevelPackMeta {
  final String id;
  final String name;
  final String description;
  final LevelPackDifficulty difficulty;
  final int levelCount;
  final String iconName;
  final List<int> sizes;

  const LevelPackMeta({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.levelCount,
    required this.iconName,
    required this.sizes,
  });
}

/// A collection of curated levels with metadata.
class LevelPack {
  final String id;
  final String name;
  final String description;
  final LevelPackDifficulty difficulty;
  final int levelCount;
  final String iconName;
  final bool isBuiltIn;
  final List<Level> levels;

  const LevelPack({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.levelCount,
    required this.iconName,
    this.isBuiltIn = true,
    required this.levels,
  });

  /// Serializes the level pack to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty.name,
      'levelCount': levelCount,
      'iconName': iconName,
      'isBuiltIn': isBuiltIn,
      'levels': levels.map((l) => l.toJson()).toList(),
    };
  }

  /// Creates a LevelPack from JSON data.
  factory LevelPack.fromJson(Map<String, dynamic> json) {
    final levelsList = (json['levels'] as List<dynamic>)
        .map((l) => Level.fromJson(l as Map<String, dynamic>))
        .toList();

    return LevelPack(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: LevelPackDifficulty.values.byName(
        json['difficulty'] as String,
      ),
      levelCount: json['levelCount'] as int,
      iconName: json['iconName'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? true,
      levels: levelsList,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelPack && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LevelPack($id, $name, ${levels.length} levels, $difficulty)';
}

/// Tracks progress for all levels within a single pack.
class LevelPackProgress {
  final String packId;
  final Map<int, LevelProgress> levels;

  const LevelPackProgress({required this.packId, this.levels = const {}});

  /// Creates empty progress for a pack.
  const LevelPackProgress.empty(this.packId) : levels = const {};

  /// Number of completed levels in this pack.
  int get completedCount =>
      levels.values.where((p) => p.completed).length;

  /// Total stars earned across all levels in this pack.
  int get totalStars =>
      levels.values.fold(0, (sum, p) => sum + p.stars);

  /// Completion percentage (0.0 to 1.0).
  double completionPercentage(int totalLevels) {
    if (totalLevels <= 0) return 0.0;
    return completedCount / totalLevels;
  }

  /// Gets progress for a specific level index within the pack.
  LevelProgress getProgress(int levelIndex) {
    return levels[levelIndex] ?? const LevelProgress.empty();
  }

  /// Whether a level is unlocked within this pack.
  ///
  /// Level 0 is always unlocked. Subsequent levels require the
  /// previous level to be completed.
  bool isUnlocked(int levelIndex) {
    if (levelIndex <= 0) return true;
    return getProgress(levelIndex - 1).completed;
  }

  /// Creates a new progress with updated level completion.
  LevelPackProgress withLevelCompleted(
    int levelIndex, {
    required int stars,
    required Duration time,
  }) {
    final current = getProgress(levelIndex);
    final newStars = stars > current.stars ? stars : current.stars;

    Duration? newBestTime;
    if (current.bestTime == null) {
      newBestTime = time;
    } else if (stars >= current.stars) {
      newBestTime = time < current.bestTime! ? time : current.bestTime;
    } else {
      newBestTime = current.bestTime;
    }

    final updatedLevels = Map<int, LevelProgress>.from(levels);
    updatedLevels[levelIndex] = LevelProgress(
      completed: true,
      stars: newStars,
      bestTime: newBestTime,
    );

    return LevelPackProgress(packId: packId, levels: updatedLevels);
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() {
    return {
      'packId': packId,
      'levels': levels.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };
  }

  /// Creates from JSON data.
  factory LevelPackProgress.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = levelsJson.map(
      (key, value) => MapEntry(
        int.parse(key),
        LevelProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
    return LevelPackProgress(
      packId: json['packId'] as String,
      levels: levels,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LevelPackProgress) return false;
    if (packId != other.packId) return false;
    if (levels.length != other.levels.length) return false;
    for (final entry in levels.entries) {
      if (other.levels[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(packId, Object.hashAll(levels.entries));

  @override
  String toString() =>
      'LevelPackProgress($packId, completed: $completedCount, '
      'stars: $totalStars)';
}
