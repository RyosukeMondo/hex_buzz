import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/platform/windows/window_config.dart';

void main() {
  group('WindowConfig', () {
    test('has correct minimum dimensions', () {
      expect(WindowConfig.minWidth, 720.0);
      expect(WindowConfig.minHeight, 480.0);
    });

    test('has correct default dimensions', () {
      expect(WindowConfig.defaultWidth, 1024.0);
      expect(WindowConfig.defaultHeight, 768.0);
    });

    group('getBreakpoint', () {
      test('returns compact for width < 600', () {
        expect(WindowConfig.getBreakpoint(400), WindowBreakpoint.compact);
        expect(WindowConfig.getBreakpoint(599), WindowBreakpoint.compact);
      });

      test('returns medium for width 600-840', () {
        expect(WindowConfig.getBreakpoint(600), WindowBreakpoint.medium);
        expect(WindowConfig.getBreakpoint(839), WindowBreakpoint.medium);
      });

      test('returns expanded for width 840-1200', () {
        expect(WindowConfig.getBreakpoint(840), WindowBreakpoint.expanded);
        expect(WindowConfig.getBreakpoint(1199), WindowBreakpoint.expanded);
      });

      test('returns large for width >= 1200', () {
        expect(WindowConfig.getBreakpoint(1200), WindowBreakpoint.large);
        expect(WindowConfig.getBreakpoint(1920), WindowBreakpoint.large);
      });
    });
  });
}
