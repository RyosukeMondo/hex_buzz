import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase/fcm_notification_service.dart';
import '../../domain/services/notification_service.dart';
import '../../platform/windows/wns_notification_service.dart';

/// Provider for SharedPreferences instance.
///
/// Must be overridden in main.dart with initialized SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for NotificationService instance.
///
/// Must be overridden in main.dart with platform-specific implementation.
/// Uses FCM for mobile/web, WNS for Windows.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'NotificationService must be overridden in main.dart',
  );
});

/// Notification preferences keys for SharedPreferences.
class NotificationPrefs {
  static const String dailyChallengeKey = 'notification_daily_challenge';
  static const String rankChangeKey = 'notification_rank_change';
  static const String reEngagementKey = 'notification_re_engagement';

  NotificationPrefs._();
}

/// Creates a platform-specific notification service implementation.
///
/// Returns FCMNotificationService for mobile/web platforms,
/// or WNSNotificationService for Windows desktop.
///
/// The [userId] parameter is the currently authenticated user's ID,
/// used for storing device tokens in Firestore.
NotificationService createNotificationService({String? userId}) {
  // Use WNS for Windows platform
  if (!kIsWeb && Platform.isWindows) {
    if (kDebugMode) {
      debugPrint('Windows detected, using WNSNotificationService');
    }
    return WNSNotificationService(userId: userId);
  }

  // Use FCM for mobile and web platforms
  if (kDebugMode) {
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;
    debugPrint('Using FCMNotificationService for $platform');
  }
  return FCMNotificationService(userId: userId);
}

/// Initializes notification subscriptions based on user preferences.
///
/// Subscribes to notification topics that the user has enabled in their
/// preferences. Should be called after notification service initialization
/// and after user authentication.
Future<void> initializeNotificationSubscriptions(
  NotificationService notificationService,
  SharedPreferences prefs,
) async {
  try {
    final dailyChallengeEnabled =
        prefs.getBool(NotificationPrefs.dailyChallengeKey) ?? true;
    final rankChangeEnabled =
        prefs.getBool(NotificationPrefs.rankChangeKey) ?? true;
    final reEngagementEnabled =
        prefs.getBool(NotificationPrefs.reEngagementKey) ?? true;

    if (dailyChallengeEnabled) {
      await notificationService.subscribeToTopic('daily_challenge');
      if (kDebugMode) debugPrint('Subscribed to daily_challenge topic');
    }

    if (rankChangeEnabled) {
      await notificationService.subscribeToTopic('rank_changes');
      if (kDebugMode) debugPrint('Subscribed to rank_changes topic');
    }

    if (reEngagementEnabled) {
      await notificationService.subscribeToTopic('re_engagement');
      if (kDebugMode) debugPrint('Subscribed to re_engagement topic');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Failed to initialize subscriptions: $e');
  }
}
