import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/domain/models/hex_edge.dart';
import 'package:hex_buzz/domain/models/level.dart';

void main() {
  group('DailyChallenge', () {
    late Level testLevel;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 1, 17);

      // Create a simple test level
      final cells = {
        (0, 0): HexCell(q: 0, r: 0, checkpoint: 1),
        (1, 0): HexCell(q: 1, r: 0, checkpoint: 2),
      };
      final walls = <HexEdge>{};

      testLevel = Level(
        id: 'test-level-id',
        size: 2,
        cells: cells,
        walls: walls,
        checkpointCount: 2,
      );
    });

    group('constructor', () {
      test('creates challenge with all required fields', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        expect(challenge.id, equals('2025-01-17'));
        expect(challenge.date, equals(testDate));
        expect(challenge.level, equals(testLevel));
        expect(challenge.completionCount, equals(42));
        expect(challenge.userBestTime, isNull);
        expect(challenge.userStars, isNull);
        expect(challenge.userRank, isNull);
      });

      test('creates challenge with optional user completion data', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );

        expect(challenge.userBestTime, equals(5000));
        expect(challenge.userStars, equals(3));
        expect(challenge.userRank, equals(10));
      });
    });

    group('hasUserCompleted', () {
      test('returns false when no user data present', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        expect(challenge.hasUserCompleted, isFalse);
      });

      test('returns false when only some user data present', () {
        final challenge1 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
        );

        final challenge2 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
        );

        expect(challenge1.hasUserCompleted, isFalse);
        expect(challenge2.hasUserCompleted, isFalse);
      });

      test('returns true when all user data present', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );

        expect(challenge.hasUserCompleted, isTrue);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all non-null fields', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );

        final json = challenge.toJson();

        expect(json['id'], equals('2025-01-17'));
        expect(json['date'], equals(testDate.toIso8601String()));
        expect(json['level'], isNotNull);
        expect(json['level']['id'], equals('test-level-id'));
        expect(json['completionCount'], equals(42));
        expect(json['userBestTime'], equals(5000));
        expect(json['userStars'], equals(3));
        expect(json['userRank'], equals(10));
      });

      test('toJson omits null optional fields', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        final json = challenge.toJson();

        expect(json.containsKey('userBestTime'), isFalse);
        expect(json.containsKey('userStars'), isFalse);
        expect(json.containsKey('userRank'), isFalse);
      });

      test('fromJson creates challenge correctly', () {
        final json = {
          'id': '2025-01-17',
          'date': testDate.toIso8601String(),
          'level': testLevel.toJson(),
          'completionCount': 42,
          'userBestTime': 5000,
          'userStars': 3,
          'userRank': 10,
        };

        final challenge = DailyChallenge.fromJson(json);

        expect(challenge.id, equals('2025-01-17'));
        expect(challenge.date, equals(testDate));
        expect(challenge.level.id, equals(testLevel.id));
        expect(challenge.completionCount, equals(42));
        expect(challenge.userBestTime, equals(5000));
        expect(challenge.userStars, equals(3));
        expect(challenge.userRank, equals(10));
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': '2025-01-17',
          'date': testDate.toIso8601String(),
          'level': testLevel.toJson(),
          'completionCount': 42,
        };

        final challenge = DailyChallenge.fromJson(json);

        expect(challenge.userBestTime, isNull);
        expect(challenge.userStars, isNull);
        expect(challenge.userRank, isNull);
      });

      test('round-trip serialization preserves all data', () {
        final original = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );

        final json = original.toJson();
        final deserialized = DailyChallenge.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.date, equals(original.date));
        expect(deserialized.level.id, equals(original.level.id));
        expect(deserialized.completionCount, equals(original.completionCount));
        expect(deserialized.userBestTime, equals(original.userBestTime));
        expect(deserialized.userStars, equals(original.userStars));
        expect(deserialized.userRank, equals(original.userRank));
      });

      test('nested Level serialization works correctly', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        final json = challenge.toJson();
        final deserialized = DailyChallenge.fromJson(json);

        // Verify the level was properly serialized and deserialized
        expect(deserialized.level.size, equals(testLevel.size));
        expect(
          deserialized.level.checkpointCount,
          equals(testLevel.checkpointCount),
        );
        expect(deserialized.level.cells.length, equals(testLevel.cells.length));
      });
    });

    group('copyWith', () {
      late DailyChallenge challenge;

      setUp(() {
        challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );
      });

      test('copies with updated id', () {
        final copied = challenge.copyWith(id: '2025-01-18');

        expect(copied.id, equals('2025-01-18'));
        expect(copied.date, equals(challenge.date));
      });

      test('copies with updated completionCount', () {
        final copied = challenge.copyWith(completionCount: 100);

        expect(copied.completionCount, equals(100));
        expect(copied.id, equals(challenge.id));
      });

      test('copies with updated user data', () {
        final copied = challenge.copyWith(
          userBestTime: 4000,
          userStars: 2,
          userRank: 5,
        );

        expect(copied.userBestTime, equals(4000));
        expect(copied.userStars, equals(2));
        expect(copied.userRank, equals(5));
      });

      test('clears userBestTime when clearUserBestTime is true', () {
        final copied = challenge.copyWith(clearUserBestTime: true);

        expect(copied.userBestTime, isNull);
        expect(copied.userStars, equals(challenge.userStars));
        expect(copied.userRank, equals(challenge.userRank));
      });

      test('clears userStars when clearUserStars is true', () {
        final copied = challenge.copyWith(clearUserStars: true);

        expect(copied.userStars, isNull);
        expect(copied.userBestTime, equals(challenge.userBestTime));
      });

      test('clears userRank when clearUserRank is true', () {
        final copied = challenge.copyWith(clearUserRank: true);

        expect(copied.userRank, isNull);
        expect(copied.userBestTime, equals(challenge.userBestTime));
      });

      test('copies without changes when no parameters provided', () {
        final copied = challenge.copyWith();

        expect(copied.id, equals(challenge.id));
        expect(copied.date, equals(challenge.date));
        expect(copied.level, equals(challenge.level));
        expect(copied.completionCount, equals(challenge.completionCount));
        expect(copied.userBestTime, equals(challenge.userBestTime));
        expect(copied.userStars, equals(challenge.userStars));
        expect(copied.userRank, equals(challenge.userRank));
      });
    });

    group('equality and hashCode', () {
      test('challenges with same data are equal', () {
        final challenge1 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        final challenge2 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        expect(challenge1, equals(challenge2));
        expect(challenge1.hashCode, equals(challenge2.hashCode));
      });

      test('challenges with different id are not equal', () {
        final challenge1 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        final challenge2 = DailyChallenge(
          id: '2025-01-18',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        expect(challenge1, isNot(equals(challenge2)));
      });

      test('challenges with different completionCount are not equal', () {
        final challenge1 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
        );

        final challenge2 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 100,
        );

        expect(challenge1, isNot(equals(challenge2)));
      });

      test('challenges with different user data are not equal', () {
        final challenge1 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
        );

        final challenge2 = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 6000,
        );

        expect(challenge1, isNot(equals(challenge2)));
      });
    });

    group('toString', () {
      test('includes all field names and values', () {
        final challenge = DailyChallenge(
          id: '2025-01-17',
          date: testDate,
          level: testLevel,
          completionCount: 42,
          userBestTime: 5000,
          userStars: 3,
          userRank: 10,
        );

        final str = challenge.toString();

        expect(str, contains('DailyChallenge'));
        expect(str, contains('id: 2025-01-17'));
        expect(str, contains('completionCount: 42'));
        expect(str, contains('userBestTime: 5000'));
        expect(str, contains('userStars: 3'));
        expect(str, contains('userRank: 10'));
      });
    });
  });
}
