import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 1, 17, 12, 0, 0);
    });

    group('constructor', () {
      test('creates entry with all required fields', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        expect(entry.userId, equals('user123'));
        expect(entry.username, equals('testuser'));
        expect(entry.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(entry.totalStars, equals(100));
        expect(entry.rank, equals(1));
        expect(entry.updatedAt, equals(testDate));
        expect(entry.completionTime, isNull);
        expect(entry.stars, isNull);
      });

      test('creates entry with optional daily challenge fields', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
          stars: 3,
        );

        expect(entry.completionTime, equals(5000));
        expect(entry.stars, equals(3));
      });

      test('creates entry without avatarUrl', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        expect(entry.avatarUrl, isNull);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all non-null fields', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
          stars: 3,
        );

        final json = entry.toJson();

        expect(json['userId'], equals('user123'));
        expect(json['username'], equals('testuser'));
        expect(json['avatarUrl'], equals('https://example.com/avatar.jpg'));
        expect(json['totalStars'], equals(100));
        expect(json['rank'], equals(1));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
        expect(json['completionTime'], equals(5000));
        expect(json['stars'], equals(3));
      });

      test('toJson omits null optional fields', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        final json = entry.toJson();

        expect(json.containsKey('avatarUrl'), isFalse);
        expect(json.containsKey('completionTime'), isFalse);
        expect(json.containsKey('stars'), isFalse);
      });

      test('fromJson creates entry correctly', () {
        final json = {
          'userId': 'user123',
          'username': 'testuser',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'totalStars': 100,
          'rank': 1,
          'updatedAt': testDate.toIso8601String(),
          'completionTime': 5000,
          'stars': 3,
        };

        final entry = LeaderboardEntry.fromJson(json);

        expect(entry.userId, equals('user123'));
        expect(entry.username, equals('testuser'));
        expect(entry.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(entry.totalStars, equals(100));
        expect(entry.rank, equals(1));
        expect(entry.updatedAt, equals(testDate));
        expect(entry.completionTime, equals(5000));
        expect(entry.stars, equals(3));
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'userId': 'user123',
          'username': 'testuser',
          'totalStars': 100,
          'rank': 1,
          'updatedAt': testDate.toIso8601String(),
        };

        final entry = LeaderboardEntry.fromJson(json);

        expect(entry.avatarUrl, isNull);
        expect(entry.completionTime, isNull);
        expect(entry.stars, isNull);
      });

      test('round-trip serialization preserves all data', () {
        final original = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
          stars: 3,
        );

        final json = original.toJson();
        final deserialized = LeaderboardEntry.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      late LeaderboardEntry entry;

      setUp(() {
        entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
          stars: 3,
        );
      });

      test('copies with updated userId', () {
        final copied = entry.copyWith(userId: 'user456');

        expect(copied.userId, equals('user456'));
        expect(copied.username, equals(entry.username));
      });

      test('copies with updated rank', () {
        final copied = entry.copyWith(rank: 2);

        expect(copied.rank, equals(2));
        expect(copied.userId, equals(entry.userId));
      });

      test('copies with updated totalStars', () {
        final copied = entry.copyWith(totalStars: 150);

        expect(copied.totalStars, equals(150));
      });

      test('clears avatarUrl when clearAvatarUrl is true', () {
        final copied = entry.copyWith(clearAvatarUrl: true);

        expect(copied.avatarUrl, isNull);
        expect(copied.userId, equals(entry.userId));
      });

      test('clears completionTime when clearCompletionTime is true', () {
        final copied = entry.copyWith(clearCompletionTime: true);

        expect(copied.completionTime, isNull);
        expect(copied.stars, equals(entry.stars));
      });

      test('clears stars when clearStars is true', () {
        final copied = entry.copyWith(clearStars: true);

        expect(copied.stars, isNull);
        expect(copied.completionTime, equals(entry.completionTime));
      });

      test('copies without changes when no parameters provided', () {
        final copied = entry.copyWith();

        expect(copied, equals(entry));
      });
    });

    group('equality and hashCode', () {
      test('entries with same data are equal', () {
        final entry1 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        final entry2 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('entries with different userId are not equal', () {
        final entry1 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        final entry2 = LeaderboardEntry(
          userId: 'user456',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different rank are not equal', () {
        final entry1 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
        );

        final entry2 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 2,
          updatedAt: testDate,
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different optional fields are not equal', () {
        final entry1 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
        );

        final entry2 = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 6000,
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('toString', () {
      test('includes all field names and values', () {
        final entry = LeaderboardEntry(
          userId: 'user123',
          username: 'testuser',
          avatarUrl: 'https://example.com/avatar.jpg',
          totalStars: 100,
          rank: 1,
          updatedAt: testDate,
          completionTime: 5000,
          stars: 3,
        );

        final str = entry.toString();

        expect(str, contains('LeaderboardEntry'));
        expect(str, contains('userId: user123'));
        expect(str, contains('username: testuser'));
        expect(str, contains('totalStars: 100'));
        expect(str, contains('rank: 1'));
        expect(str, contains('completionTime: 5000'));
        expect(str, contains('stars: 3'));
      });
    });
  });
}
