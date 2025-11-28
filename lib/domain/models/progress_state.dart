/// Represents progress for a single level.
///
/// Tracks whether the level has been completed, the star rating earned,
/// and the best completion time achieved.
class LevelProgress {
  final bool completed;
  final int stars;
  final Duration? bestTime;

  const LevelProgress({this.completed = false, this.stars = 0, this.bestTime});

  /// Creates an empty progress entry for an incomplete level.
  const LevelProgress.empty() : completed = false, stars = 0, bestTime = null;

  /// Creates a copy with optional updated fields.
  LevelProgress copyWith({
    bool? completed,
    int? stars,
    Duration? bestTime,
    bool clearBestTime = false,
  }) {
    return LevelProgress(
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bestTime: clearBestTime ? null : (bestTime ?? this.bestTime),
    );
  }

  /// Serializes the level progress to JSON.
  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'stars': stars,
      if (bestTime != null) 'bestTimeMs': bestTime!.inMilliseconds,
    };
  }

  /// Creates a LevelProgress from JSON data.
  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestTime: json['bestTimeMs'] != null
          ? Duration(milliseconds: json['bestTimeMs'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelProgress &&
        other.completed == completed &&
        other.stars == stars &&
        other.bestTime == bestTime;
  }

  @override
  int get hashCode => Object.hash(completed, stars, bestTime);

  @override
  String toString() {
    return 'LevelProgress(completed: $completed, stars: $stars, bestTime: $bestTime)';
  }
}

/// Represents the overall progress state for all levels.
///
/// Tracks progress across all levels and provides computed properties
/// for total stars, completion status, and level unlocking logic.
class ProgressState {
  final Map<int, LevelProgress> levels;

  const ProgressState({this.levels = const {}});

  /// Creates an empty progress state with no completed levels.
  const ProgressState.empty() : levels = const {};

  /// Gets progress for a specific level, returning empty progress if not found.
  LevelProgress getProgress(int levelIndex) {
    return levels[levelIndex] ?? const LevelProgress.empty();
  }

  /// Checks if a level is unlocked.
  ///
  /// Level 0 is always unlocked. Subsequent levels are unlocked when
  /// the previous level has been completed.
  bool isUnlocked(int levelIndex) {
    if (levelIndex <= 0) return true;
    return getProgress(levelIndex - 1).completed;
  }

  /// Returns the total number of stars earned across all levels.
  int get totalStars {
    return levels.values.fold(0, (sum, progress) => sum + progress.stars);
  }

  /// Returns the number of completed levels.
  int get completedLevels {
    return levels.values.where((progress) => progress.completed).length;
  }

  /// Returns the highest unlocked level index.
  int get highestUnlockedLevel {
    int highest = 0;
    for (final entry in levels.entries) {
      if (entry.value.completed && entry.key >= highest) {
        highest = entry.key + 1;
      }
    }
    return highest;
  }

  /// Creates a new state with updated progress for a specific level.
  ProgressState withLevelProgress(int levelIndex, LevelProgress progress) {
    return ProgressState(levels: Map.from(levels)..[levelIndex] = progress);
  }

  /// Creates a new state after completing a level.
  ///
  /// Updates the level's progress only if the new result is better
  /// (more stars or faster time with same stars).
  ProgressState withLevelCompleted(
    int levelIndex, {
    required int stars,
    required Duration time,
  }) {
    final currentProgress = getProgress(levelIndex);

    // Always mark as completed
    // Keep better star count
    // Keep better time if star count is equal or better
    final newStars = stars > currentProgress.stars
        ? stars
        : currentProgress.stars;

    Duration? newBestTime;
    if (currentProgress.bestTime == null) {
      newBestTime = time;
    } else if (stars >= currentProgress.stars) {
      newBestTime = time < currentProgress.bestTime!
          ? time
          : currentProgress.bestTime;
    } else {
      newBestTime = currentProgress.bestTime;
    }

    return withLevelProgress(
      levelIndex,
      LevelProgress(completed: true, stars: newStars, bestTime: newBestTime),
    );
  }

  /// Creates a copy with optional updated fields.
  ProgressState copyWith({Map<int, LevelProgress>? levels}) {
    return ProgressState(levels: levels ?? this.levels);
  }

  /// Serializes the progress state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'levels': levels.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };
  }

  /// Creates a ProgressState from JSON data.
  factory ProgressState.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = levelsJson.map(
      (key, value) => MapEntry(
        int.parse(key),
        LevelProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
    return ProgressState(levels: levels);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProgressState) return false;
    if (levels.length != other.levels.length) return false;
    for (final entry in levels.entries) {
      if (other.levels[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(levels.entries);

  @override
  String toString() {
    return 'ProgressState(levels: ${levels.length}, totalStars: $totalStars, completed: $completedLevels)';
  }
}
