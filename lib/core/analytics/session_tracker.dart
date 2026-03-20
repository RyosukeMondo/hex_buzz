import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_event.dart';
import 'analytics_service.dart';

/// Tracks user sessions for retention and engagement analytics.
///
/// A session starts when the app is opened and ends when the app goes to
/// background or is closed. The tracker persists session history in
/// SharedPreferences for retention calculations across app restarts.
///
/// Retention metrics:
/// - Day 1: User returned at least 1 day after first session
/// - Day 7: User returned at least 7 days after first session
class SessionTracker {
  final SharedPreferences _prefs;
  final AnalyticsService _analytics;

  DateTime? _currentSessionStart;

  static const String _totalSessionsKey = 'session_total_count';
  static const String _firstSessionDateKey = 'session_first_date';
  static const String _lastSessionDateKey = 'session_last_date';
  static const String _sessionDatesKey = 'session_unique_dates';

  SessionTracker({
    required SharedPreferences prefs,
    required AnalyticsService analytics,
  })  : _prefs = prefs,
        _analytics = analytics;

  /// Starts a new session and records it.
  ///
  /// Increments the session count, updates first/last session dates,
  /// and fires a [AnalyticsEventType.sessionStarted] event.
  Future<void> startSession() async {
    _currentSessionStart = DateTime.now();
    final now = _currentSessionStart!;

    // Increment total session count
    final currentCount = totalSessions;
    await _prefs.setInt(_totalSessionsKey, currentCount + 1);

    // Set first session date if not already set
    if (firstSessionDate == null) {
      await _prefs.setString(_firstSessionDateKey, now.toIso8601String());
    }

    // Always update last session date
    await _prefs.setString(_lastSessionDateKey, now.toIso8601String());

    // Track unique session dates for retention
    await _addUniqueSessionDate(now);

    // Check retention milestones
    _checkRetentionMilestones(now);

    _analytics.trackEvent(
      AnalyticsEventType.sessionStarted,
      properties: {
        'sessionNumber': currentCount + 1,
        'isFirstSession': currentCount == 0,
      },
    );

    if (kDebugMode) {
      debugPrint('Session started: #${currentCount + 1}');
    }
  }

  /// Ends the current session and records its duration.
  ///
  /// Fires a [AnalyticsEventType.sessionEnded] event with the session
  /// duration in seconds.
  Future<void> endSession() async {
    final duration = currentSessionDuration;
    final now = DateTime.now();

    await _prefs.setString(_lastSessionDateKey, now.toIso8601String());

    _analytics.trackEvent(
      AnalyticsEventType.sessionEnded,
      properties: {
        'durationSeconds': duration.inSeconds,
        'sessionNumber': totalSessions,
      },
    );

    if (kDebugMode) {
      debugPrint('Session ended: ${duration.inSeconds}s');
    }

    _currentSessionStart = null;
  }

  /// Total number of sessions across all time.
  int get totalSessions => _prefs.getInt(_totalSessionsKey) ?? 0;

  /// Date of the first ever session, or null if no sessions recorded.
  DateTime? get firstSessionDate {
    final raw = _prefs.getString(_firstSessionDateKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Date of the most recent session, or null if no sessions recorded.
  DateTime? get lastSessionDate {
    final raw = _prefs.getString(_lastSessionDateKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Duration of the current active session.
  ///
  /// Returns [Duration.zero] if no session is active.
  Duration get currentSessionDuration {
    if (_currentSessionStart == null) return Duration.zero;
    return DateTime.now().difference(_currentSessionStart!);
  }

  /// Whether the user returned at least 1 day after their first session.
  bool isDay1Retained() {
    return _isRetainedAfterDays(1);
  }

  /// Whether the user returned at least 7 days after their first session.
  bool isDay7Retained() {
    return _isRetainedAfterDays(7);
  }

  /// Checks if the user has a session at least [days] after first session.
  bool _isRetainedAfterDays(int days) {
    final first = firstSessionDate;
    if (first == null) return false;

    final uniqueDates = _getUniqueSessionDates();
    final threshold = _dateOnly(first).add(Duration(days: days));

    return uniqueDates.any((date) => !date.isBefore(threshold));
  }

  /// Adds today's date to the set of unique session dates.
  Future<void> _addUniqueSessionDate(DateTime date) async {
    final dates = _getUniqueSessionDates();
    final dateOnly = _dateOnly(date);
    dates.add(dateOnly);

    final dateStrings = dates.map((d) => d.toIso8601String()).toList();
    await _prefs.setStringList(_sessionDatesKey, dateStrings);
  }

  /// Retrieves the set of unique dates on which sessions occurred.
  Set<DateTime> _getUniqueSessionDates() {
    final raw = _prefs.getStringList(_sessionDatesKey);
    if (raw == null) return {};

    return raw.map(DateTime.parse).toSet();
  }

  /// Checks and fires retention milestone events.
  void _checkRetentionMilestones(DateTime now) {
    if (isDay1Retained()) {
      _analytics.trackEvent(
        AnalyticsEventType.dayRetention,
        properties: {'milestone': 'day1'},
      );
    }

    if (isDay7Retained()) {
      _analytics.trackEvent(
        AnalyticsEventType.dayRetention,
        properties: {'milestone': 'day7'},
      );
    }
  }

  /// Strips time components from a DateTime, keeping only the date.
  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
