import 'package:hex_buzz/domain/data/test_level.dart';
import 'package:hex_buzz/domain/services/level_validator.dart';

/// Script to verify that the test level is solvable.
void main() {
  print('Verifying test level...\n');

  final level = getTestLevel();
  print('Level: ${level.id}');
  print('Size: ${level.size}x${level.size}');
  print('Cells: ${level.cells.length}');
  print('Walls: ${level.walls.length}');
  print('Checkpoints: ${level.checkpointCount}');
  print('');

  // Show checkpoint positions
  for (var i = 1; i <= level.checkpointCount; i++) {
    final cell = level.cells.values.firstWhere((c) => c.checkpoint == i);
    print('Checkpoint $i: (${cell.q}, ${cell.r})');
  }
  print('');

  // Show walls
  print('Walls:');
  for (final wall in level.walls) {
    print('  $wall');
  }
  print('');

  // Validate level
  const validator = LevelValidator();
  final result = validator.validate(level);

  print('Validation result:');
  print('  Solvable: ${result.isSolvable}');

  if (result.isSolvable && result.solutionPath != null) {
    print('  Solution path (${result.solutionPath!.length} cells):');
    for (var i = 0; i < result.solutionPath!.length; i++) {
      final cell = result.solutionPath![i];
      final cp = cell.checkpoint != null ? ' [CP${cell.checkpoint}]' : '';
      print('    ${i + 1}. (${cell.q}, ${cell.r})$cp');
    }
  } else if (result.error != null) {
    print('  Error: ${result.error}');
  }
}
