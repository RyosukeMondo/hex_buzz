import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/services/notification_service.dart';

/// Firebase Cloud Messaging implementation of [NotificationService].
///
/// Handles push notifications for mobile (Android/iOS) and web platforms.
/// Manages device tokens, topic subscriptions, and message handling for
/// both foreground and background notifications.
class FCMNotificationService implements NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final String? _userId;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  FCMNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    String? userId,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _userId = userId;

  @override
  Future<bool> initialize() async {
    try {
      // Request permission first
      final permitted = await requestPermission();
      if (!permitted) {
        return false;
      }

      // Setup foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Setup background message handler (if app was in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      // Get and store device token if user is authenticated
      if (_userId != null) {
        final token = await getDeviceToken();
        if (token != null) {
          await _storeDeviceToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _storeDeviceToken(newToken);
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Handles messages received while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final data = <String, dynamic>{
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
    };
    _messageController.add(data);
  }

  /// Handles messages that opened the app from background or terminated state.
  void _handleBackgroundMessage(RemoteMessage message) {
    final data = <String, dynamic>{
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
    };
    _messageController.add(data);
  }

  /// Stores the device token in Firestore user document.
  Future<void> _storeDeviceToken(String token) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'deviceToken': token,
        'deviceTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail if user document doesn't exist yet
      // It will be created by the auth repository
    }
  }

  /// Disposes resources.
  void dispose() {
    _messageController.close();
  }
}

/// Top-level function for handling background messages.
///
/// This must be a top-level function (not a method) because it's called
/// by the Firebase messaging service in a separate isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are logged but not processed here
  // The app will handle them when it's opened via onMessageOpenedApp
}
