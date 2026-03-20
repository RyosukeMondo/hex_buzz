import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/core/analytics/analytics_event.dart';

void main() {
  group('AnalyticsEvent', () {
    test('constructs with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final event = AnalyticsEvent(
        type: AnalyticsEventType.levelStarted,
        timestamp: timestamp,
      );

      expect(event.type, AnalyticsEventType.levelStarted);
      expect(event.timestamp, timestamp);
      expect(event.properties, isEmpty);
    });

    test('constructs with properties', () {
      final event = AnalyticsEvent(
        type: AnalyticsEventType.levelCompleted,
        properties: {'levelIndex': 5, 'stars': 3},
        timestamp: DateTime(2024, 1, 15),
      );

      expect(event.properties['levelIndex'], 5);
      expect(event.properties['stars'], 3);
    });

    test('now factory creates event with current time', () {
      final before = DateTime.now();
      final event = AnalyticsEvent.now(
        type: AnalyticsEventType.appOpened,
      );
      final after = DateTime.now();

      expect(event.type, AnalyticsEventType.appOpened);
      expect(event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(event.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('toJson serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final event = AnalyticsEvent(
        type: AnalyticsEventType.sessionStarted,
        properties: {'sessionNumber': 1},
        timestamp: timestamp,
      );

      final json = event.toJson();

      expect(json['type'], 'sessionStarted');
      expect(json['properties'], {'sessionNumber': 1});
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'type': 'levelCompleted',
        'properties': {'stars': 3},
        'timestamp': '2024-01-15T10:30:00.000',
      };

      final event = AnalyticsEvent.fromJson(json);

      expect(event.type, AnalyticsEventType.levelCompleted);
      expect(event.properties['stars'], 3);
      expect(event.timestamp, DateTime(2024, 1, 15, 10, 30));
    });

    test('fromJson handles missing properties', () {
      final json = {
        'type': 'appOpened',
        'timestamp': '2024-01-15T10:30:00.000',
      };

      final event = AnalyticsEvent.fromJson(json);

      expect(event.type, AnalyticsEventType.appOpened);
      expect(event.properties, isEmpty);
    });

    test('roundtrip toJson/fromJson preserves data', () {
      final original = AnalyticsEvent(
        type: AnalyticsEventType.dailyChallengeCompleted,
        properties: {'stars': 2, 'timeMs': 45000},
        timestamp: DateTime(2024, 6, 15, 14, 0),
      );

      final roundtripped = AnalyticsEvent.fromJson(original.toJson());

      expect(roundtripped.type, original.type);
      expect(roundtripped.timestamp, original.timestamp);
      expect(roundtripped.properties['stars'], 2);
      expect(roundtripped.properties['timeMs'], 45000);
    });

    test('copyWith creates modified copy', () {
      final original = AnalyticsEvent(
        type: AnalyticsEventType.levelStarted,
        properties: {'level': 1},
        timestamp: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        type: AnalyticsEventType.levelCompleted,
        properties: {'level': 1, 'stars': 3},
      );

      expect(modified.type, AnalyticsEventType.levelCompleted);
      expect(modified.properties['stars'], 3);
      expect(modified.timestamp, original.timestamp);
    });

    test('copyWith preserves unmodified fields', () {
      final original = AnalyticsEvent(
        type: AnalyticsEventType.hintUsed,
        properties: {'hintType': 'auto'},
        timestamp: DateTime(2024, 3, 1),
      );

      final modified = original.copyWith();

      expect(modified.type, original.type);
      expect(modified.properties, original.properties);
      expect(modified.timestamp, original.timestamp);
    });

    test('equality works for identical events', () {
      final timestamp = DateTime(2024, 1, 15);
      final a = AnalyticsEvent(
        type: AnalyticsEventType.appOpened,
        properties: {'key': 'value'},
        timestamp: timestamp,
      );
      final b = AnalyticsEvent(
        type: AnalyticsEventType.appOpened,
        properties: {'key': 'value'},
        timestamp: timestamp,
      );

      expect(a, equals(b));
    });

    test('equality fails for different types', () {
      final timestamp = DateTime(2024, 1, 15);
      final a = AnalyticsEvent(
        type: AnalyticsEventType.appOpened,
        timestamp: timestamp,
      );
      final b = AnalyticsEvent(
        type: AnalyticsEventType.sessionStarted,
        timestamp: timestamp,
      );

      expect(a, isNot(equals(b)));
    });

    test('toString includes type and timestamp', () {
      final event = AnalyticsEvent(
        type: AnalyticsEventType.levelStarted,
        timestamp: DateTime(2024, 1, 15),
      );

      final str = event.toString();
      expect(str, contains('levelStarted'));
      expect(str, contains('2024'));
    });
  });

  group('AnalyticsEventType', () {
    test('contains all funnel events', () {
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.appOpened));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.tutorialStarted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.tutorialCompleted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.tutorialSkipped));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.authCompleted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.firstLevelStarted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.firstLevelCompleted));
    });

    test('contains all engagement events', () {
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.levelStarted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.levelCompleted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.levelFailed));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.levelUndoUsed));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.hintUsed));
    });

    test('contains all daily challenge events', () {
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.dailyChallengeStarted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.dailyChallengeCompleted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.dailyChallengeShared));
    });

    test('contains all retention events', () {
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.sessionStarted));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.sessionEnded));
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.dayRetention));
    });

    test('contains screenViewed event', () {
      expect(AnalyticsEventType.values, contains(AnalyticsEventType.screenViewed));
    });

    test('byName resolves correctly', () {
      expect(
        AnalyticsEventType.values.byName('levelCompleted'),
        AnalyticsEventType.levelCompleted,
      );
    });
  });
}
