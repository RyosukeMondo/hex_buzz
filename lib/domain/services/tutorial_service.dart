import '../models/hex_cell.dart';
import '../models/hex_edge.dart';
import '../models/level.dart';
import '../models/tutorial_state.dart';

/// Service that creates tutorial levels and provides step metadata.
///
/// Each tutorial step can have an associated small level designed to teach
/// a specific game concept. Levels are intentionally tiny (2-7 cells) to
/// keep them simple and non-intimidating for new players.
class TutorialService {
  const TutorialService();

  /// Creates a tiny 3-cell level for the basic movement tutorial.
  ///
  /// Layout (flat-top hexagons):
  ///   (0,0)[1] - (1,0)
  ///      \
  ///     (0,1)[2]
  ///
  /// Simple linear path: (0,0) -> (1,0) -> (0,1)  or  (0,0) -> (0,1) -> ...
  Level createBasicLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1, checkpoint: 2),
    };
    return Level(
      id: 'tutorial_basic',
      size: 2,
      cells: cells,
      walls: {},
      checkpointCount: 2,
    );
  }

  /// Creates a 5-cell level with checkpoints for the checkpoint tutorial.
  ///
  /// Layout:
  ///   (0,0)[1] - (1,0)[2]
  ///      \    /  \
  ///     (0,1) - (1,1)
  ///        \
  ///       (0,2)[3]
  ///
  /// Player must visit checkpoints 1, 2, 3 in order while covering all cells.
  Level createCheckpointLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0, checkpoint: 2),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1),
      (0, 2): const HexCell(q: 0, r: 2, checkpoint: 3),
    };
    return Level(
      id: 'tutorial_checkpoint',
      size: 2,
      cells: cells,
      walls: {},
      checkpointCount: 3,
    );
  }

  /// Creates a 4-cell level with a wall for the wall tutorial.
  ///
  /// Layout:
  ///   (0,0)[1] - (1,0)
  ///      |    /  \
  ///     (0,1) - (1,1)[2]
  ///
  /// Wall between (0,0) and (1,0) forces the player to go around.
  /// Path: (0,0) -> (0,1) -> (1,0) -> (1,1)
  Level createWallLevel() {
    final cells = <(int, int), HexCell>{
      (0, 0): const HexCell(q: 0, r: 0, checkpoint: 1),
      (1, 0): const HexCell(q: 1, r: 0),
      (0, 1): const HexCell(q: 0, r: 1),
      (1, 1): const HexCell(q: 1, r: 1, checkpoint: 2),
    };
    final walls = <HexEdge>{
      HexEdge(cellQ1: 0, cellR1: 0, cellQ2: 1, cellR2: 0),
    };
    return Level(
      id: 'tutorial_walls',
      size: 2,
      cells: cells,
      walls: walls,
      checkpointCount: 2,
    );
  }

  /// Returns the instruction text for a given tutorial step.
  String getInstructionText(TutorialStep step) {
    return switch (step) {
      TutorialStep.welcome =>
        'Welcome to HexBuzz! Let\'s learn how to play.',
      TutorialStep.explainGoal =>
        'Your goal: draw a single path through every cell on the board.',
      TutorialStep.tapStartCell =>
        'Tap the cell marked "1" to begin your path.',
      TutorialStep.drawPath =>
        'Slide to adjacent cells to extend your path. '
            'Visit every cell exactly once!',
      TutorialStep.checkpoints =>
        'Numbered checkpoints must be visited in order. '
            'Reach each number before moving on.',
      TutorialStep.walls =>
        'Walls block your path between cells. '
            'Find another way around!',
      TutorialStep.undo =>
        'Made a mistake? Slide back to the previous cell to undo.',
      TutorialStep.complete =>
        'You\'ve mastered the basics! Time to play for real.',
    };
  }

  /// Returns the subtitle text shown below the instruction.
  String getSubtitleText(TutorialStep step) {
    return switch (step) {
      TutorialStep.welcome => 'A hexagonal path puzzle',
      TutorialStep.explainGoal => 'Cover every hexagon exactly once',
      TutorialStep.tapStartCell => 'The path always starts at checkpoint 1',
      TutorialStep.drawPath => 'Try it on the grid below',
      TutorialStep.checkpoints => 'This puzzle has 3 checkpoints',
      TutorialStep.walls => 'The thick line between cells is a wall',
      TutorialStep.undo => 'You can always backtrack',
      TutorialStep.complete => 'Great job!',
    };
  }

  /// Returns the next step after the current one, or null if complete.
  TutorialStep? nextStep(TutorialStep current) {
    final values = TutorialStep.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex < 0 || currentIndex >= values.length - 1) {
      return null;
    }
    return values[currentIndex + 1];
  }

  /// Returns the level to display for a given tutorial step, or null
  /// if the step does not require a playable grid.
  Level? getLevelForStep(TutorialStep step) {
    return switch (step) {
      TutorialStep.tapStartCell => createBasicLevel(),
      TutorialStep.drawPath => createBasicLevel(),
      TutorialStep.checkpoints => createCheckpointLevel(),
      TutorialStep.walls => createWallLevel(),
      TutorialStep.undo => createBasicLevel(),
      _ => null,
    };
  }

  /// Whether the step requires user interaction on the grid before advancing.
  bool requiresInteraction(TutorialStep step) {
    return switch (step) {
      TutorialStep.tapStartCell => true,
      TutorialStep.drawPath => true,
      TutorialStep.checkpoints => true,
      TutorialStep.walls => true,
      TutorialStep.undo => true,
      _ => false,
    };
  }
}
