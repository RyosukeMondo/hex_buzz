/// Represents a user's completion of a daily challenge.
///
/// This model stores the user's performance data including stars earned,
/// completion time, and their rank on the leaderboard.
class DailyChallengeCompletion {
  /// The user ID who completed the challenge.
  final String userId;

  /// The challenge date ID (YYYY-MM-DD format).
  final String dateId;

  /// The number of stars earned (0-3).
  final int stars;

  /// The completion time in milliseconds.
  final int completionTimeMs;

  /// When the challenge was completed.
  final DateTime completedAt;

  /// The user's rank on the daily leaderboard.
  /// Only available after completion is saved.
  final int? rank;

  const DailyChallengeCompletion({
    required this.userId,
    required this.dateId,
    required this.stars,
    required this.completionTimeMs,
    required this.completedAt,
    this.rank,
  });

  /// Creates a DailyChallengeCompletion from JSON data.
  factory DailyChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return DailyChallengeCompletion(
      userId: json['userId'] as String,
      dateId: json['dateId'] as String,
      stars: json['stars'] as int,
      completionTimeMs: json['completionTimeMs'] as int,
      completedAt: json['completedAt'] is DateTime
          ? json['completedAt'] as DateTime
          : DateTime.parse(json['completedAt'] as String),
      rank: json['rank'] as int?,
    );
  }

  /// Serializes the completion to JSON.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dateId': dateId,
      'stars': stars,
      'completionTimeMs': completionTimeMs,
      'completedAt': completedAt.toIso8601String(),
      if (rank != null) 'rank': rank,
    };
  }

  /// Creates a copy with optional updated fields.
  DailyChallengeCompletion copyWith({
    String? userId,
    String? dateId,
    int? stars,
    int? completionTimeMs,
    DateTime? completedAt,
    int? rank,
  }) {
    return DailyChallengeCompletion(
      userId: userId ?? this.userId,
      dateId: dateId ?? this.dateId,
      stars: stars ?? this.stars,
      completionTimeMs: completionTimeMs ?? this.completionTimeMs,
      completedAt: completedAt ?? this.completedAt,
      rank: rank ?? this.rank,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallengeCompletion &&
        other.userId == userId &&
        other.dateId == dateId &&
        other.stars == stars &&
        other.completionTimeMs == completionTimeMs &&
        other.completedAt == completedAt &&
        other.rank == rank;
  }

  @override
  int get hashCode =>
      Object.hash(userId, dateId, stars, completionTimeMs, completedAt, rank);

  @override
  String toString() {
    return 'DailyChallengeCompletion('
        'userId: $userId, '
        'dateId: $dateId, '
        'stars: $stars, '
        'completionTimeMs: $completionTimeMs, '
        'completedAt: $completedAt, '
        'rank: $rank)';
  }
}
