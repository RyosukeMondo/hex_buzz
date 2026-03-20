import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/analytics/analytics_event.dart';
import 'package:hex_buzz/core/analytics/analytics_service.dart';
import 'package:hex_buzz/core/analytics/funnel_tracker.dart';
import 'package:hex_buzz/core/analytics/local_analytics_service.dart';
import 'package:hex_buzz/core/analytics/session_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AnalyticsService contract', () {
    late AnalyticsService service;

    setUp(() {
      service = LocalAnalyticsService();
    });

    test('initialize completes without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('trackEvent does not throw', () {
      expect(
        () => service.trackEvent(AnalyticsEventType.appOpened),
        returnsNormally,
      );
    });

    test('trackEvent with properties does not throw', () {
      expect(
        () => service.trackEvent(
          AnalyticsEventType.levelCompleted,
          properties: {'stars': 3, 'timeMs': 45000},
        ),
        returnsNormally,
      );
    });

    test('setUserId accepts string', () {
      expect(() => service.setUserId('user-123'), returnsNormally);
    });

    test('setUserId accepts null', () {
      expect(() => service.setUserId(null), returnsNormally);
    });

    test('setUserProperty does not throw', () {
      expect(
        () => service.setUserProperty('plan', 'premium'),
        returnsNormally,
      );
    });

    test('flush completes without error', () async {
      service.trackEvent(AnalyticsEventType.appOpened);
      await expectLater(service.flush(), completes);
    });
  });

  group('Event tracking records correct data', () {
    late LocalAnalyticsService service;

    setUp(() {
      service = LocalAnalyticsService();
    });

    test('records event type correctly', () {
      service.trackEvent(AnalyticsEventType.levelStarted);

      expect(service.events, hasLength(1));
      expect(service.events.first.type, AnalyticsEventType.levelStarted);
    });

    test('records properties correctly', () {
      service.trackEvent(
        AnalyticsEventType.levelCompleted,
        properties: {
          'levelIndex': 5,
          'stars': 3,
          'completionTimeMs': 30000,
        },
      );

      final event = service.events.first;
      expect(event.properties['levelIndex'], 5);
      expect(event.properties['stars'], 3);
      expect(event.properties['completionTimeMs'], 30000);
    });

    test('records timestamp on each event', () {
      final before = DateTime.now();
      service.trackEvent(AnalyticsEventType.appOpened);
      final after = DateTime.now();

      final event = service.events.first;
      expect(
        event.timestamp.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch - 1000),
      );
      expect(
        event.timestamp.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch + 1000),
      );
    });

    test('records events in chronological order', () {
      service.trackEvent(AnalyticsEventType.sessionStarted);
      service.trackEvent(AnalyticsEventType.appOpened);
      service.trackEvent(AnalyticsEventType.levelStarted);
      service.trackEvent(AnalyticsEventType.levelCompleted);

      expect(service.events[0].type, AnalyticsEventType.sessionStarted);
      expect(service.events[1].type, AnalyticsEventType.appOpened);
      expect(service.events[2].type, AnalyticsEventType.levelStarted);
      expect(service.events[3].type, AnalyticsEventType.levelCompleted);
    });
  });

  group('Session tracker correctly counts sessions', () {
    late SessionTracker tracker;
    late LocalAnalyticsService analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      analytics = LocalAnalyticsService();
      tracker = SessionTracker(prefs: prefs, analytics: analytics);
    });

    test('starts at zero sessions', () {
      expect(tracker.totalSessions, 0);
    });

    test('increments count on each startSession', () async {
      await tracker.startSession();
      expect(tracker.totalSessions, 1);

      await tracker.startSession();
      expect(tracker.totalSessions, 2);

      await tracker.startSession();
      expect(tracker.totalSessions, 3);
    });

    test('tracks session duration', () async {
      await tracker.startSession();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        tracker.currentSessionDuration.inMilliseconds,
        greaterThan(0),
      );
    });

    test('emits sessionStarted and sessionEnded events', () async {
      await tracker.startSession();
      await tracker.endSession();

      expect(analytics.hasEvent(AnalyticsEventType.sessionStarted), true);
      expect(analytics.hasEvent(AnalyticsEventType.sessionEnded), true);
    });

    test('reports retention correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Set up data as if first session was 2 days ago
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await prefs.setString(
        'session_first_date',
        twoDaysAgo.toIso8601String(),
      );
      await prefs.setStringList('session_unique_dates', [
        DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day)
            .toIso8601String(),
        DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ).toIso8601String(),
      ]);

      final retainedTracker = SessionTracker(
        prefs: prefs,
        analytics: analytics,
      );

      expect(retainedTracker.isDay1Retained(), true);
      expect(retainedTracker.isDay7Retained(), false);
    });
  });

  group('Funnel tracker fires events in order', () {
    late FunnelTracker funnel;
    late LocalAnalyticsService analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      analytics = LocalAnalyticsService();
      funnel = FunnelTracker(analytics: analytics, prefs: prefs);
    });

    test('tracks full funnel progression', () {
      funnel.trackInstallToFirstGame();
      funnel.trackFirstGameToCompletion();
      funnel.trackCompletionToDailyChallenge();
      funnel.trackDailyToRetention();

      expect(analytics.events, hasLength(4));

      // Verify correct event types in order
      expect(
        analytics.events[0].type,
        AnalyticsEventType.firstLevelStarted,
      );
      expect(
        analytics.events[1].type,
        AnalyticsEventType.firstLevelCompleted,
      );
      expect(
        analytics.events[2].type,
        AnalyticsEventType.dailyChallengeStarted,
      );
      expect(
        analytics.events[3].type,
        AnalyticsEventType.dayRetention,
      );
    });

    test('each step fires only once (deduplication)', () {
      // Fire each step twice
      funnel.trackInstallToFirstGame();
      funnel.trackInstallToFirstGame();
      funnel.trackFirstGameToCompletion();
      funnel.trackFirstGameToCompletion();

      // Only 2 events should exist (one per unique step)
      expect(analytics.events, hasLength(2));
    });

    test('funnel step events include step metadata', () {
      funnel.trackInstallToFirstGame();

      final event = analytics.events.first;
      expect(event.properties.containsKey('funnelStep'), true);
      expect(event.properties['funnelStep'], 'install_to_first_game');
    });
  });

  group('User properties are set correctly', () {
    late LocalAnalyticsService service;

    setUp(() {
      service = LocalAnalyticsService();
    });

    test('sets single property', () {
      service.setUserProperty('subscription', 'premium');
      expect(service.userProperties['subscription'], 'premium');
    });

    test('sets multiple properties', () {
      service.setUserProperty('subscription', 'premium');
      service.setUserProperty('region', 'us-east');
      service.setUserProperty('level', '42');

      expect(service.userProperties, hasLength(3));
      expect(service.userProperties['subscription'], 'premium');
      expect(service.userProperties['region'], 'us-east');
      expect(service.userProperties['level'], '42');
    });

    test('overwrites existing property', () {
      service.setUserProperty('subscription', 'free');
      service.setUserProperty('subscription', 'premium');

      expect(service.userProperties['subscription'], 'premium');
      expect(service.userProperties, hasLength(1));
    });

    test('userId is tracked separately from properties', () {
      service.setUserId('user-abc');
      service.setUserProperty('name', 'test');

      expect(service.userId, 'user-abc');
      expect(service.userProperties.containsKey('userId'), false);
    });

    test('userId can be cleared', () {
      service.setUserId('user-abc');
      service.setUserId(null);

      expect(service.userId, isNull);
    });
  });
}
