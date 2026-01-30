import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hex_buzz/presentation/providers/notification_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hex_buzz/domain/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationProvider Edge Cases', () {
    late MockNotificationService mockService;

    setUp(() {
      mockService = MockNotificationService();
    });

    test('setEnabled handles service errors gracefully', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockService)],
      );

      when(
        () => mockService.setEnabled(true),
      ).thenThrow(Exception('Permission denied'));

      // Should not throw
      await container
          .read(notificationNotifierProvider.notifier)
          .setEnabled(true);

      expect(container.read(notificationNotifierProvider), false);
    });

    test('setEnabled returns early if already enabled', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockService)],
      );

      when(() => mockService.setEnabled(true)).thenAnswer((_) async {});
      when(() => mockService.isEnabled()).thenReturn(true);

      await container
          .read(notificationNotifierProvider.notifier)
          .setEnabled(true);
      await container
          .read(notificationNotifierProvider.notifier)
          .setEnabled(true);

      // Should only call once
      verify(() => mockService.setEnabled(true)).called(1);
    });

    test('setEnabled with false disables notifications', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockService)],
      );

      when(() => mockService.setEnabled(false)).thenAnswer((_) async {});
      when(() => mockService.isEnabled()).thenReturn(false);

      await container
          .read(notificationNotifierProvider.notifier)
          .setEnabled(false);

      expect(container.read(notificationNotifierProvider), false);
      verify(() => mockService.setEnabled(false)).called(1);
    });

    test('sendTestNotification handles errors', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockService)],
      );

      when(
        () => mockService.sendNotification(any(), any()),
      ).thenThrow(Exception('Send failed'));

      // Should not throw
      await container
          .read(notificationNotifierProvider.notifier)
          .sendTestNotification();

      verify(() => mockService.sendNotification(any(), any())).called(1);
    });

    test('sendTestNotification sends with correct title and body', () async {
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockService)],
      );

      when(
        () => mockService.sendNotification(any(), any()),
      ).thenAnswer((_) async {});

      await container
          .read(notificationNotifierProvider.notifier)
          .sendTestNotification();

      verify(
        () => mockService.sendNotification(
          'Test Notification',
          'This is a test notification',
        ),
      ).called(1);
    });
  });
}
