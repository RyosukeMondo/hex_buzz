/// The current status of a friend relationship.
enum FriendStatus { pending, accepted, blocked }

/// Represents a friend relationship between two users.
///
/// Stored bidirectionally in Firestore: when user A sends a request to user B,
/// both users get a [FriendRelation] document. The [status] field tracks
/// whether the request is pending, accepted, or blocked.
class FriendRelation {
  /// The ID of the user who owns this relation record.
  final String ownerId;

  /// The ID of the friend user.
  final String friendId;

  /// The display username of the friend.
  final String friendUsername;

  /// Current status of the relationship.
  final FriendStatus status;

  /// When the friend request was created.
  final DateTime createdAt;

  /// Whether the current user initiated the request.
  ///
  /// Used to determine who sees "Accept/Decline" vs "Pending" UI.
  final bool isInitiator;

  const FriendRelation({
    required this.ownerId,
    required this.friendId,
    required this.friendUsername,
    required this.status,
    required this.createdAt,
    this.isInitiator = false,
  });

  /// Creates a [FriendRelation] from Firestore JSON data.
  factory FriendRelation.fromJson(Map<String, dynamic> json) {
    return FriendRelation(
      ownerId: json['ownerId'] as String,
      friendId: json['friendId'] as String,
      friendUsername: json['friendUsername'] as String,
      status: FriendStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FriendStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isInitiator: json['isInitiator'] as bool? ?? false,
    );
  }

  /// Serializes this relation to JSON for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'friendId': friendId,
      'friendUsername': friendUsername,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'isInitiator': isInitiator,
    };
  }

  /// Creates a copy with optional updated fields.
  FriendRelation copyWith({
    String? ownerId,
    String? friendId,
    String? friendUsername,
    FriendStatus? status,
    DateTime? createdAt,
    bool? isInitiator,
  }) {
    return FriendRelation(
      ownerId: ownerId ?? this.ownerId,
      friendId: friendId ?? this.friendId,
      friendUsername: friendUsername ?? this.friendUsername,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isInitiator: isInitiator ?? this.isInitiator,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRelation &&
        other.ownerId == ownerId &&
        other.friendId == friendId &&
        other.friendUsername == friendUsername &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.isInitiator == isInitiator;
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    friendId,
    friendUsername,
    status,
    createdAt,
    isInitiator,
  );

  @override
  String toString() {
    return 'FriendRelation('
        'ownerId: $ownerId, '
        'friendId: $friendId, '
        'friendUsername: $friendUsername, '
        'status: $status, '
        'isInitiator: $isInitiator)';
  }
}
