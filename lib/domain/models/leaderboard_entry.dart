/// Represents a single entry in the leaderboard.
///
/// Contains user information and ranking data for both global and daily challenge
/// leaderboards. For daily challenges, includes optional completion time and stars.
class LeaderboardEntry {
  /// The unique identifier of the user.
  final String userId;

  /// The display name of the user.
  final String username;

  /// The URL of the user's avatar image.
  final String? avatarUrl;

  /// The total number of stars accumulated by the user.
  final int totalStars;

  /// The user's rank in the leaderboard (1-indexed).
  final int rank;

  /// The timestamp when this entry was last updated.
  final DateTime updatedAt;

  /// The completion time in milliseconds (for daily challenges).
  /// Only present for daily challenge leaderboard entries.
  final int? completionTime;

  /// The number of stars earned (for daily challenges).
  /// Only present for daily challenge leaderboard entries.
  final int? stars;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.totalStars,
    required this.rank,
    required this.updatedAt,
    this.completionTime,
    this.stars,
  });

  /// Creates a LeaderboardEntry from JSON data.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      totalStars: json['totalStars'] as int,
      rank: json['rank'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completionTime: json['completionTime'] as int?,
      stars: json['stars'] as int?,
    );
  }

  /// Serializes the entry to JSON.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'totalStars': totalStars,
      'rank': rank,
      'updatedAt': updatedAt.toIso8601String(),
      if (completionTime != null) 'completionTime': completionTime,
      if (stars != null) 'stars': stars,
    };
  }

  /// Creates a copy with optional updated fields.
  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    int? totalStars,
    int? rank,
    DateTime? updatedAt,
    int? completionTime,
    int? stars,
    bool clearAvatarUrl = false,
    bool clearCompletionTime = false,
    bool clearStars = false,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      totalStars: totalStars ?? this.totalStars,
      rank: rank ?? this.rank,
      updatedAt: updatedAt ?? this.updatedAt,
      completionTime: clearCompletionTime
          ? null
          : (completionTime ?? this.completionTime),
      stars: clearStars ? null : (stars ?? this.stars),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.totalStars == totalStars &&
        other.rank == rank &&
        other.updatedAt == updatedAt &&
        other.completionTime == completionTime &&
        other.stars == stars;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    username,
    avatarUrl,
    totalStars,
    rank,
    updatedAt,
    completionTime,
    stars,
  );

  @override
  String toString() {
    return 'LeaderboardEntry('
        'userId: $userId, '
        'username: $username, '
        'avatarUrl: $avatarUrl, '
        'totalStars: $totalStars, '
        'rank: $rank, '
        'updatedAt: $updatedAt, '
        'completionTime: $completionTime, '
        'stars: $stars)';
  }
}
