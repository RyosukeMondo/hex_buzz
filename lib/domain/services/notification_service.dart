/// Abstract interface for push notification operations.
///
/// Provides methods for initializing notifications, managing device tokens,
/// subscribing to topics, and handling incoming messages. Implementations
/// are platform-specific (FCM for mobile/web, WNS for Windows) while consumers
/// depend only on this interface for dependency injection.
abstract class NotificationService {
  /// Initializes the notification service.
  ///
  /// Must be called before using any other methods. Sets up notification
  /// handlers, configures platform-specific settings, and prepares to receive
  /// messages.
  ///
  /// Returns true if initialization succeeded, false otherwise.
  Future<bool> initialize();

  /// Gets the device token for push notifications.
  ///
  /// The token uniquely identifies this device and is used by the backend
  /// to send targeted push notifications. The token may change over time
  /// (e.g., after app reinstall), so implementations should monitor for changes.
  ///
  /// Returns the device token string, or null if unavailable or on error.
  Future<String?> getDeviceToken();

  /// Subscribes to a notification topic.
  ///
  /// Topics allow sending messages to groups of devices without managing
  /// individual device tokens. Common topics include "daily_challenge",
  /// "rank_changes", etc.
  ///
  /// The [topic] is the topic name to subscribe to (e.g., "daily_challenge").
  ///
  /// Returns true if subscription succeeded, false otherwise.
  Future<bool> subscribeToTopic(String topic);

  /// Unsubscribes from a notification topic.
  ///
  /// Stops receiving messages sent to the specified topic.
  ///
  /// The [topic] is the topic name to unsubscribe from.
  ///
  /// Returns true if unsubscription succeeded, false otherwise.
  Future<bool> unsubscribeFromTopic(String topic);

  /// A stream that emits received notification messages.
  ///
  /// Emits a map containing the notification data whenever a message is
  /// received (both foreground and background). The map structure depends
  /// on the notification payload but typically includes:
  /// - 'title': Notification title
  /// - 'body': Notification body
  /// - 'data': Custom data payload
  ///
  /// Consumers should handle messages appropriately (e.g., showing UI,
  /// navigating to specific screens).
  Stream<Map<String, dynamic>> get onMessageReceived;

  /// Requests notification permission from the user.
  ///
  /// On platforms that require explicit permission (iOS, Web, Windows),
  /// prompts the user to grant notification permissions. On platforms
  /// where permissions are granted by default (Android), this may be a no-op.
  ///
  /// Returns true if permission was granted, false if denied or on error.
  Future<bool> requestPermission();
}
