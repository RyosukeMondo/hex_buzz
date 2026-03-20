import 'package:flutter/foundation.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';

/// In-memory analytics service for testing and debug builds.
///
/// Stores all events in a list for inspection. Useful for:
/// - Unit and integration tests: Assert specific events were tracked
/// - Debug builds: Inspect analytics behavior without a backend
/// - Development: Verify event properties and ordering
class LocalAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> events = [];
  String? userId;
  final Map<String, String> userProperties = {};
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;

    if (kDebugMode) {
      debugPrint('LocalAnalyticsService initialized (in-memory)');
    }
  }

  @override
  void trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic>? properties,
  }) {
    final event = AnalyticsEvent.now(
      type: type,
      properties: properties ?? {},
    );
    events.add(event);

    if (kDebugMode) {
      debugPrint('[Analytics] ${type.name}: ${properties ?? {}}');
    }
  }

  @override
  void setUserId(String? userId) {
    this.userId = userId;

    if (kDebugMode) {
      debugPrint('[Analytics] userId set: $userId');
    }
  }

  @override
  void setUserProperty(String name, String value) {
    userProperties[name] = value;

    if (kDebugMode) {
      debugPrint('[Analytics] property $name = $value');
    }
  }

  @override
  Future<void> flush() async {
    if (kDebugMode) {
      debugPrint('[Analytics] flush: ${events.length} events');
    }
  }

  /// Returns events filtered by type.
  List<AnalyticsEvent> eventsOfType(AnalyticsEventType type) {
    return events.where((e) => e.type == type).toList();
  }

  /// Returns the most recent event of the given type, or null.
  AnalyticsEvent? lastEventOfType(AnalyticsEventType type) {
    final matching = eventsOfType(type);
    return matching.isEmpty ? null : matching.last;
  }

  /// Whether any event of the given type has been tracked.
  bool hasEvent(AnalyticsEventType type) {
    return events.any((e) => e.type == type);
  }

  /// Clears all tracked events and user data.
  void reset() {
    events.clear();
    userId = null;
    userProperties.clear();
    initialized = false;
  }
}
