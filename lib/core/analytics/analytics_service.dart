import 'analytics_event.dart';

/// Abstract interface for analytics tracking services.
///
/// Implementations handle event recording, user identification, and
/// property management. The interface is intentionally simple to allow
/// swapping between Firebase, local, or third-party analytics backends.
///
/// All implementations must:
/// - Be safe to call before [initialize] completes
/// - Handle null userId gracefully (anonymous users)
/// - Not throw exceptions from [trackEvent] (fire-and-forget)
abstract class AnalyticsService {
  /// Initializes the analytics service.
  ///
  /// Must be called before tracking events. Implementations should
  /// handle initialization failures gracefully (e.g., disable tracking).
  Future<void> initialize();

  /// Tracks an analytics event with optional properties.
  ///
  /// This is a fire-and-forget operation. Implementations must not throw.
  /// Events recorded before [initialize] completes may be buffered or dropped
  /// depending on the implementation.
  void trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic>? properties,
  });

  /// Sets the user ID for event attribution.
  ///
  /// Pass null to clear the user ID (e.g., on logout).
  void setUserId(String? userId);

  /// Sets a user property for segmentation.
  ///
  /// User properties persist across sessions and are attached
  /// to all subsequent events.
  void setUserProperty(String name, String value);

  /// Flushes any buffered events to the backend.
  ///
  /// Call this before app termination to ensure all events are persisted.
  Future<void> flush();
}
