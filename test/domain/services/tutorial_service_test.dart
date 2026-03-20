import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/tutorial_state.dart';
import 'package:hex_buzz/domain/services/tutorial_service.dart';

void main() {
  late TutorialService service;

  setUp(() {
    service = const TutorialService();
  });

  group('TutorialService', () {
    group('createBasicLevel', () {
      test('creates a level with 3 cells', () {
        final level = service.createBasicLevel();
        expect(level.cells.length, 3);
      });

      test('has checkpoint 1 at start', () {
        final level = service.createBasicLevel();
        final startCell = level.startCell;
        expect(startCell.checkpoint, 1);
        expect(startCell.q, 0);
        expect(startCell.r, 0);
      });

      test('has checkpoint 2 as end', () {
        final level = service.createBasicLevel();
        final endCell = level.endCell;
        expect(endCell.checkpoint, 2);
      });

      test('has 2 checkpoints', () {
        final level = service.createBasicLevel();
        expect(level.checkpointCount, 2);
      });

      test('has no walls', () {
        final level = service.createBasicLevel();
        expect(level.walls, isEmpty);
      });

      test('has deterministic id', () {
        final level = service.createBasicLevel();
        expect(level.id, 'tutorial_basic');
      });
    });

    group('createCheckpointLevel', () {
      test('creates a level with 5 cells', () {
        final level = service.createCheckpointLevel();
        expect(level.cells.length, 5);
      });

      test('has 3 checkpoints', () {
        final level = service.createCheckpointLevel();
        expect(level.checkpointCount, 3);
      });

      test('checkpoint 1 is at (0,0)', () {
        final level = service.createCheckpointLevel();
        final cell = level.getCell(0, 0);
        expect(cell, isNotNull);
        expect(cell!.checkpoint, 1);
      });

      test('checkpoint 2 is at (1,0)', () {
        final level = service.createCheckpointLevel();
        final cell = level.getCell(1, 0);
        expect(cell, isNotNull);
        expect(cell!.checkpoint, 2);
      });

      test('checkpoint 3 is at (0,2)', () {
        final level = service.createCheckpointLevel();
        final cell = level.getCell(0, 2);
        expect(cell, isNotNull);
        expect(cell!.checkpoint, 3);
      });

      test('has no walls', () {
        final level = service.createCheckpointLevel();
        expect(level.walls, isEmpty);
      });

      test('has deterministic id', () {
        final level = service.createCheckpointLevel();
        expect(level.id, 'tutorial_checkpoint');
      });
    });

    group('createWallLevel', () {
      test('creates a level with 4 cells', () {
        final level = service.createWallLevel();
        expect(level.cells.length, 4);
      });

      test('has 2 checkpoints', () {
        final level = service.createWallLevel();
        expect(level.checkpointCount, 2);
      });

      test('has exactly 1 wall', () {
        final level = service.createWallLevel();
        expect(level.walls.length, 1);
      });

      test('wall blocks direct path from (0,0) to (1,0)', () {
        final level = service.createWallLevel();
        expect(level.hasWall(0, 0, 1, 0), isTrue);
      });

      test('has deterministic id', () {
        final level = service.createWallLevel();
        expect(level.id, 'tutorial_walls');
      });

      test('checkpoint 1 is at (0,0)', () {
        final level = service.createWallLevel();
        expect(level.startCell.q, 0);
        expect(level.startCell.r, 0);
      });

      test('checkpoint 2 is at (1,1)', () {
        final level = service.createWallLevel();
        expect(level.endCell.q, 1);
        expect(level.endCell.r, 1);
      });
    });

    group('getInstructionText', () {
      test('returns non-empty text for every step', () {
        for (final step in TutorialStep.values) {
          final text = service.getInstructionText(step);
          expect(text, isNotEmpty, reason: 'Step $step should have text');
        }
      });

      test('welcome text includes HexBuzz', () {
        final text = service.getInstructionText(TutorialStep.welcome);
        expect(text, contains('HexBuzz'));
      });

      test('tapStartCell text mentions cell marked 1', () {
        final text = service.getInstructionText(TutorialStep.tapStartCell);
        expect(text, contains('1'));
      });

      test('walls text mentions walls', () {
        final text = service.getInstructionText(TutorialStep.walls);
        expect(text.toLowerCase(), contains('wall'));
      });

      test('undo text mentions undo concept', () {
        final text = service.getInstructionText(TutorialStep.undo);
        expect(text.toLowerCase(), contains('mistake'));
      });

      test('complete text mentions mastered or basics', () {
        final text = service.getInstructionText(TutorialStep.complete);
        expect(text.toLowerCase(), contains('master'));
      });
    });

    group('getSubtitleText', () {
      test('returns non-empty subtitle for every step', () {
        for (final step in TutorialStep.values) {
          final text = service.getSubtitleText(step);
          expect(text, isNotEmpty, reason: 'Step $step should have subtitle');
        }
      });
    });

    group('nextStep', () {
      test('welcome -> explainGoal', () {
        expect(service.nextStep(TutorialStep.welcome),
            TutorialStep.explainGoal);
      });

      test('explainGoal -> tapStartCell', () {
        expect(service.nextStep(TutorialStep.explainGoal),
            TutorialStep.tapStartCell);
      });

      test('tapStartCell -> drawPath', () {
        expect(service.nextStep(TutorialStep.tapStartCell),
            TutorialStep.drawPath);
      });

      test('drawPath -> checkpoints', () {
        expect(service.nextStep(TutorialStep.drawPath),
            TutorialStep.checkpoints);
      });

      test('checkpoints -> walls', () {
        expect(service.nextStep(TutorialStep.checkpoints),
            TutorialStep.walls);
      });

      test('walls -> undo', () {
        expect(service.nextStep(TutorialStep.walls), TutorialStep.undo);
      });

      test('undo -> complete', () {
        expect(service.nextStep(TutorialStep.undo), TutorialStep.complete);
      });

      test('complete -> null (no next step)', () {
        expect(service.nextStep(TutorialStep.complete), isNull);
      });

      test('full progression covers all steps', () {
        TutorialStep? current = TutorialStep.welcome;
        final visited = <TutorialStep>[current];

        while (true) {
          current = service.nextStep(current!);
          if (current == null) break;
          visited.add(current);
        }

        expect(visited, TutorialStep.values);
      });
    });

    group('getLevelForStep', () {
      test('returns null for welcome', () {
        expect(service.getLevelForStep(TutorialStep.welcome), isNull);
      });

      test('returns null for explainGoal', () {
        expect(service.getLevelForStep(TutorialStep.explainGoal), isNull);
      });

      test('returns basic level for tapStartCell', () {
        final level = service.getLevelForStep(TutorialStep.tapStartCell);
        expect(level, isNotNull);
        expect(level!.id, 'tutorial_basic');
      });

      test('returns basic level for drawPath', () {
        final level = service.getLevelForStep(TutorialStep.drawPath);
        expect(level, isNotNull);
        expect(level!.id, 'tutorial_basic');
      });

      test('returns checkpoint level for checkpoints', () {
        final level = service.getLevelForStep(TutorialStep.checkpoints);
        expect(level, isNotNull);
        expect(level!.id, 'tutorial_checkpoint');
      });

      test('returns wall level for walls', () {
        final level = service.getLevelForStep(TutorialStep.walls);
        expect(level, isNotNull);
        expect(level!.id, 'tutorial_walls');
      });

      test('returns basic level for undo', () {
        final level = service.getLevelForStep(TutorialStep.undo);
        expect(level, isNotNull);
        expect(level!.id, 'tutorial_basic');
      });

      test('returns null for complete', () {
        expect(service.getLevelForStep(TutorialStep.complete), isNull);
      });
    });

    group('requiresInteraction', () {
      test('welcome does not require interaction', () {
        expect(service.requiresInteraction(TutorialStep.welcome), isFalse);
      });

      test('explainGoal does not require interaction', () {
        expect(
          service.requiresInteraction(TutorialStep.explainGoal),
          isFalse,
        );
      });

      test('tapStartCell requires interaction', () {
        expect(
          service.requiresInteraction(TutorialStep.tapStartCell),
          isTrue,
        );
      });

      test('drawPath requires interaction', () {
        expect(service.requiresInteraction(TutorialStep.drawPath), isTrue);
      });

      test('checkpoints requires interaction', () {
        expect(
          service.requiresInteraction(TutorialStep.checkpoints),
          isTrue,
        );
      });

      test('walls requires interaction', () {
        expect(service.requiresInteraction(TutorialStep.walls), isTrue);
      });

      test('undo requires interaction', () {
        expect(service.requiresInteraction(TutorialStep.undo), isTrue);
      });

      test('complete does not require interaction', () {
        expect(
          service.requiresInteraction(TutorialStep.complete),
          isFalse,
        );
      });
    });
  });
}
