import 'level.dart';

/// Represents a user-created level with metadata for sharing and tracking.
///
/// Wraps a [Level] with creator information, sharing capability via
/// short codes, and aggregate play statistics.
class UserLevel {
  final String id;
  final Level level;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final String? shareCode;
  final int playCount;
  final double averageStars;

  const UserLevel({
    required this.id,
    required this.level,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.shareCode,
    this.playCount = 0,
    this.averageStars = 0.0,
  });

  /// Creates a copy with optional updated fields.
  UserLevel copyWith({
    String? id,
    Level? level,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    String? shareCode,
    int? playCount,
    double? averageStars,
  }) {
    return UserLevel(
      id: id ?? this.id,
      level: level ?? this.level,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      shareCode: shareCode ?? this.shareCode,
      playCount: playCount ?? this.playCount,
      averageStars: averageStars ?? this.averageStars,
    );
  }

  /// Serializes the user level to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.toJson(),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
      if (shareCode != null) 'shareCode': shareCode,
      'playCount': playCount,
      'averageStars': averageStars,
    };
  }

  /// Creates a UserLevel from JSON data.
  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      id: json['id'] as String,
      level: Level.fromJson(json['level'] as Map<String, dynamic>),
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      shareCode: json['shareCode'] as String?,
      playCount: json['playCount'] as int? ?? 0,
      averageStars: (json['averageStars'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLevel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserLevel($id, creator: $creatorName, size: ${level.size})';
}
