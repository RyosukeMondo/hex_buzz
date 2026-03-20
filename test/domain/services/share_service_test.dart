import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/services/share_service.dart';

void main() {
  group('ShareService', () {
    late ShareService service;

    setUp(() {
      service = const ShareService();
    });

    group('generateShareText', () {
      group('star display', () {
        test('3 stars shows three star emojis', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 8, milliseconds: 500),
            mode: 'Level 5',
          );

          expect(text, contains('\u2b50\u2b50\u2b50'));
          expect(text, isNot(contains('\u2606')));
        });

        test('2 stars shows two star emojis', () {
          final text = service.generateShareText(
            stars: 2,
            time: const Duration(seconds: 15),
            mode: 'Level 3',
          );

          expect(text, contains('\u2b50\u2b50'));
          // Should not contain 3 stars
          expect(text, isNot(contains('\u2b50\u2b50\u2b50')));
        });

        test('1 star shows one star emoji', () {
          final text = service.generateShareText(
            stars: 1,
            time: const Duration(seconds: 45),
            mode: 'Level 10',
          );

          expect(text, contains('\u2b50'));
          expect(text, isNot(contains('\u2b50\u2b50')));
        });

        test('0 stars shows empty star', () {
          final text = service.generateShareText(
            stars: 0,
            time: const Duration(seconds: 90),
            mode: 'Level 1',
          );

          expect(text, contains('\u2606'));
          expect(text, isNot(contains('\u2b50')));
        });
      });

      group('time formatting', () {
        test('short time formats as seconds with decimal', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 8, milliseconds: 500),
            mode: 'Level 5',
          );

          expect(text, contains('8.5s'));
        });

        test('sub-second time formats correctly', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(milliseconds: 750),
            mode: 'Level 1',
          );

          expect(text, contains('0.8s'));
        });

        test('exact seconds formats with .0', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 10),
            mode: 'Level 2',
          );

          expect(text, contains('10.0s'));
        });

        test('time over 60 seconds formats as minutes:seconds', () {
          final text = service.generateShareText(
            stars: 1,
            time: const Duration(minutes: 2, seconds: 5),
            mode: 'Level 20',
          );

          expect(text, contains('2:05'));
        });

        test('time exactly 60 seconds formats as minutes:seconds', () {
          final text = service.generateShareText(
            stars: 1,
            time: const Duration(seconds: 60),
            mode: 'Level 15',
          );

          expect(text, contains('1:00'));
        });
      });

      group('mode display', () {
        test('includes Level mode', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 5),
            mode: 'Level 5',
          );

          expect(text, contains('Level 5'));
        });

        test('includes Daily Challenge mode', () {
          final text = service.generateShareText(
            stars: 2,
            time: const Duration(seconds: 20),
            mode: 'Daily Challenge',
          );

          expect(text, contains('Daily Challenge'));
        });

        test('includes Timed Sprint mode', () {
          final text = service.generateShareText(
            stars: 1,
            time: const Duration(seconds: 30),
            mode: 'Timed Sprint',
          );

          expect(text, contains('Timed Sprint'));
        });
      });

      group('format structure', () {
        test('contains HexBuzz branding and hashtag', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 8, milliseconds: 500),
            mode: 'Level 5',
          );

          expect(text, startsWith('HexBuzz'));
          expect(text, contains('\ud83d\udc1d'));
          expect(text, contains('#HexBuzz'));
        });

        test('full format matches expected output', () {
          final text = service.generateShareText(
            stars: 3,
            time: const Duration(seconds: 8, milliseconds: 500),
            mode: 'Level 5',
          );

          expect(
            text,
            equals('HexBuzz \ud83d\udc1d Level 5 \u2b50\u2b50\u2b50 8.5s #HexBuzz'),
          );
        });

        test('full format with 0 stars', () {
          final text = service.generateShareText(
            stars: 0,
            time: const Duration(minutes: 1, seconds: 30),
            mode: 'Daily Challenge',
          );

          expect(
            text,
            equals('HexBuzz \ud83d\udc1d Daily Challenge \u2606 1:30 #HexBuzz'),
          );
        });
      });
    });
  });
}
