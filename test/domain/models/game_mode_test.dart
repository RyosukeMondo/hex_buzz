import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/game_mode.dart';

void main() {
  group('GameMode', () {
    test('has daily mode', () {
      expect(GameMode.daily, isNotNull);
      expect(GameMode.daily.name, 'daily');
    });

    test('has practice mode', () {
      expect(GameMode.practice, isNotNull);
      expect(GameMode.practice.name, 'practice');
    });

    test('has timed mode', () {
      expect(GameMode.timed, isNotNull);
      expect(GameMode.timed.name, 'timed');
    });

    test('has exactly 3 modes', () {
      expect(GameMode.values.length, 3);
    });

    test('can be parsed from name', () {
      expect(GameMode.values.byName('daily'), GameMode.daily);
      expect(GameMode.values.byName('practice'), GameMode.practice);
      expect(GameMode.values.byName('timed'), GameMode.timed);
    });
  });
}
