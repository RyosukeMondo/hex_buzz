/// Categories for grouping achievements.
enum AchievementCategory { gameplay, mastery, daily, speed, social }

/// Defines an achievement that can be unlocked by the player.
///
/// Achievements are immutable definitions with a [requiredValue] threshold.
/// When the player's tracked metric reaches [requiredValue], the achievement
/// is considered unlocked.
class Achievement {
  /// Unique identifier for this achievement.
  final String id;

  /// Display name shown in the UI.
  final String name;

  /// Description of how to unlock this achievement.
  final String description;

  /// Category for grouping in the achievements screen.
  final AchievementCategory category;

  /// Material icon name for display.
  final String iconName;

  /// Threshold value required to unlock this achievement.
  final int requiredValue;

  /// Whether this achievement is hidden until unlocked.
  final bool isSecret;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconName,
    required this.requiredValue,
    this.isSecret = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Achievement(id: $id, name: $name)';
}

/// Tracks a player's progress toward a specific achievement.
///
/// Stores the current metric value and unlock status. When [currentValue]
/// reaches the achievement's [requiredValue], [unlocked] becomes true.
class AchievementProgress {
  /// The achievement this progress tracks.
  final String achievementId;

  /// Current progress value toward the achievement threshold.
  final int currentValue;

  /// Whether the achievement has been unlocked.
  final bool unlocked;

  /// Timestamp when the achievement was unlocked, null if still locked.
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievementId,
    this.currentValue = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  /// Creates a copy with optional updated fields.
  AchievementProgress copyWith({
    int? currentValue,
    bool? unlocked,
    DateTime? unlockedAt,
    bool clearUnlockedAt = false,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: clearUnlockedAt ? null : (unlockedAt ?? this.unlockedAt),
    );
  }

  /// Serializes the progress to JSON.
  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'unlocked': unlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
    };
  }

  /// Creates an AchievementProgress from JSON data.
  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementProgress &&
        other.achievementId == achievementId &&
        other.currentValue == currentValue &&
        other.unlocked == unlocked &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode =>
      Object.hash(achievementId, currentValue, unlocked, unlockedAt);

  @override
  String toString() {
    return 'AchievementProgress('
        'achievementId: $achievementId, '
        'currentValue: $currentValue, '
        'unlocked: $unlocked)';
  }
}

/// The overall achievement state for a player.
///
/// Contains progress for all tracked achievements and provides computed
/// properties for UI display.
class AchievementState {
  /// Map of achievement ID to progress.
  final Map<String, AchievementProgress> progress;

  const AchievementState({this.progress = const {}});

  /// Creates an empty achievement state.
  const AchievementState.empty() : progress = const {};

  /// Returns the number of unlocked achievements.
  int get unlockedCount =>
      progress.values.where((p) => p.unlocked).length;

  /// Returns the total number of tracked achievements.
  int get totalCount => progress.length;

  /// Returns recently unlocked achievements, sorted by unlock time descending.
  List<AchievementProgress> get recentlyUnlocked {
    final unlocked = progress.values
        .where((p) => p.unlocked && p.unlockedAt != null)
        .toList();
    unlocked.sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked;
  }

  /// Gets progress for a specific achievement.
  AchievementProgress? getProgress(String achievementId) {
    return progress[achievementId];
  }

  /// Creates a new state with updated progress for a specific achievement.
  AchievementState withProgress(
    String achievementId,
    AchievementProgress achievementProgress,
  ) {
    return AchievementState(
      progress: Map.from(progress)..[achievementId] = achievementProgress,
    );
  }

  /// Creates a copy with optional updated fields.
  AchievementState copyWith({Map<String, AchievementProgress>? progress}) {
    return AchievementState(progress: progress ?? this.progress);
  }

  /// Serializes the achievement state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'progress': progress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Creates an AchievementState from JSON data.
  factory AchievementState.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'] as Map<String, dynamic>? ?? {};
    final progress = progressJson.map(
      (key, value) => MapEntry(
        key,
        AchievementProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
    return AchievementState(progress: progress);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AchievementState) return false;
    if (progress.length != other.progress.length) return false;
    for (final entry in progress.entries) {
      if (other.progress[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(progress.entries);

  @override
  String toString() {
    return 'AchievementState('
        'total: $totalCount, '
        'unlocked: $unlockedCount)';
  }
}
