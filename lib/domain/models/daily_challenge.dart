import 'level.dart';

/// Represents a daily challenge with level data and user completion status.
///
/// Daily challenges are unique puzzles available for 24 hours. Each challenge
/// includes the level to be played, metadata about global completion, and
/// optional user-specific data about their best performance.
class DailyChallenge {
  /// The unique identifier for this challenge (date in YYYY-MM-DD format).
  final String id;

  /// The date this challenge is valid for.
  final DateTime date;

  /// The level to be played for this challenge.
  final Level level;

  /// The number of users who have completed this challenge.
  final int completionCount;

  /// The user's best completion time in milliseconds.
  /// Only present if the user has completed this challenge.
  final int? userBestTime;

  /// The number of stars the user earned on this challenge.
  /// Only present if the user has completed this challenge.
  final int? userStars;

  /// The user's rank among all players who completed this challenge.
  /// Only present if the user has completed this challenge.
  final int? userRank;

  const DailyChallenge({
    required this.id,
    required this.date,
    required this.level,
    required this.completionCount,
    this.userBestTime,
    this.userStars,
    this.userRank,
  });

  /// Creates a DailyChallenge from JSON data.
  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      level: Level.fromJson(json['level'] as Map<String, dynamic>),
      completionCount: json['completionCount'] as int,
      userBestTime: json['userBestTime'] as int?,
      userStars: json['userStars'] as int?,
      userRank: json['userRank'] as int?,
    );
  }

  /// Serializes the challenge to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'level': level.toJson(),
      'completionCount': completionCount,
      if (userBestTime != null) 'userBestTime': userBestTime,
      if (userStars != null) 'userStars': userStars,
      if (userRank != null) 'userRank': userRank,
    };
  }

  /// Creates a copy with optional updated fields.
  DailyChallenge copyWith({
    String? id,
    DateTime? date,
    Level? level,
    int? completionCount,
    int? userBestTime,
    int? userStars,
    int? userRank,
    bool clearUserBestTime = false,
    bool clearUserStars = false,
    bool clearUserRank = false,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      date: date ?? this.date,
      level: level ?? this.level,
      completionCount: completionCount ?? this.completionCount,
      userBestTime: clearUserBestTime
          ? null
          : (userBestTime ?? this.userBestTime),
      userStars: clearUserStars ? null : (userStars ?? this.userStars),
      userRank: clearUserRank ? null : (userRank ?? this.userRank),
    );
  }

  /// Returns true if the user has completed this challenge.
  bool get hasUserCompleted =>
      userBestTime != null && userStars != null && userRank != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyChallenge &&
        other.id == id &&
        other.date == date &&
        other.level == level &&
        other.completionCount == completionCount &&
        other.userBestTime == userBestTime &&
        other.userStars == userStars &&
        other.userRank == userRank;
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    level,
    completionCount,
    userBestTime,
    userStars,
    userRank,
  );

  @override
  String toString() {
    return 'DailyChallenge('
        'id: $id, '
        'date: $date, '
        'level: ${level.id}, '
        'completionCount: $completionCount, '
        'userBestTime: $userBestTime, '
        'userStars: $userStars, '
        'userRank: $userRank)';
  }
}
