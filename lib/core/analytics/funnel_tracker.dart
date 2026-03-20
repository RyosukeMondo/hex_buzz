import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';

/// Tracks user progression through key conversion funnels.
///
/// Funnels are ordered sequences of steps that represent the user's journey
/// from install to long-term retention. Each funnel step is tracked only once
/// (persisted in SharedPreferences) to avoid double-counting.
///
/// Tracked funnels:
/// 1. Install -> First Game: User opens app and starts their first level
/// 2. First Game -> Completion: User completes their first level
/// 3. Completion -> Daily Challenge: User tries the daily challenge
/// 4. Daily -> Retention: User returns after completing a daily challenge
class FunnelTracker {
  final AnalyticsService _analytics;
  final SharedPreferences _prefs;

  static const String _funnelPrefix = 'funnel_';

  FunnelTracker({
    required AnalyticsService analytics,
    required SharedPreferences prefs,
  })  : _analytics = analytics,
        _prefs = prefs;

  /// Tracks the install-to-first-game funnel step.
  ///
  /// Called when the user starts their very first level. Fires
  /// [AnalyticsEventType.firstLevelStarted] exactly once per install.
  void trackInstallToFirstGame() {
    _trackFunnelStep(
      step: 'install_to_first_game',
      eventType: AnalyticsEventType.firstLevelStarted,
    );
  }

  /// Tracks the first-game-to-completion funnel step.
  ///
  /// Called when the user completes their very first level. Fires
  /// [AnalyticsEventType.firstLevelCompleted] exactly once per install.
  void trackFirstGameToCompletion() {
    _trackFunnelStep(
      step: 'first_game_to_completion',
      eventType: AnalyticsEventType.firstLevelCompleted,
    );
  }

  /// Tracks the completion-to-daily-challenge funnel step.
  ///
  /// Called when the user starts their first daily challenge. Fires
  /// [AnalyticsEventType.dailyChallengeStarted] as a funnel event
  /// exactly once per install.
  void trackCompletionToDailyChallenge() {
    _trackFunnelStep(
      step: 'completion_to_daily_challenge',
      eventType: AnalyticsEventType.dailyChallengeStarted,
      properties: {'funnelSource': 'first_completion'},
    );
  }

  /// Tracks the daily-to-retention funnel step.
  ///
  /// Called when the user returns after completing a daily challenge.
  /// Fires [AnalyticsEventType.dayRetention] as a funnel event exactly
  /// once per install.
  void trackDailyToRetention() {
    _trackFunnelStep(
      step: 'daily_to_retention',
      eventType: AnalyticsEventType.dayRetention,
      properties: {'funnelSource': 'daily_challenge'},
    );
  }

  /// Whether a specific funnel step has been completed.
  bool isStepCompleted(String step) {
    return _prefs.getBool('$_funnelPrefix$step') ?? false;
  }

  /// Tracks a funnel step if it hasn't been tracked before.
  ///
  /// Each step is persisted to SharedPreferences so it fires only once
  /// across app restarts.
  void _trackFunnelStep({
    required String step,
    required AnalyticsEventType eventType,
    Map<String, dynamic>? properties,
  }) {
    if (isStepCompleted(step)) return;

    _prefs.setBool('$_funnelPrefix$step', true);

    _analytics.trackEvent(
      eventType,
      properties: {
        'funnelStep': step,
        ...?properties,
      },
    );

    if (kDebugMode) {
      debugPrint('[Funnel] Step completed: $step');
    }
  }
}
