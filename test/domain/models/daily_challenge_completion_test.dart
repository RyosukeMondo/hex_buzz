import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/daily_challenge_completion.dart';

void main() {
  group('DailyChallengeCompletion.fromJson', () {
    test('parses completionTimeMs field', () {
      final json = {
        'userId': 'user1',
        'dateId': '2026-02-14',
        'stars': 3,
        'completionTimeMs': 45000,
        'completedAt': '2026-02-14T12:00:00Z',
      };

      final completion = DailyChallengeCompletion.fromJson(json);

      expect(completion.userId, 'user1');
      expect(completion.completionTimeMs, 45000);
      expect(completion.stars, 3);
    });

    test('parses completionTime field (Firestore format)', () {
      final json = {
        'userId': 'user2',
        'dateId': '2026-02-14',
        'stars': 2,
        'completionTime': 30000,
        'completedAt': '2026-02-14T12:00:00Z',
      };

      final completion = DailyChallengeCompletion.fromJson(json);

      expect(completion.userId, 'user2');
      expect(completion.completionTimeMs, 30000);
      expect(completion.stars, 2);
    });

    test('prefers completionTimeMs over completionTime when both present', () {
      final json = {
        'userId': 'user3',
        'dateId': '2026-02-14',
        'stars': 1,
        'completionTimeMs': 20000,
        'completionTime': 99999,
        'completedAt': '2026-02-14T12:00:00Z',
      };

      final completion = DailyChallengeCompletion.fromJson(json);

      expect(completion.completionTimeMs, 20000);
    });

    test('parses DateTime completedAt field', () {
      final dateTime = DateTime(2026, 2, 14, 12, 0, 0);
      final json = {
        'userId': 'user1',
        'dateId': '2026-02-14',
        'stars': 3,
        'completionTimeMs': 45000,
        'completedAt': dateTime,
      };

      final completion = DailyChallengeCompletion.fromJson(json);

      expect(completion.completedAt, dateTime);
    });

    test('parses optional rank field', () {
      final json = {
        'userId': 'user1',
        'dateId': '2026-02-14',
        'stars': 3,
        'completionTimeMs': 45000,
        'completedAt': '2026-02-14T12:00:00Z',
        'rank': 5,
      };

      final completion = DailyChallengeCompletion.fromJson(json);

      expect(completion.rank, 5);
    });
  });
}
