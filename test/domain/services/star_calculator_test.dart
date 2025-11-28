import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/services/star_calculator.dart';

void main() {
  group('StarCalculator', () {
    group('constants', () {
      test('maxStars is 3', () {
        expect(StarCalculator.maxStars, 3);
      });

      test('threeStarThreshold is 10 seconds', () {
        expect(StarCalculator.threeStarThreshold, const Duration(seconds: 10));
      });

      test('twoStarThreshold is 30 seconds', () {
        expect(StarCalculator.twoStarThreshold, const Duration(seconds: 30));
      });

      test('oneStarThreshold is 60 seconds', () {
        expect(StarCalculator.oneStarThreshold, const Duration(seconds: 60));
      });
    });

    group('calculateStars', () {
      group('3 star threshold (<=10s)', () {
        test('0 seconds returns 3 stars', () {
          expect(StarCalculator.calculateStars(Duration.zero), 3);
        });

        test('1 second returns 3 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 1)), 3);
        });

        test('5 seconds returns 3 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 5)), 3);
        });

        test('9.99 seconds returns 3 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 9, milliseconds: 990),
            ),
            3,
          );
        });

        test('9.999 seconds returns 3 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 9, milliseconds: 999),
            ),
            3,
          );
        });

        test('exactly 10.000 seconds returns 3 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 10)), 3);
        });

        test('10.001 seconds returns 2 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 10, milliseconds: 1),
            ),
            2,
          );
        });
      });

      group('2 star threshold (<=30s)', () {
        test('10.5 seconds returns 2 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 10, milliseconds: 500),
            ),
            2,
          );
        });

        test('15 seconds returns 2 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 15)), 2);
        });

        test('20 seconds returns 2 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 20)), 2);
        });

        test('29.99 seconds returns 2 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 29, milliseconds: 990),
            ),
            2,
          );
        });

        test('29.999 seconds returns 2 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 29, milliseconds: 999),
            ),
            2,
          );
        });

        test('exactly 30.000 seconds returns 2 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 30)), 2);
        });

        test('30.001 seconds returns 1 star', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 30, milliseconds: 1),
            ),
            1,
          );
        });
      });

      group('1 star threshold (<=60s)', () {
        test('30.5 seconds returns 1 star', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 30, milliseconds: 500),
            ),
            1,
          );
        });

        test('45 seconds returns 1 star', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 45)), 1);
        });

        test('59.99 seconds returns 1 star', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 59, milliseconds: 990),
            ),
            1,
          );
        });

        test('59.999 seconds returns 1 star', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 59, milliseconds: 999),
            ),
            1,
          );
        });

        test('exactly 60.000 seconds returns 1 star', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 60)), 1);
        });

        test('60.001 seconds returns 0 stars', () {
          expect(
            StarCalculator.calculateStars(
              const Duration(seconds: 60, milliseconds: 1),
            ),
            0,
          );
        });
      });

      group('0 star threshold (>60s)', () {
        test('61 seconds returns 0 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 61)), 0);
        });

        test('90 seconds returns 0 stars', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 90)), 0);
        });

        test('120 seconds (2 minutes) returns 0 stars', () {
          expect(StarCalculator.calculateStars(const Duration(minutes: 2)), 0);
        });

        test('300 seconds (5 minutes) returns 0 stars', () {
          expect(StarCalculator.calculateStars(const Duration(minutes: 5)), 0);
        });

        test('very long time returns 0 stars', () {
          expect(StarCalculator.calculateStars(const Duration(hours: 1)), 0);
        });
      });

      group('edge cases', () {
        test('negative duration treated as zero (3 stars)', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: -5)), 3);
        });

        test('microsecond precision at 10s boundary', () {
          // 10 seconds exactly
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 10000000),
            ),
            3,
          );
          // 10 seconds + 1 microsecond
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 10000001),
            ),
            2,
          );
        });

        test('microsecond precision at 30s boundary', () {
          // 30 seconds exactly
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 30000000),
            ),
            2,
          );
          // 30 seconds + 1 microsecond
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 30000001),
            ),
            1,
          );
        });

        test('microsecond precision at 60s boundary', () {
          // 60 seconds exactly
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 60000000),
            ),
            1,
          );
          // 60 seconds + 1 microsecond
          expect(
            StarCalculator.calculateStars(
              const Duration(microseconds: 60000001),
            ),
            0,
          );
        });
      });

      group('is pure function', () {
        test('same input always produces same output', () {
          const duration = Duration(seconds: 15);

          final result1 = StarCalculator.calculateStars(duration);
          final result2 = StarCalculator.calculateStars(duration);
          final result3 = StarCalculator.calculateStars(duration);

          expect(result1, result2);
          expect(result2, result3);
          expect(result1, 2);
        });

        test('multiple calls with different durations', () {
          expect(StarCalculator.calculateStars(const Duration(seconds: 5)), 3);
          expect(StarCalculator.calculateStars(const Duration(seconds: 20)), 2);
          expect(StarCalculator.calculateStars(const Duration(seconds: 45)), 1);
          expect(StarCalculator.calculateStars(const Duration(seconds: 90)), 0);
        });
      });
    });
  });
}
