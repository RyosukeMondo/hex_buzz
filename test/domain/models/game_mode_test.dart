import 'package:flutter_test/flutter_test.dart';
import 'package:honeycomb_one_pass/domain/models/game_mode.dart';

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

    test('has exactly 2 modes', () {
      expect(GameMode.values.length, 2);
    });

    test('can be parsed from name', () {
      expect(GameMode.values.byName('daily'), GameMode.daily);
      expect(GameMode.values.byName('practice'), GameMode.practice);
    });
  });
}
