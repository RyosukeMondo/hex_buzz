/// Analytics event types for tracking user behavior and engagement.
///
/// Events are organized by category:
/// - **Funnel**: Track user progression from install to retention
/// - **Engagement**: Track in-game actions and feature usage
/// - **Daily challenge**: Track daily challenge participation
/// - **Retention**: Track session and return behavior
/// - **Feature usage**: Track feature discovery and adoption
enum AnalyticsEventType {
  // Funnel events
  appOpened,
  tutorialStarted,
  tutorialCompleted,
  tutorialSkipped,
  authCompleted,
  firstLevelStarted,
  firstLevelCompleted,

  // Engagement events
  levelStarted,
  levelCompleted,
  levelFailed,
  levelUndoUsed,
  hintUsed,

  // Daily challenge events
  dailyChallengeStarted,
  dailyChallengeCompleted,
  dailyChallengeShared,

  // Retention events
  sessionStarted,
  sessionEnded,
  dayRetention,

  // Feature usage events
  achievementUnlocked,
  timedChallengeStarted,
  timedChallengeCompleted,
  leaderboardViewed,
  settingsChanged,
  screenViewed,

  // Hint events
  hintRequested,
  hintUnavailable,

  // Achievement events
  achievementViewed,
  achievementScreenOpened,

  // Tutorial events
  tutorialStepCompleted,
  tutorialStepSkipped,

  // Timed challenge events
  timedChallengeGameOver,

  // Level pack events
  levelPackOpened,
  packLevelStarted,

  // Editor events
  editorLevelCreated,
  editorLevelShared,

  // Social events
  friendRequestSent,
  friendRequestAccepted,

  // Store events
  storePurchaseAttempted,
  storeAdWatched,

  // Settings events
  settingsOpened,
  settingChanged,

  // What's new events
  whatsNewViewed,

  // Rating events
  ratingPromptShown,
  ratingPromptResult,
}

/// An immutable analytics event with type, properties, and timestamp.
///
/// Events are the atomic unit of analytics tracking. Each event captures
/// a single user action or system occurrence with optional contextual
/// properties.
class AnalyticsEvent {
  final AnalyticsEventType type;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.type,
    this.properties = const {},
    required this.timestamp,
  });

  /// Creates an event with the current timestamp.
  factory AnalyticsEvent.now({
    required AnalyticsEventType type,
    Map<String, dynamic> properties = const {},
  }) {
    return AnalyticsEvent(
      type: type,
      properties: properties,
      timestamp: DateTime.now(),
    );
  }

  /// Serializes the event to JSON for storage or transmission.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserializes an event from JSON.
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      type: AnalyticsEventType.values.byName(json['type'] as String),
      properties: Map<String, dynamic>.from(
        json['properties'] as Map<String, dynamic>? ?? {},
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Creates a copy with optional updated fields.
  AnalyticsEvent copyWith({
    AnalyticsEventType? type,
    Map<String, dynamic>? properties,
    DateTime? timestamp,
  }) {
    return AnalyticsEvent(
      type: type ?? this.type,
      properties: properties ?? this.properties,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AnalyticsEvent(${type.name}, '
        'properties: $properties, '
        'timestamp: ${timestamp.toIso8601String()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnalyticsEvent) return false;
    return type == other.type &&
        timestamp == other.timestamp &&
        _mapsEqual(properties, other.properties);
  }

  @override
  int get hashCode => Object.hash(type, timestamp, properties.length);

  static bool _mapsEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
