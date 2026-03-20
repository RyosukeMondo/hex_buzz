import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/analytics/analytics_event.dart';
import 'package:hex_buzz/core/analytics/local_analytics_service.dart';

void main() {
  late LocalAnalyticsService service;

  setUp(() {
    service = LocalAnalyticsService();
  });

  group('LocalAnalyticsService', () {
    group('initialize', () {
      test('sets initialized flag', () async {
        expect(service.initialized, false);
        await service.initialize();
        expect(service.initialized, true);
      });

      test('is idempotent', () async {
        await service.initialize();
        await service.initialize();
        expect(service.initialized, true);
      });
    });

    group('trackEvent', () {
      test('records event with type', () {
        service.trackEvent(AnalyticsEventType.appOpened);

        expect(service.events, hasLength(1));
        expect(service.events.first.type, AnalyticsEventType.appOpened);
      });

      test('records event with properties', () {
        service.trackEvent(
          AnalyticsEventType.levelCompleted,
          properties: {'levelIndex': 3, 'stars': 2},
        );

        final event = service.events.first;
        expect(event.properties['levelIndex'], 3);
        expect(event.properties['stars'], 2);
      });

      test('records multiple events in order', () {
        service.trackEvent(AnalyticsEventType.sessionStarted);
        service.trackEvent(AnalyticsEventType.appOpened);
        service.trackEvent(AnalyticsEventType.levelStarted);

        expect(service.events, hasLength(3));
        expect(service.events[0].type, AnalyticsEventType.sessionStarted);
        expect(service.events[1].type, AnalyticsEventType.appOpened);
        expect(service.events[2].type, AnalyticsEventType.levelStarted);
      });

      test('records timestamp on each event', () {
        final before = DateTime.now();
        service.trackEvent(AnalyticsEventType.appOpened);
        final after = DateTime.now();

        final eventTime = service.events.first.timestamp;
        expect(
          eventTime.isAfter(before.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(
          eventTime.isBefore(after.add(const Duration(seconds: 1))),
          true,
        );
      });

      test('handles null properties as empty map', () {
        service.trackEvent(AnalyticsEventType.appOpened);

        expect(service.events.first.properties, isEmpty);
      });
    });

    group('setUserId', () {
      test('sets user ID', () {
        service.setUserId('user-123');
        expect(service.userId, 'user-123');
      });

      test('clears user ID with null', () {
        service.setUserId('user-123');
        service.setUserId(null);
        expect(service.userId, isNull);
      });
    });

    group('setUserProperty', () {
      test('sets a user property', () {
        service.setUserProperty('plan', 'premium');
        expect(service.userProperties['plan'], 'premium');
      });

      test('overwrites existing property', () {
        service.setUserProperty('plan', 'free');
        service.setUserProperty('plan', 'premium');
        expect(service.userProperties['plan'], 'premium');
      });

      test('sets multiple properties', () {
        service.setUserProperty('plan', 'premium');
        service.setUserProperty('region', 'us');

        expect(service.userProperties, hasLength(2));
        expect(service.userProperties['plan'], 'premium');
        expect(service.userProperties['region'], 'us');
      });
    });

    group('flush', () {
      test('completes without error', () async {
        service.trackEvent(AnalyticsEventType.appOpened);
        await expectLater(service.flush(), completes);
      });

      test('does not clear events', () async {
        service.trackEvent(AnalyticsEventType.appOpened);
        await service.flush();
        expect(service.events, hasLength(1));
      });
    });

    group('query helpers', () {
      setUp(() {
        service.trackEvent(AnalyticsEventType.sessionStarted);
        service.trackEvent(
          AnalyticsEventType.levelStarted,
          properties: {'level': 1},
        );
        service.trackEvent(
          AnalyticsEventType.levelCompleted,
          properties: {'level': 1},
        );
        service.trackEvent(
          AnalyticsEventType.levelStarted,
          properties: {'level': 2},
        );
      });

      test('eventsOfType returns matching events', () {
        final starts = service.eventsOfType(AnalyticsEventType.levelStarted);
        expect(starts, hasLength(2));
      });

      test('eventsOfType returns empty for no matches', () {
        final hints = service.eventsOfType(AnalyticsEventType.hintUsed);
        expect(hints, isEmpty);
      });

      test('lastEventOfType returns most recent match', () {
        final last = service.lastEventOfType(AnalyticsEventType.levelStarted);
        expect(last, isNotNull);
        expect(last!.properties['level'], 2);
      });

      test('lastEventOfType returns null for no matches', () {
        final last = service.lastEventOfType(AnalyticsEventType.hintUsed);
        expect(last, isNull);
      });

      test('hasEvent returns true when event exists', () {
        expect(service.hasEvent(AnalyticsEventType.sessionStarted), true);
      });

      test('hasEvent returns false when event does not exist', () {
        expect(service.hasEvent(AnalyticsEventType.hintUsed), false);
      });
    });

    group('reset', () {
      test('clears all data', () {
        service.trackEvent(AnalyticsEventType.appOpened);
        service.setUserId('user-123');
        service.setUserProperty('plan', 'premium');

        service.reset();

        expect(service.events, isEmpty);
        expect(service.userId, isNull);
        expect(service.userProperties, isEmpty);
        expect(service.initialized, false);
      });
    });
  });
}
