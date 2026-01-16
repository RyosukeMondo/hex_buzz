import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/services/notification_service.dart';

/// Windows Notification Service implementation of [NotificationService].
///
/// Handles push notifications for Windows platform using WNS (Windows Notification Service)
/// via flutter_local_notifications. Manages device tokens, topic subscriptions through
/// Firestore, and local notification display.
///
/// Note: Unlike FCM which handles server-side topic management, this implementation
/// stores topic subscriptions in Firestore and relies on Cloud Functions to query
/// and send notifications to subscribed Windows devices.
class WNSNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;
  final String? _userId;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Unique identifier for this Windows device.
  /// Used as a pseudo "device token" since WNS tokens are managed differently.
  String? _deviceId;

  /// Whether notification permission has been granted.
  bool _permissionGranted = false;

  WNSNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    String? userId,
  }) : _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
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

      // Initialize Linux notification settings (works on Windows too)
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      final initSettings = InitializationSettings(linux: linuxSettings);

      // Setup notification tap handler
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Generate or retrieve device ID
      _deviceId = await _getOrCreateDeviceId();

      // Store device ID in Firestore if user is authenticated
      if (_userId != null && _deviceId != null) {
        await _storeDeviceToken(_deviceId!);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      return _deviceId ?? await _getOrCreateDeviceId();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> subscribeToTopic(String topic) async {
    if (_userId == null || _deviceId == null) {
      return false;
    }

    try {
      // Store topic subscription in Firestore
      // Cloud Functions will query this to send notifications
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('notificationSubscriptions')
          .doc(topic)
          .set({
            'topic': topic,
            'deviceId': _deviceId,
            'platform': 'windows',
            'subscribedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> unsubscribeFromTopic(String topic) async {
    if (_userId == null) {
      return false;
    }

    try {
      // Remove topic subscription from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('notificationSubscriptions')
          .doc(topic)
          .delete();

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
    if (_permissionGranted) {
      return true;
    }

    try {
      // On Windows/Linux desktop platforms, notifications are generally allowed by default
      // Using Linux notification backend which works on both Windows and Linux
      _permissionGranted = true;
      return _permissionGranted;
    } catch (e) {
      return false;
    }
  }

  /// Displays a local notification.
  ///
  /// This method is called by the app when it receives notification data
  /// from Cloud Functions (via polling or other mechanism). It displays
  /// the notification using Linux notification backend (compatible with Windows).
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const linuxDetails = LinuxNotificationDetails();

      const notificationDetails = NotificationDetails(linux: linuxDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: data != null ? _encodePayload(data) : null,
      );

      // Emit to stream for in-app handling
      _messageController.add({
        'title': title,
        'body': body,
        'data': data ?? {},
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Handles notification tap events.
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _messageController.add({'title': '', 'body': '', 'data': data});
    }
  }

  /// Stores the device ID in Firestore user document.
  Future<void> _storeDeviceToken(String deviceId) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'windowsDeviceId': deviceId,
        'windowsDeviceIdUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'windows',
      });
    } catch (e) {
      // Silently fail if user document doesn't exist yet
      // It will be created by the auth repository
    }
  }

  /// Gets or creates a unique device ID for this Windows installation.
  ///
  /// Since WNS tokens are managed differently than FCM tokens,
  /// we generate a unique identifier for this device installation.
  Future<String> _getOrCreateDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }

    try {
      // In a real implementation, this would retrieve or generate
      // a persistent device ID (e.g., from registry or local storage)
      // For now, we'll use a combination of user ID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _deviceId = 'windows_${_userId ?? 'guest'}_$timestamp';
      return _deviceId!;
    } catch (e) {
      // Fallback to timestamp-based ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _deviceId = 'windows_fallback_$timestamp';
      return _deviceId!;
    }
  }

  /// Encodes a data map into a string payload.
  String _encodePayload(Map<String, dynamic> data) {
    // Simple encoding: join key-value pairs with delimiters
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decodes a string payload into a data map.
  Map<String, dynamic> _decodePayload(String payload) {
    final result = <String, dynamic>{};
    final pairs = payload.split('&');
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    return result;
  }

  /// Disposes resources.
  void dispose() {
    _messageController.close();
  }
}
