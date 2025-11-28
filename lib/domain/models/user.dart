/// Represents a user in the application.
///
/// Tracks user identity, creation time, and whether the user is a guest
/// (local-only account without authentication).
class User {
  final String id;
  final String username;
  final DateTime createdAt;
  final bool isGuest;

  const User({
    required this.id,
    required this.username,
    required this.createdAt,
    this.isGuest = false,
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
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  /// Serializes the user to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'isGuest': isGuest,
    };
  }

  /// Creates a User from JSON data.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.createdAt == createdAt &&
        other.isGuest == isGuest;
  }

  @override
  int get hashCode => Object.hash(id, username, createdAt, isGuest);

  @override
  String toString() {
    return 'User(id: $id, username: $username, isGuest: $isGuest)';
  }
}
