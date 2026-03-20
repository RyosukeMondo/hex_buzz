import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/analytics/analytics_event.dart';
import 'package:hex_buzz/core/analytics/funnel_tracker.dart';
import 'package:hex_buzz/core/analytics/local_analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FunnelTracker funnel;
  late LocalAnalyticsService analytics;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = LocalAnalyticsService();
    funnel = FunnelTracker(analytics: analytics, prefs: prefs);
  });

  group('FunnelTracker', () {
    group('trackInstallToFirstGame', () {
      test('fires firstLevelStarted event', () {
        funnel.trackInstallToFirstGame();

        expect(
          analytics.hasEvent(AnalyticsEventType.firstLevelStarted),
          true,
        );
        final event = analytics.lastEventOfType(
          AnalyticsEventType.firstLevelStarted,
        );
        expect(event!.properties['funnelStep'], 'install_to_first_game');
      });

      test('fires only once', () {
        funnel.trackInstallToFirstGame();
        funnel.trackInstallToFirstGame();
        funnel.trackInstallToFirstGame();

        final events = analytics.eventsOfType(
          AnalyticsEventType.firstLevelStarted,
        );
        expect(events, hasLength(1));
      });

      test('marks step as completed', () {
        funnel.trackInstallToFirstGame();
        expect(funnel.isStepCompleted('install_to_first_game'), true);
      });
    });

    group('trackFirstGameToCompletion', () {
      test('fires firstLevelCompleted event', () {
        funnel.trackFirstGameToCompletion();

        expect(
          analytics.hasEvent(AnalyticsEventType.firstLevelCompleted),
          true,
        );
        final event = analytics.lastEventOfType(
          AnalyticsEventType.firstLevelCompleted,
        );
        expect(event!.properties['funnelStep'], 'first_game_to_completion');
      });

      test('fires only once', () {
        funnel.trackFirstGameToCompletion();
        funnel.trackFirstGameToCompletion();

        final events = analytics.eventsOfType(
          AnalyticsEventType.firstLevelCompleted,
        );
        expect(events, hasLength(1));
      });
    });

    group('trackCompletionToDailyChallenge', () {
      test('fires dailyChallengeStarted event with funnel source', () {
        funnel.trackCompletionToDailyChallenge();

        expect(
          analytics.hasEvent(AnalyticsEventType.dailyChallengeStarted),
          true,
        );
        final event = analytics.lastEventOfType(
          AnalyticsEventType.dailyChallengeStarted,
        );
        expect(event!.properties['funnelSource'], 'first_completion');
        expect(
          event.properties['funnelStep'],
          'completion_to_daily_challenge',
        );
      });

      test('fires only once', () {
        funnel.trackCompletionToDailyChallenge();
        funnel.trackCompletionToDailyChallenge();

        final events = analytics.eventsOfType(
          AnalyticsEventType.dailyChallengeStarted,
        );
        expect(events, hasLength(1));
      });
    });

    group('trackDailyToRetention', () {
      test('fires dayRetention event with funnel source', () {
        funnel.trackDailyToRetention();

        expect(
          analytics.hasEvent(AnalyticsEventType.dayRetention),
          true,
        );
        final event = analytics.lastEventOfType(
          AnalyticsEventType.dayRetention,
        );
        expect(event!.properties['funnelSource'], 'daily_challenge');
        expect(event.properties['funnelStep'], 'daily_to_retention');
      });

      test('fires only once', () {
        funnel.trackDailyToRetention();
        funnel.trackDailyToRetention();

        final events = analytics.eventsOfType(
          AnalyticsEventType.dayRetention,
        );
        expect(events, hasLength(1));
      });
    });

    group('funnel ordering', () {
      test('tracks all steps in order', () {
        funnel.trackInstallToFirstGame();
        funnel.trackFirstGameToCompletion();
        funnel.trackCompletionToDailyChallenge();
        funnel.trackDailyToRetention();

        expect(analytics.events, hasLength(4));
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

      test('steps are independent (can be tracked in any order)', () {
        funnel.trackDailyToRetention();
        funnel.trackInstallToFirstGame();

        expect(analytics.events, hasLength(2));
        expect(
          analytics.events[0].type,
          AnalyticsEventType.dayRetention,
        );
        expect(
          analytics.events[1].type,
          AnalyticsEventType.firstLevelStarted,
        );
      });
    });

    group('isStepCompleted', () {
      test('returns false for untracked steps', () {
        expect(funnel.isStepCompleted('install_to_first_game'), false);
        expect(funnel.isStepCompleted('first_game_to_completion'), false);
      });

      test('returns true after tracking', () {
        funnel.trackInstallToFirstGame();
        expect(funnel.isStepCompleted('install_to_first_game'), true);
        expect(funnel.isStepCompleted('first_game_to_completion'), false);
      });
    });

    group('persistence', () {
      test('completed steps persist across tracker instances', () {
        funnel.trackInstallToFirstGame();
        funnel.trackFirstGameToCompletion();

        // Create new tracker with same prefs
        final newAnalytics = LocalAnalyticsService();
        final newFunnel = FunnelTracker(
          analytics: newAnalytics,
          prefs: prefs,
        );

        // Steps should already be marked as completed
        expect(newFunnel.isStepCompleted('install_to_first_game'), true);
        expect(newFunnel.isStepCompleted('first_game_to_completion'), true);

        // Should not fire duplicate events
        newFunnel.trackInstallToFirstGame();
        newFunnel.trackFirstGameToCompletion();
        expect(newAnalytics.events, isEmpty);
      });
    });
  });
}
