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
  ///
  /// Handles both ISO8601 strings and Firestore Timestamp objects for
  /// the `completedAt` field.
  factory DailyChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return DailyChallengeCompletion(
      userId: json['userId'] as String,
      dateId: json['dateId'] as String,
      stars: json['stars'] as int,
      completionTimeMs:
          (json['completionTimeMs'] ?? json['completionTime']) as int,
      completedAt: _parseDateTime(json['completedAt']) ?? DateTime.now(),
      rank: json['rank'] as int?,
    );
  }

  /// Parses a DateTime from a value that may be a String, a Firestore
  /// Timestamp (which has a `toDate()` method), DateTime, or null.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Handle Firestore Timestamp objects (has toDate() method)
    try {
      // ignore: avoid_dynamic_calls
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
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
