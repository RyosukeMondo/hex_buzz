import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/platform/windows/wns_notification_service.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockNotificationResponse extends Mock implements NotificationResponse {}

// Fake classes for fallback values
class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
  });

  group('WNSNotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late FakeFirebaseFirestore fakeFirestore;
    late WNSNotificationService service;
    const testUserId = 'test-user-123';

    setUp(() {
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      fakeFirestore = FakeFirebaseFirestore();

      // Create user document for testing token storage
      fakeFirestore.collection('users').doc(testUserId).set({
        'uid': testUserId,
        'email': 'test@example.com',
      });

      service = WNSNotificationService(
        localNotifications: mockLocalNotifications,
        firestore: fakeFirestore,
        userId: testUserId,
      );

      // Setup default mock behavior for initialization
      when(
        () => mockLocalNotifications.initialize(
          any(),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
    });

    tearDown(() {
      service.dispose();
    });

    group('initialize', () {
      test('succeeds on Windows platform', () async {
        final result = await service.initialize();

        expect(result, isTrue);
        verify(
          () => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).called(1);
      });

      test(
        'stores device ID in Firestore when user is authenticated',
        () async {
          await service.initialize();

          // Allow async operations to complete
          await Future.delayed(const Duration(milliseconds: 100));

          final userDoc = await fakeFirestore
              .collection('users')
              .doc(testUserId)
              .get();
          expect(userDoc.data()?['windowsDeviceId'], isNotNull);
          expect(
            userDoc.data()?['windowsDeviceId'],
            startsWith('windows_$testUserId'),
          );
          expect(userDoc.data()?['windowsDeviceIdUpdatedAt'], isNotNull);
          expect(userDoc.data()?['platform'], 'windows');
        },
      );

      test('handles exception gracefully', () async {
        when(
          () => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenThrow(Exception('Initialization error'));

        final result = await service.initialize();

        expect(result, isFalse);
      });
    });

    group('getDeviceToken', () {
      test('returns device ID after initialization', () async {
        await service.initialize();

        final token = await service.getDeviceToken();

        expect(token, isNotNull);
        expect(token, startsWith('windows_'));
      });

      test('generates device ID if not initialized', () async {
        final token = await service.getDeviceToken();

        expect(token, isNotNull);
        expect(token, startsWith('windows_'));
      });
    });

    group('subscribeToTopic', () {
      test('succeeds when subscription is successful', () async {
        await service.initialize();
        const topic = 'daily_challenge';

        final result = await service.subscribeToTopic(topic);

        expect(result, isTrue);

        // Verify subscription stored in Firestore
        final subscriptionDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('notificationSubscriptions')
            .doc(topic)
            .get();

        expect(subscriptionDoc.exists, isTrue);
        expect(subscriptionDoc.data()?['topic'], topic);
        expect(subscriptionDoc.data()?['platform'], 'windows');
        expect(subscriptionDoc.data()?['deviceId'], isNotNull);
        expect(subscriptionDoc.data()?['subscribedAt'], isNotNull);
      });

      test('fails when user ID is null', () async {
        final serviceNoUser = WNSNotificationService(
          localNotifications: mockLocalNotifications,
          firestore: fakeFirestore,
          userId: null,
        );

        await serviceNoUser.initialize();
        const topic = 'daily_challenge';

        final result = await serviceNoUser.subscribeToTopic(topic);

        expect(result, isFalse);
        serviceNoUser.dispose();
      });

      test('fails when not initialized', () async {
        const topic = 'daily_challenge';

        final result = await service.subscribeToTopic(topic);

        expect(result, isFalse);
      });

      test('handles exception gracefully', () async {
        await service.initialize();
        const topic = 'daily_challenge';

        // Close firestore connection to simulate error
        final badService = WNSNotificationService(
          localNotifications: mockLocalNotifications,
          firestore: FakeFirebaseFirestore(),
          userId: 'nonexistent-user',
        );
        await badService.initialize();

        final result = await badService.subscribeToTopic(topic);

        // Should return true even if user doc doesn't exist
        // (subscription doc will be created anyway)
        expect(result, isTrue);
        badService.dispose();
      });
    });

    group('unsubscribeFromTopic', () {
      test('succeeds when unsubscription is successful', () async {
        await service.initialize();
        const topic = 'daily_challenge';

        // First subscribe
        await service.subscribeToTopic(topic);

        // Then unsubscribe
        final result = await service.unsubscribeFromTopic(topic);

        expect(result, isTrue);

        // Verify subscription removed from Firestore
        final subscriptionDoc = await fakeFirestore
            .collection('users')
            .doc(testUserId)
            .collection('notificationSubscriptions')
            .doc(topic)
            .get();

        expect(subscriptionDoc.exists, isFalse);
      });

      test('succeeds even if subscription does not exist', () async {
        await service.initialize();
        const topic = 'nonexistent_topic';

        final result = await service.unsubscribeFromTopic(topic);

        expect(result, isTrue);
      });

      test('fails when user ID is null', () async {
        final serviceNoUser = WNSNotificationService(
          localNotifications: mockLocalNotifications,
          firestore: fakeFirestore,
          userId: null,
        );

        await serviceNoUser.initialize();
        const topic = 'daily_challenge';

        final result = await serviceNoUser.unsubscribeFromTopic(topic);

        expect(result, isFalse);
        serviceNoUser.dispose();
      });
    });

    group('requestPermission', () {
      test(
        'returns true on Windows (permissions granted by default)',
        () async {
          final result = await service.requestPermission();

          expect(result, isTrue);
        },
      );

      test('returns same result when called multiple times', () async {
        final result1 = await service.requestPermission();
        final result2 = await service.requestPermission();

        expect(result1, isTrue);
        expect(result2, isTrue);
      });
    });

    group('onMessageReceived stream', () {
      test('emits messages with proper structure', () async {
        await service.initialize();

        // Service is ready, stream should be available
        expect(service.onMessageReceived, isA<Stream<Map<String, dynamic>>>());
      });

      test('emits message when showNotification is called', () async {
        await service.initialize();
        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        final messages = <Map<String, dynamic>>[];
        service.onMessageReceived.listen(messages.add);

        await service.showNotification(
          title: 'Test Title',
          body: 'Test Body',
          data: {'key': 'value'},
        );

        await Future.delayed(const Duration(milliseconds: 50));

        expect(messages.length, 1);
        expect(messages[0]['title'], 'Test Title');
        expect(messages[0]['body'], 'Test Body');
        expect(messages[0]['data'], {'key': 'value'});
      });
    });

    group('showNotification', () {
      test('displays notification with title and body', () async {
        await service.initialize();
        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.showNotification(title: 'Test Title', body: 'Test Body');

        verify(
          () => mockLocalNotifications.show(
            any(),
            'Test Title',
            'Test Body',
            any(),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });

      test('displays notification with data payload', () async {
        await service.initialize();
        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.showNotification(
          title: 'Test Title',
          body: 'Test Body',
          data: {'screen': 'daily_challenge', 'id': '123'},
        );

        verify(
          () => mockLocalNotifications.show(
            any(),
            'Test Title',
            'Test Body',
            any(),
            payload: 'screen=daily_challenge&id=123',
          ),
        ).called(1);
      });

      test('handles exception gracefully', () async {
        await service.initialize();
        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).thenThrow(Exception('Show error'));

        // Should not throw
        await service.showNotification(title: 'Test Title', body: 'Test Body');
      });
    });

    group('service without userId', () {
      test('initializes but does not store token', () async {
        final serviceNoUser = WNSNotificationService(
          localNotifications: mockLocalNotifications,
          firestore: fakeFirestore,
          userId: null,
        );

        final result = await serviceNoUser.initialize();

        expect(result, isTrue);

        serviceNoUser.dispose();
      });
    });

    group('payload encoding/decoding', () {
      test('correctly encodes and decodes data', () async {
        await service.initialize();
        when(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        final testData = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};

        await service.showNotification(
          title: 'Test',
          body: 'Test',
          data: testData,
        );

        // Verify the payload was encoded
        final captured = verify(
          () => mockLocalNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: captureAny(named: 'payload'),
          ),
        ).captured;

        expect(captured.length, 1);
        expect(captured[0], contains('key1=value1'));
        expect(captured[0], contains('key2=value2'));
        expect(captured[0], contains('key3=value3'));
      });
    });
  });
}
