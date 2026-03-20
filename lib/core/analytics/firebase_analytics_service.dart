import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/diagnostic_logger.dart';
import '../logging/logger.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

/// Firebase-backed analytics service using DiagnosticLogger and Performance traces.
///
/// Since firebase_analytics is not in the dependency list, this implementation
/// leverages:
/// - [DiagnosticLogger] for structured event logging to Firestore
/// - [FirebasePerformance] custom traces for key funnel metrics
/// - [SharedPreferences] for local event persistence and session data
///
/// Events are logged immediately via DiagnosticLogger and also stored locally
/// in SharedPreferences for session-level aggregation.
class FirebaseAnalyticsService implements AnalyticsService {
  final SharedPreferences _prefs;
  final FirebasePerformance _performance;

  String? _userId;
  final Map<String, String> _userProperties = {};
  bool _initialized = false;

  static const String _eventBufferKey = 'analytics_event_buffer';
  static const String _userPropertiesKey = 'analytics_user_properties';
  static const int _maxBufferedEvents = 500;

  /// Funnel event types that get Firebase Performance traces.
  static const Set<AnalyticsEventType> _tracedEvents = {
    AnalyticsEventType.appOpened,
    AnalyticsEventType.tutorialCompleted,
    AnalyticsEventType.authCompleted,
    AnalyticsEventType.firstLevelCompleted,
    AnalyticsEventType.levelCompleted,
    AnalyticsEventType.dailyChallengeCompleted,
    AnalyticsEventType.sessionStarted,
    AnalyticsEventType.sessionEnded,
  };

  FirebaseAnalyticsService({
    required SharedPreferences prefs,
    FirebasePerformance? performance,
  })  : _prefs = prefs,
        _performance = performance ?? FirebasePerformance.instance;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _loadUserProperties();
    _initialized = true;

    if (kDebugMode) {
      debugPrint('FirebaseAnalyticsService initialized');
    }
  }

  @override
  void trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic>? properties,
  }) {
    final event = AnalyticsEvent.now(
      type: type,
      properties: {
        if (_userId != null) 'userId': _userId,
        ..._userProperties,
        ...?properties,
      },
    );

    _logToFirestore(event);
    _traceIfApplicable(event);
    _bufferLocally(event);
  }

  @override
  void setUserId(String? userId) {
    _userId = userId;

    DiagnosticLogger.logEvent(
      'analytics_user_id_set',
      data: {'hasUserId': userId != null},
      level: LogLevel.info,
    );
  }

  @override
  void setUserProperty(String name, String value) {
    _userProperties[name] = value;
    _saveUserProperties();

    DiagnosticLogger.logEvent(
      'analytics_user_property_set',
      data: {'name': name, 'value': value},
      level: LogLevel.debug,
    );
  }

  @override
  Future<void> flush() async {
    final buffer = _getBufferedEvents();
    if (buffer.isEmpty) return;

    // Log summary to Firestore for aggregation
    DiagnosticLogger.logEvent(
      'analytics_flush',
      data: {
        'eventCount': buffer.length,
        'userId': _userId,
        'eventTypes': _summarizeEventTypes(buffer),
      },
      level: LogLevel.info,
    );

    // Clear the buffer after flush
    await _prefs.remove(_eventBufferKey);
  }

  /// Logs the event to Firestore via DiagnosticLogger.
  void _logToFirestore(AnalyticsEvent event) {
    DiagnosticLogger.logEvent(
      'analytics_${event.type.name}',
      data: event.properties,
      level: LogLevel.info,
    );
  }

  /// Creates a Firebase Performance trace for key funnel events.
  void _traceIfApplicable(AnalyticsEvent event) {
    if (!_tracedEvents.contains(event.type)) return;

    try {
      final trace = _performance.newTrace('analytics_${event.type.name}');
      trace.start();

      // Add event properties as trace attributes
      for (final entry in event.properties.entries) {
        final value = entry.value?.toString() ?? '';
        if (value.length <= 100) {
          trace.putAttribute(entry.key, value);
        }
      }

      // Traces are point-in-time for analytics, so stop immediately
      trace.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to create performance trace: $e');
      }
    }
  }

  /// Buffers the event locally in SharedPreferences.
  void _bufferLocally(AnalyticsEvent event) {
    try {
      final buffer = _getBufferedEvents();
      buffer.add(event.toJson());

      // Evict oldest events if buffer exceeds max size
      while (buffer.length > _maxBufferedEvents) {
        buffer.removeAt(0);
      }

      _prefs.setString(_eventBufferKey, jsonEncode(buffer));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to buffer analytics event: $e');
      }
    }
  }

  /// Retrieves buffered events from SharedPreferences.
  List<Map<String, dynamic>> _getBufferedEvents() {
    final raw = _prefs.getString(_eventBufferKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to decode buffered events: $e');
      }
      return [];
    }
  }

  /// Loads user properties from SharedPreferences.
  void _loadUserProperties() {
    final raw = _prefs.getString(_userPropertiesKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _userProperties
        ..clear()
        ..addAll(decoded.cast<String, String>());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load user properties: $e');
      }
    }
  }

  /// Saves user properties to SharedPreferences.
  void _saveUserProperties() {
    try {
      _prefs.setString(_userPropertiesKey, jsonEncode(_userProperties));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save user properties: $e');
      }
    }
  }

  /// Summarizes event types from a list of buffered events for flush logging.
  Map<String, int> _summarizeEventTypes(List<Map<String, dynamic>> events) {
    final counts = <String, int>{};
    for (final event in events) {
      final type = event['type'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
