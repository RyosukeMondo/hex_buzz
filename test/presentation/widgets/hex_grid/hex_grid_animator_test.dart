import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/hex_cell.dart';
import 'package:hex_buzz/presentation/widgets/hex_grid/hex_grid_animator.dart';

void main() {
  group('HexGridAnimator', () {
    test('starts with no animated cells', () {
      final animator = HexGridAnimator();
      const cell = HexCell(q: 0, r: 0);

      expect(animator.hasAnimated(cell), isFalse);
    });

    test('marks cell as animated', () {
      final animator = HexGridAnimator();
      const cell = HexCell(q: 0, r: 0);

      animator.markAnimated(cell);

      expect(animator.hasAnimated(cell), isTrue);
    });

    test('tracks multiple cells independently', () {
      final animator = HexGridAnimator();
      const cell1 = HexCell(q: 0, r: 0);
      const cell2 = HexCell(q: 1, r: 0);
      const cell3 = HexCell(q: 0, r: 1);

      animator.markAnimated(cell1);
      animator.markAnimated(cell2);

      expect(animator.hasAnimated(cell1), isTrue);
      expect(animator.hasAnimated(cell2), isTrue);
      expect(animator.hasAnimated(cell3), isFalse);
    });

    test('reset clears all animated cells', () {
      final animator = HexGridAnimator();
      const cell1 = HexCell(q: 0, r: 0);
      const cell2 = HexCell(q: 1, r: 0);

      animator.markAnimated(cell1);
      animator.markAnimated(cell2);
      animator.reset();

      expect(animator.hasAnimated(cell1), isFalse);
      expect(animator.hasAnimated(cell2), isFalse);
    });

    test('distinguishes cells by coordinates', () {
      final animator = HexGridAnimator();
      const cell1 = HexCell(q: 0, r: 0, checkpoint: 1);
      const cell2 = HexCell(q: 0, r: 0, checkpoint: 2);

      animator.markAnimated(cell1);

      // Same coordinates, so should be considered animated
      expect(animator.hasAnimated(cell2), isTrue);
    });

    test('handles cells with different coordinates', () {
      final animator = HexGridAnimator();
      const cell1 = HexCell(q: 0, r: 0);
      const cell2 = HexCell(q: 1, r: 1);

      animator.markAnimated(cell1);

      expect(animator.hasAnimated(cell1), isTrue);
      expect(animator.hasAnimated(cell2), isFalse);
    });

    test('handles negative coordinates', () {
      final animator = HexGridAnimator();
      const cell = HexCell(q: -5, r: -3);

      animator.markAnimated(cell);

      expect(animator.hasAnimated(cell), isTrue);
    });

    test('multiple marks do not change state', () {
      final animator = HexGridAnimator();
      const cell = HexCell(q: 0, r: 0);

      animator.markAnimated(cell);
      animator.markAnimated(cell);
      animator.markAnimated(cell);

      expect(animator.hasAnimated(cell), isTrue);
    });
  });
}
