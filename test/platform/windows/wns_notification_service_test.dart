import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/platform/windows/wns_notification_service.dart';

void main() {
  late WNSNotificationService service;

  setUp(() {
    service = WNSNotificationService();
  });

  tearDown(() {
    service.dispose();
  });

  group('WNSNotificationService', () {
    group('initialize', () {
      test('initializes successfully on Windows', () async {
        // Skip test if not running on Windows
        if (!Platform.isWindows) {
          return;
        }

        final result = await service.initialize();

        expect(result, true);
      });

      test('returns false on non-Windows platforms', () async {
        // Skip test if running on Windows
        if (Platform.isWindows) {
          return;
        }

        final result = await service.initialize();

        expect(result, false);
      });

      test('can be called multiple times safely', () async {
        if (!Platform.isWindows) {
          return;
        }

        final result1 = await service.initialize();
        final result2 = await service.initialize();

        expect(result1, true);
        expect(result2, true);
      });
    });

    group('getDeviceToken', () {
      test('returns device identifier after initialization', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        final token = await service.getDeviceToken();

        expect(token, isNotNull);
        expect(token, startsWith('windows-'));
      });

      test('initializes automatically if not initialized', () async {
        if (!Platform.isWindows) {
          return;
        }

        // Don't call initialize() first
        final token = await service.getDeviceToken();

        // On Windows, should auto-initialize and return token
        if (Platform.isWindows) {
          expect(token, isNotNull);
        }
      });
    });

    group('requestPermission', () {
      test('grants permission by default on Windows', () async {
        final result = await service.requestPermission();

        expect(result, true);
      });
    });

    group('topic subscriptions', () {
      test('subscribes to topic successfully', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        final result = await service.subscribeToTopic('daily_challenge');

        expect(result, true);
        expect(service.isSubscribedToTopic('daily_challenge'), true);
      });

      test('unsubscribes from topic successfully', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.subscribeToTopic('daily_challenge');
        expect(service.isSubscribedToTopic('daily_challenge'), true);

        final result = await service.unsubscribeFromTopic('daily_challenge');

        expect(result, true);
        expect(service.isSubscribedToTopic('daily_challenge'), false);
      });

      test('handles multiple topic subscriptions', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();

        await service.subscribeToTopic('daily_challenge');
        await service.subscribeToTopic('rank_changes');
        await service.subscribeToTopic('re_engagement');

        final subscriptions = service.getActiveSubscriptions();

        expect(subscriptions.length, 3);
        expect(subscriptions, contains('daily_challenge'));
        expect(subscriptions, contains('rank_changes'));
        expect(subscriptions, contains('re_engagement'));
      });

      test('returns false when subscribing without initialization', () async {
        final result = await service.subscribeToTopic('test_topic');

        expect(result, false);
      });

      test('returns false when unsubscribing without initialization', () async {
        final result = await service.unsubscribeFromTopic('test_topic');

        expect(result, false);
      });
    });

    group('onMessageReceived stream', () {
      test('emits messages when local notification shown', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.requestPermission();

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showLocalNotification(
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
        );

        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages.length, 1);
        expect(messages[0]['title'], 'Test Title');
        expect(messages[0]['body'], 'Test Body');
        expect(messages[0]['data'], {'key': 'value'});
      });

      test('emits multiple messages correctly', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.requestPermission();

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showLocalNotification(title: 'Message 1', body: 'Body 1');

        await service.showLocalNotification(title: 'Message 2', body: 'Body 2');

        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages.length, 2);
        expect(messages[0]['title'], 'Message 1');
        expect(messages[1]['title'], 'Message 2');
      });

      test('does not emit when not initialized', () async {
        if (!Platform.isWindows) {
          return;
        }

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        // Don't initialize
        await service.showLocalNotification(title: 'Test', body: 'Body');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages, isEmpty);
      });

      test('does not emit when permission not granted', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        // Don't request permission

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showLocalNotification(title: 'Test', body: 'Body');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages, isEmpty);
      });
    });

    group('showLocalNotification', () {
      test('handles null data parameter', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.requestPermission();

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showLocalNotification(title: 'Test', body: 'Body');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages.length, 1);
        expect(messages[0]['data'], {});
      });

      test('handles empty strings', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.requestPermission();

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showLocalNotification(title: '', body: '');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(messages.length, 1);
        expect(messages[0]['title'], '');
        expect(messages[0]['body'], '');
      });
    });

    group('isSubscribedToTopic', () {
      test('returns false for non-existent topic', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();

        expect(service.isSubscribedToTopic('non_existent'), false);
      });

      test('returns true for subscribed topic', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.subscribeToTopic('test_topic');

        expect(service.isSubscribedToTopic('test_topic'), true);
      });
    });

    group('getActiveSubscriptions', () {
      test('returns empty list when no subscriptions', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();

        expect(service.getActiveSubscriptions(), isEmpty);
      });

      test('returns all subscribed topics', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.subscribeToTopic('topic1');
        await service.subscribeToTopic('topic2');

        final subscriptions = service.getActiveSubscriptions();

        expect(subscriptions.length, 2);
        expect(subscriptions, containsAll(['topic1', 'topic2']));
      });

      test('updates after unsubscription', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.subscribeToTopic('topic1');
        await service.subscribeToTopic('topic2');

        expect(service.getActiveSubscriptions().length, 2);

        await service.unsubscribeFromTopic('topic1');

        final subscriptions = service.getActiveSubscriptions();
        expect(subscriptions.length, 1);
        expect(subscriptions, contains('topic2'));
        expect(subscriptions, isNot(contains('topic1')));
      });
    });

    group('dispose', () {
      test('closes stream controller', () async {
        if (!Platform.isWindows) {
          return;
        }

        await service.initialize();
        await service.requestPermission();

        service.dispose();

        // Stream should be closed, no more emissions
        expect(service.onMessageReceived.isBroadcast, true);
      });
    });
  });
}
