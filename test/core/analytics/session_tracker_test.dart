import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/analytics/analytics_event.dart';
import 'package:hex_buzz/core/analytics/local_analytics_service.dart';
import 'package:hex_buzz/core/analytics/session_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionTracker tracker;
  late LocalAnalyticsService analytics;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = LocalAnalyticsService();
    tracker = SessionTracker(prefs: prefs, analytics: analytics);
  });

  group('SessionTracker', () {
    group('startSession', () {
      test('increments total session count', () async {
        expect(tracker.totalSessions, 0);

        await tracker.startSession();
        expect(tracker.totalSessions, 1);

        await tracker.startSession();
        expect(tracker.totalSessions, 2);
      });

      test('sets first session date on first call', () async {
        expect(tracker.firstSessionDate, isNull);

        await tracker.startSession();
        expect(tracker.firstSessionDate, isNotNull);
      });

      test('does not overwrite first session date', () async {
        await tracker.startSession();
        final firstDate = tracker.firstSessionDate;

        // Simulate a later session
        await tracker.startSession();
        expect(tracker.firstSessionDate, firstDate);
      });

      test('updates last session date', () async {
        await tracker.startSession();
        final firstLast = tracker.lastSessionDate;
        expect(firstLast, isNotNull);

        // Small delay to ensure different timestamp
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tracker.startSession();

        expect(
          tracker.lastSessionDate!.millisecondsSinceEpoch,
          greaterThanOrEqualTo(firstLast!.millisecondsSinceEpoch),
        );
      });

      test('fires sessionStarted event', () async {
        await tracker.startSession();

        expect(analytics.hasEvent(AnalyticsEventType.sessionStarted), true);
        final event = analytics.lastEventOfType(
          AnalyticsEventType.sessionStarted,
        );
        expect(event!.properties['sessionNumber'], 1);
        expect(event.properties['isFirstSession'], true);
      });

      test('marks isFirstSession false after first session', () async {
        await tracker.startSession();
        await tracker.startSession();

        final events = analytics.eventsOfType(
          AnalyticsEventType.sessionStarted,
        );
        expect(events.last.properties['isFirstSession'], false);
        expect(events.last.properties['sessionNumber'], 2);
      });
    });

    group('endSession', () {
      test('fires sessionEnded event with duration', () async {
        await tracker.startSession();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tracker.endSession();

        expect(analytics.hasEvent(AnalyticsEventType.sessionEnded), true);
        final event = analytics.lastEventOfType(
          AnalyticsEventType.sessionEnded,
        );
        expect(event!.properties['durationSeconds'], isA<int>());
        expect(event.properties['sessionNumber'], 1);
      });

      test('resets current session duration after end', () async {
        await tracker.startSession();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(tracker.currentSessionDuration, isNot(Duration.zero));

        await tracker.endSession();
        expect(tracker.currentSessionDuration, Duration.zero);
      });
    });

    group('currentSessionDuration', () {
      test('returns zero when no session active', () {
        expect(tracker.currentSessionDuration, Duration.zero);
      });

      test('returns non-zero during active session', () async {
        await tracker.startSession();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          tracker.currentSessionDuration.inMilliseconds,
          greaterThan(0),
        );
      });
    });

    group('retention', () {
      test('isDay1Retained returns false with no sessions', () {
        expect(tracker.isDay1Retained(), false);
      });

      test('isDay1Retained returns false on first day only', () async {
        await tracker.startSession();
        expect(tracker.isDay1Retained(), false);
      });

      test('isDay1Retained returns true when sessions span 1+ days', () async {
        // Simulate first session yesterday
        final yesterday = DateTime.now().subtract(const Duration(days: 2));
        await prefs.setString(
          'session_first_date',
          yesterday.toIso8601String(),
        );
        await prefs.setStringList('session_unique_dates', [
          DateTime(yesterday.year, yesterday.month, yesterday.day)
              .toIso8601String(),
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ).toIso8601String(),
        ]);

        expect(tracker.isDay1Retained(), true);
      });

      test('isDay7Retained returns false with only recent sessions', () async {
        await tracker.startSession();
        expect(tracker.isDay7Retained(), false);
      });

      test('isDay7Retained returns true when sessions span 7+ days', () async {
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        await prefs.setString(
          'session_first_date',
          eightDaysAgo.toIso8601String(),
        );
        await prefs.setStringList('session_unique_dates', [
          DateTime(eightDaysAgo.year, eightDaysAgo.month, eightDaysAgo.day)
              .toIso8601String(),
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ).toIso8601String(),
        ]);

        expect(tracker.isDay7Retained(), true);
      });
    });

    group('persistence', () {
      test('session count persists across tracker instances', () async {
        await tracker.startSession();
        await tracker.startSession();

        // Create new tracker with same prefs
        final newTracker = SessionTracker(
          prefs: prefs,
          analytics: analytics,
        );

        expect(newTracker.totalSessions, 2);
      });

      test('first session date persists across tracker instances', () async {
        await tracker.startSession();
        final firstDate = tracker.firstSessionDate;

        final newTracker = SessionTracker(
          prefs: prefs,
          analytics: analytics,
        );

        expect(newTracker.firstSessionDate, firstDate);
      });
    });
  });
}
