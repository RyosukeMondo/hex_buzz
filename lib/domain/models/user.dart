/// Represents a user in the application.
///
/// Tracks user identity, creation time, and whether the user is a guest
/// (local-only account without authentication).
/// Enhanced with social/competitive features: email, photo, stats, and rank.
class User {
  final String id;
  final String username;
  final DateTime createdAt;
  final bool isGuest;

  // Social/Firebase fields
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final int totalStars;
  final int? rank;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.username,
    required this.createdAt,
    this.isGuest = false,
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.totalStars = 0,
    this.rank,
    this.lastLoginAt,
  });

  /// Creates a guest user with a unique ID.
  factory User.guest() {
    return User(
      id: 'guest',
      username: 'Guest',
      createdAt: DateTime.now(),
      isGuest: true,
    );
  }

  /// Creates a copy with optional updated fields.
  User copyWith({
    String? id,
    String? username,
    DateTime? createdAt,
    bool? isGuest,
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    int? totalStars,
    int? rank,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      totalStars: totalStars ?? this.totalStars,
      rank: rank ?? this.rank,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Serializes the user to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'isGuest': isGuest,
      if (uid != null) 'uid': uid,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'totalStars': totalStars,
      if (rank != null) 'rank': rank,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
    };
  }

  /// Creates a User from JSON data.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isGuest: json['isGuest'] as bool? ?? false,
      uid: json['uid'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      totalStars: json['totalStars'] as int? ?? 0,
      rank: json['rank'] as int?,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.createdAt == createdAt &&
        other.isGuest == isGuest &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.totalStars == totalStars &&
        other.rank == rank &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    createdAt,
    isGuest,
    uid,
    email,
    displayName,
    photoURL,
    totalStars,
    rank,
    lastLoginAt,
  );

  @override
  String toString() {
    return 'User(id: $id, username: $username, isGuest: $isGuest)';
  }
}
