import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> hapticCalls;

  setUp(() {
    hapticCalls = [];
    // Intercept platform channel calls to HapticFeedback and SystemSound.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        hapticCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('HapticService', () {
    group('when disabled', () {
      test('does not fire any haptic feedback', () {
        final service = HapticService(isEnabled: () => false);

        for (final type in HapticType.values) {
          service.trigger(type);
        }

        expect(
          hapticCalls,
          isEmpty,
          reason: 'No haptic calls should be made when disabled',
        );
      });

      test('checks enabled state on each trigger call', () {
        var enabled = true;
        final service = HapticService(isEnabled: () => enabled);

        service.trigger(HapticType.cellTap);
        expect(hapticCalls, isNotEmpty);

        hapticCalls.clear();
        enabled = false;

        service.trigger(HapticType.cellTap);
        expect(
          hapticCalls,
          isEmpty,
          reason: 'Should respect dynamic enabled state changes',
        );
      });
    });

    group('when enabled', () {
      late HapticService service;

      setUp(() {
        service = HapticService(isEnabled: () => true);
      });

      test('cellTap triggers lightImpact', () {
        service.trigger(HapticType.cellTap);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('pathDraw triggers selectionClick', () {
        service.trigger(HapticType.pathDraw);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(
          hapticCalls.first.arguments,
          'HapticFeedbackType.selectionClick',
        );
      });

      test('undo triggers lightImpact', () {
        service.trigger(HapticType.undo);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('checkpoint triggers mediumImpact', () {
        service.trigger(HapticType.checkpoint);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('completion triggers heavyImpact and system click', () {
        service.trigger(HapticType.completion);

        expect(hapticCalls, hasLength(2));
        expect(hapticCalls[0].method, 'HapticFeedback.vibrate');
        expect(hapticCalls[0].arguments, 'HapticFeedbackType.heavyImpact');
        expect(hapticCalls[1].method, 'SystemSound.play');
        expect(hapticCalls[1].arguments, 'SystemSoundType.click');
      });

      test('error triggers vibrate', () {
        service.trigger(HapticType.error);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        // Plain vibrate sends null arguments (no specific type)
        expect(hapticCalls.first.arguments, isNull);
      });

      test('buttonTap triggers selectionClick', () {
        service.trigger(HapticType.buttonTap);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(
          hapticCalls.first.arguments,
          'HapticFeedbackType.selectionClick',
        );
      });

      test('achievement triggers heavyImpact', () {
        service.trigger(HapticType.achievement);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('timerWarning triggers lightImpact', () {
        service.trigger(HapticType.timerWarning);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('timerExpired triggers heavyImpact', () {
        service.trigger(HapticType.timerExpired);

        expect(hapticCalls, hasLength(1));
        expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
        expect(hapticCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });
    });

    group('HapticType mapping uniqueness', () {
      test('different types produce distinct feedback patterns', () {
        final service = HapticService(isEnabled: () => true);

        // Collect the feedback pattern for each type.
        final patterns = <HapticType, List<String>>{};

        for (final type in HapticType.values) {
          hapticCalls.clear();
          service.trigger(type);
          patterns[type] = hapticCalls
              .map((c) => '${c.method}:${c.arguments}')
              .toList();
        }

        // Group types by their pattern to verify intentional groupings.
        // Some types intentionally share patterns (e.g., cellTap and undo
        // both use lightImpact). Verify that we have multiple distinct
        // patterns across all types.
        final uniquePatterns = patterns.values.map((p) => p.join(',')).toSet();

        // We expect at least 5 distinct patterns:
        // lightImpact, selectionClick, mediumImpact, heavyImpact,
        // vibrate, heavyImpact+click
        expect(
          uniquePatterns.length,
          greaterThanOrEqualTo(5),
          reason:
              'Should have at least 5 distinct haptic patterns. '
              'Found: $uniquePatterns',
        );
      });
    });
  });
}
