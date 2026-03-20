import 'dart:math';

/// A shareable code that other users can use to send a friend request.
///
/// Each user gets a unique 6-character alphanumeric code. Codes are stored
/// in Firestore keyed by user ID for quick lookup in both directions.
class FriendCode {
  /// The user ID who owns this friend code.
  final String ownerId;

  /// The 6-character uppercase alphanumeric code.
  final String code;

  /// When this code was created.
  final DateTime createdAt;

  const FriendCode({
    required this.ownerId,
    required this.code,
    required this.createdAt,
  });

  /// Generates a random 6-character uppercase alphanumeric code.
  ///
  /// Uses characters A-Z and 0-9 for readability and easy sharing.
  static String generate() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Creates a [FriendCode] from Firestore JSON data.
  factory FriendCode.fromJson(Map<String, dynamic> json) {
    return FriendCode(
      ownerId: json['ownerId'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serializes this friend code to JSON for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendCode &&
        other.ownerId == ownerId &&
        other.code == code &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(ownerId, code, createdAt);

  @override
  String toString() {
    return 'FriendCode(ownerId: $ownerId, code: $code)';
  }
}
