import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/firebase/fcm_notification_service.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockRemoteNotification extends Mock implements RemoteNotification {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  group('FCMNotificationService', () {
    late MockFirebaseMessaging mockMessaging;
    late FakeFirebaseFirestore fakeFirestore;
    late FCMNotificationService service;
    const testUserId = 'test-user-123';
    const testToken = 'test-fcm-token-abc123';

    setUp(() {
      mockMessaging = MockFirebaseMessaging();
      fakeFirestore = FakeFirebaseFirestore();

      // Create user document for testing token storage
      fakeFirestore.collection('users').doc(testUserId).set({
        'uid': testUserId,
        'email': 'test@example.com',
      });

      service = FCMNotificationService(
        messaging: mockMessaging,
        firestore: fakeFirestore,
        userId: testUserId,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('initialize', () {
      test('succeeds when permission is granted', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);
        when(() => mockMessaging.getToken()).thenAnswer((_) async => testToken);
        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);
        when(
          () => mockMessaging.onTokenRefresh,
        ).thenAnswer((_) => Stream.value(testToken));

        final result = await service.initialize();

        expect(result, isTrue);
        verify(
          () => mockMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            announcement: false,
            carPlay: false,
            criticalAlert: false,
          ),
        ).called(1);
        verify(() => mockMessaging.getToken()).called(1);
      });

      test('fails when permission is denied', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.initialize();

        expect(result, isFalse);
        verifyNever(() => mockMessaging.getToken());
      });

      test('succeeds with provisional authorization', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.provisional);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);
        when(() => mockMessaging.getToken()).thenAnswer((_) async => testToken);
        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);
        when(
          () => mockMessaging.onTokenRefresh,
        ).thenAnswer((_) => Stream.value(testToken));

        final result = await service.initialize();

        expect(result, isTrue);
      });

      test(
        'stores device token in Firestore when user is authenticated',
        () async {
          final mockSettings = MockNotificationSettings();
          when(
            () => mockSettings.authorizationStatus,
          ).thenReturn(AuthorizationStatus.authorized);
          when(
            () => mockMessaging.requestPermission(
              alert: any(named: 'alert'),
              badge: any(named: 'badge'),
              sound: any(named: 'sound'),
              provisional: any(named: 'provisional'),
              announcement: any(named: 'announcement'),
              carPlay: any(named: 'carPlay'),
              criticalAlert: any(named: 'criticalAlert'),
            ),
          ).thenAnswer((_) async => mockSettings);
          when(
            () => mockMessaging.getToken(),
          ).thenAnswer((_) async => testToken);
          when(
            () => mockMessaging.getInitialMessage(),
          ).thenAnswer((_) async => null);
          when(
            () => mockMessaging.onTokenRefresh,
          ).thenAnswer((_) => Stream.value(testToken));

          await service.initialize();

          // Allow async operations to complete
          await Future.delayed(const Duration(milliseconds: 100));

          final userDoc = await fakeFirestore
              .collection('users')
              .doc(testUserId)
              .get();
          expect(userDoc.data()?['deviceToken'], testToken);
          expect(userDoc.data()?['deviceTokenUpdatedAt'], isNotNull);
        },
      );

      test('handles exception gracefully', () async {
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenThrow(Exception('Permission error'));

        final result = await service.initialize();

        expect(result, isFalse);
      });
    });

    group('getDeviceToken', () {
      test('returns token when available', () async {
        when(() => mockMessaging.getToken()).thenAnswer((_) async => testToken);

        final token = await service.getDeviceToken();

        expect(token, testToken);
        verify(() => mockMessaging.getToken()).called(1);
      });

      test('returns null on error', () async {
        when(
          () => mockMessaging.getToken(),
        ).thenThrow(Exception('Token error'));

        final token = await service.getDeviceToken();

        expect(token, isNull);
      });
    });

    group('subscribeToTopic', () {
      test('succeeds when subscription is successful', () async {
        const topic = 'daily_challenge';
        when(
          () => mockMessaging.subscribeToTopic(topic),
        ).thenAnswer((_) async {});

        final result = await service.subscribeToTopic(topic);

        expect(result, isTrue);
        verify(() => mockMessaging.subscribeToTopic(topic)).called(1);
      });

      test('fails when subscription throws error', () async {
        const topic = 'daily_challenge';
        when(
          () => mockMessaging.subscribeToTopic(topic),
        ).thenThrow(Exception('Subscription error'));

        final result = await service.subscribeToTopic(topic);

        expect(result, isFalse);
      });
    });

    group('unsubscribeFromTopic', () {
      test('succeeds when unsubscription is successful', () async {
        const topic = 'daily_challenge';
        when(
          () => mockMessaging.unsubscribeFromTopic(topic),
        ).thenAnswer((_) async {});

        final result = await service.unsubscribeFromTopic(topic);

        expect(result, isTrue);
        verify(() => mockMessaging.unsubscribeFromTopic(topic)).called(1);
      });

      test('fails when unsubscription throws error', () async {
        const topic = 'daily_challenge';
        when(
          () => mockMessaging.unsubscribeFromTopic(topic),
        ).thenThrow(Exception('Unsubscription error'));

        final result = await service.unsubscribeFromTopic(topic);

        expect(result, isFalse);
      });
    });

    group('requestPermission', () {
      test('returns true when permission is granted', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, isTrue);
      });

      test('returns true when permission is provisional', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.provisional);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, isTrue);
      });

      test('returns false when permission is denied', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, isFalse);
      });

      test('returns false when permission is not determined', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.notDetermined);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, isFalse);
      });

      test('returns false on exception', () async {
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenThrow(Exception('Permission error'));

        final result = await service.requestPermission();

        expect(result, isFalse);
      });
    });

    group('onMessageReceived stream', () {
      test('emits messages with proper structure', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);
        when(() => mockMessaging.getToken()).thenAnswer((_) async => testToken);
        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);
        when(
          () => mockMessaging.onTokenRefresh,
        ).thenAnswer((_) => const Stream.empty());

        await service.initialize();

        // Service is ready, stream should be available
        expect(service.onMessageReceived, isA<Stream<Map<String, dynamic>>>());
      });
    });

    group('service without userId', () {
      test('initializes but does not store token', () async {
        final serviceNoUser = FCMNotificationService(
          messaging: mockMessaging,
          firestore: fakeFirestore,
          userId: null,
        );

        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
            announcement: any(named: 'announcement'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
          ),
        ).thenAnswer((_) async => mockSettings);
        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);

        final result = await serviceNoUser.initialize();

        expect(result, isTrue);
        // Token should not be requested when userId is null
        verifyNever(() => mockMessaging.getToken());

        serviceNoUser.dispose();
      });
    });
  });
}
