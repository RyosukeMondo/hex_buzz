/// A leaderboard entry enriched with social context.
///
/// Extends the basic leaderboard concept with friend and current-user flags
/// for rendering friend-only leaderboard views.
class SocialLeaderboardEntry {
  /// The unique user ID.
  final String userId;

  /// The display username.
  final String username;

  /// Total stars accumulated by the user.
  final int stars;

  /// Completion time in milliseconds (for daily challenges).
  final int? completionTime;

  /// The user's rank within this leaderboard view.
  final int rank;

  /// Whether this user is a friend of the viewing user.
  final bool isFriend;

  /// Whether this entry represents the current (viewing) user.
  final bool isCurrentUser;

  const SocialLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.stars,
    this.completionTime,
    required this.rank,
    this.isFriend = false,
    this.isCurrentUser = false,
  });

  /// Creates a [SocialLeaderboardEntry] from JSON data.
  factory SocialLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SocialLeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      stars: json['stars'] as int,
      completionTime: json['completionTime'] as int?,
      rank: json['rank'] as int,
      isFriend: json['isFriend'] as bool? ?? false,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  /// Serializes this entry to JSON.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'stars': stars,
      if (completionTime != null) 'completionTime': completionTime,
      'rank': rank,
      'isFriend': isFriend,
      'isCurrentUser': isCurrentUser,
    };
  }

  /// Creates a copy with optional updated fields.
  SocialLeaderboardEntry copyWith({
    String? userId,
    String? username,
    int? stars,
    int? completionTime,
    int? rank,
    bool? isFriend,
    bool? isCurrentUser,
    bool clearCompletionTime = false,
  }) {
    return SocialLeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      stars: stars ?? this.stars,
      completionTime: clearCompletionTime
          ? null
          : (completionTime ?? this.completionTime),
      rank: rank ?? this.rank,
      isFriend: isFriend ?? this.isFriend,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialLeaderboardEntry &&
        other.userId == userId &&
        other.username == username &&
        other.stars == stars &&
        other.completionTime == completionTime &&
        other.rank == rank &&
        other.isFriend == isFriend &&
        other.isCurrentUser == isCurrentUser;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    username,
    stars,
    completionTime,
    rank,
    isFriend,
    isCurrentUser,
  );

  @override
  String toString() {
    return 'SocialLeaderboardEntry('
        'userId: $userId, '
        'username: $username, '
        'stars: $stars, '
        'rank: $rank, '
        'isFriend: $isFriend, '
        'isCurrentUser: $isCurrentUser)';
  }
}
