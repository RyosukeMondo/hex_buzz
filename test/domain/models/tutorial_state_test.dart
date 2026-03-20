import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/tutorial_state.dart';

void main() {
  group('TutorialState', () {
    group('constructors', () {
      test('default constructor has expected defaults', () {
        const state = TutorialState();
        expect(state.currentStep, TutorialStep.welcome);
        expect(state.isActive, isFalse);
        expect(state.hasCompletedTutorial, isFalse);
      });

      test('initial() starts at welcome, not active, not completed', () {
        const state = TutorialState.initial();
        expect(state.currentStep, TutorialStep.welcome);
        expect(state.isActive, isFalse);
        expect(state.hasCompletedTutorial, isFalse);
      });

      test('completed() is at complete step, not active, completed', () {
        const state = TutorialState.completed();
        expect(state.currentStep, TutorialStep.complete);
        expect(state.isActive, isFalse);
        expect(state.hasCompletedTutorial, isTrue);
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equivalent state', () {
        const state = TutorialState(
          currentStep: TutorialStep.drawPath,
          isActive: true,
          hasCompletedTutorial: false,
        );
        final copy = state.copyWith();
        expect(copy, state);
      });

      test('copies with changed step', () {
        const state = TutorialState.initial();
        final copy = state.copyWith(currentStep: TutorialStep.walls);
        expect(copy.currentStep, TutorialStep.walls);
        expect(copy.isActive, state.isActive);
        expect(copy.hasCompletedTutorial, state.hasCompletedTutorial);
      });

      test('copies with changed isActive', () {
        const state = TutorialState.initial();
        final copy = state.copyWith(isActive: true);
        expect(copy.isActive, isTrue);
        expect(copy.currentStep, state.currentStep);
      });

      test('copies with changed hasCompletedTutorial', () {
        const state = TutorialState.initial();
        final copy = state.copyWith(hasCompletedTutorial: true);
        expect(copy.hasCompletedTutorial, isTrue);
      });
    });

    group('serialization', () {
      test('toJson produces expected map', () {
        const state = TutorialState(
          currentStep: TutorialStep.checkpoints,
          isActive: true,
          hasCompletedTutorial: false,
        );
        final json = state.toJson();
        expect(json['currentStep'], 'checkpoints');
        expect(json['isActive'], true);
        expect(json['hasCompletedTutorial'], false);
      });

      test('fromJson restores state', () {
        final json = {
          'currentStep': 'walls',
          'isActive': false,
          'hasCompletedTutorial': true,
        };
        final state = TutorialState.fromJson(json);
        expect(state.currentStep, TutorialStep.walls);
        expect(state.isActive, isFalse);
        expect(state.hasCompletedTutorial, isTrue);
      });

      test('fromJson handles missing fields with defaults', () {
        final state = TutorialState.fromJson({});
        expect(state.currentStep, TutorialStep.welcome);
        expect(state.isActive, isFalse);
        expect(state.hasCompletedTutorial, isFalse);
      });

      test('roundtrip toJson -> fromJson preserves state', () {
        const original = TutorialState(
          currentStep: TutorialStep.undo,
          isActive: true,
          hasCompletedTutorial: false,
        );
        final restored = TutorialState.fromJson(original.toJson());
        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const a = TutorialState(
          currentStep: TutorialStep.drawPath,
          isActive: true,
          hasCompletedTutorial: false,
        );
        const b = TutorialState(
          currentStep: TutorialStep.drawPath,
          isActive: true,
          hasCompletedTutorial: false,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different steps are not equal', () {
        const a = TutorialState(currentStep: TutorialStep.welcome);
        const b = TutorialState(currentStep: TutorialStep.complete);
        expect(a, isNot(b));
      });

      test('different isActive are not equal', () {
        const a = TutorialState(isActive: true);
        const b = TutorialState(isActive: false);
        expect(a, isNot(b));
      });

      test('different hasCompletedTutorial are not equal', () {
        const a = TutorialState(hasCompletedTutorial: true);
        const b = TutorialState(hasCompletedTutorial: false);
        expect(a, isNot(b));
      });
    });

    group('toString', () {
      test('includes step name', () {
        const state = TutorialState(currentStep: TutorialStep.walls);
        expect(state.toString(), contains('walls'));
      });

      test('includes active status', () {
        const state = TutorialState(isActive: true);
        expect(state.toString(), contains('true'));
      });
    });
  });

  group('TutorialStep', () {
    test('has 8 values', () {
      expect(TutorialStep.values.length, 8);
    });

    test('values are in correct order', () {
      expect(TutorialStep.values, [
        TutorialStep.welcome,
        TutorialStep.explainGoal,
        TutorialStep.tapStartCell,
        TutorialStep.drawPath,
        TutorialStep.checkpoints,
        TutorialStep.walls,
        TutorialStep.undo,
        TutorialStep.complete,
      ]);
    });
  });
}
