import 'dart:io';

import '../../../data/local/file_progress_repository.dart';
import '../../../domain/models/progress_state.dart';
import '../cli_runner.dart';

/// CLI command for managing player progress.
///
/// Provides subcommands for getting, setting, and resetting progress.
/// All output is JSON formatted for AI agent parsing.
class ProgressCommand extends JsonCommand {
  @override
  final String name = 'progress';

  @override
  final String description = 'Manage player progress';

  ProgressCommand() {
    addSubcommand(_GetProgressCommand());
    addSubcommand(_SetProgressCommand());
    addSubcommand(_ResetProgressCommand());
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    // This is called when no subcommand is provided
    throw ArgumentError('A subcommand is required: get, set, or reset');
  }
}

/// Gets the current progress state.
class _GetProgressCommand extends JsonCommand {
  @override
  final String name = 'get';

  @override
  final String description = 'Get current progress state';

  _GetProgressCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to progress JSON file',
      defaultsTo: _defaultProgressPath(),
    );
    argParser.addOption(
      'level',
      abbr: 'l',
      help: 'Get progress for specific level index',
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final filePath = argResults?['file'] as String;
    final levelArg = argResults?['level'] as String?;

    final repository = FileProgressRepository(filePath);
    final state = await repository.load();

    if (levelArg != null) {
      final levelIndex = int.tryParse(levelArg);
      if (levelIndex == null) {
        throw ArgumentError('Invalid level index: $levelArg');
      }

      final progress = state.getProgress(levelIndex);
      return {
        'levelIndex': levelIndex,
        'progress': _levelProgressToJson(progress),
        'isUnlocked': state.isUnlocked(levelIndex),
      };
    }

    return {
      'totalStars': state.totalStars,
      'completedLevels': state.completedLevels,
      'highestUnlockedLevel': state.highestUnlockedLevel,
      'levels': state.levels.map(
        (key, value) => MapEntry(key.toString(), _levelProgressToJson(value)),
      ),
    };
  }

  Map<String, dynamic> _levelProgressToJson(LevelProgress progress) {
    final result = <String, dynamic>{
      'completed': progress.completed,
      'stars': progress.stars,
    };
    if (progress.bestTime != null) {
      result['bestTimeMs'] = progress.bestTime!.inMilliseconds;
    }
    return result;
  }
}

/// Sets progress for a specific level.
class _SetProgressCommand extends JsonCommand {
  @override
  final String name = 'set';

  @override
  final String description = 'Set progress for a level';

  _SetProgressCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to progress JSON file',
      defaultsTo: _defaultProgressPath(),
    );
    argParser.addOption(
      'level',
      abbr: 'l',
      help: 'Level index to set progress for',
      mandatory: true,
    );
    argParser.addOption(
      'stars',
      abbr: 's',
      help: 'Star rating (0-3)',
      mandatory: true,
    );
    argParser.addOption('time', abbr: 't', help: 'Best time in milliseconds');
    argParser.addFlag(
      'completed',
      defaultsTo: true,
      help: 'Mark level as completed',
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final filePath = argResults?['file'] as String;
    final levelIndex = _parseLevel(argResults?['level'] as String);
    final stars = _parseStars(argResults?['stars'] as String);
    final bestTime = _parseTime(argResults?['time'] as String?);
    final completed = argResults?.flag('completed') ?? true;

    final repository = FileProgressRepository(filePath);
    var state = await repository.load();

    final progress = LevelProgress(
      completed: completed,
      stars: stars,
      bestTime: bestTime,
    );

    state = state.withLevelProgress(levelIndex, progress);
    await repository.save(state);

    return _buildResult(levelIndex, progress, bestTime);
  }

  int _parseLevel(String levelArg) {
    final levelIndex = int.tryParse(levelArg);
    if (levelIndex == null || levelIndex < 0) {
      throw ArgumentError('Invalid level index: $levelArg');
    }
    return levelIndex;
  }

  int _parseStars(String starsArg) {
    final stars = int.tryParse(starsArg);
    if (stars == null || stars < 0 || stars > 3) {
      throw ArgumentError('Invalid stars value: $starsArg (must be 0-3)');
    }
    return stars;
  }

  Duration? _parseTime(String? timeArg) {
    if (timeArg == null) return null;
    final timeMs = int.tryParse(timeArg);
    if (timeMs == null || timeMs < 0) {
      throw ArgumentError('Invalid time value: $timeArg');
    }
    return Duration(milliseconds: timeMs);
  }

  Map<String, dynamic> _buildResult(
    int levelIndex,
    LevelProgress progress,
    Duration? bestTime,
  ) {
    final progressMap = <String, dynamic>{
      'completed': progress.completed,
      'stars': progress.stars,
    };
    if (bestTime != null) {
      progressMap['bestTimeMs'] = bestTime.inMilliseconds;
    }
    return {
      'levelIndex': levelIndex,
      'progress': progressMap,
      'message': 'Progress updated for level $levelIndex',
    };
  }
}

/// Resets all progress.
class _ResetProgressCommand extends JsonCommand {
  @override
  final String name = 'reset';

  @override
  final String description = 'Reset all progress';

  _ResetProgressCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to progress JSON file',
      defaultsTo: _defaultProgressPath(),
    );
    argParser.addFlag(
      'confirm',
      help: 'Confirm reset (required)',
      negatable: false,
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final filePath = argResults?['file'] as String;
    final confirmed = argResults?.flag('confirm') ?? false;

    if (!confirmed) {
      throw ArgumentError('Use --confirm to reset all progress');
    }

    final repository = FileProgressRepository(filePath);
    await repository.reset();

    return {'message': 'All progress has been reset'};
  }
}

/// Returns the default progress file path.
String _defaultProgressPath() {
  // Use a default location in the current directory
  return '${Directory.current.path}/progress.json';
}
