import '../../../domain/services/daily_challenge_repository.dart';
import '../cli_runner.dart';

/// CLI command for daily challenge operations.
///
/// Provides subcommands for getting today's challenge, completing challenges,
/// and generating new challenges (admin).
/// All output is JSON formatted for AI agent parsing.
class DailyChallengeCommand extends JsonCommand {
  final DailyChallengeRepository dailyChallengeRepository;

  @override
  final String name = 'daily-challenge';

  @override
  final String description = 'Manage daily challenges';

  DailyChallengeCommand(this.dailyChallengeRepository) {
    addSubcommand(_GetTodayCommand(dailyChallengeRepository));
    addSubcommand(_CompleteCommand(dailyChallengeRepository));
    addSubcommand(_CheckCompletedCommand(dailyChallengeRepository));
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    // This is called when no subcommand is provided
    throw ArgumentError(
      'A subcommand is required: get-today, complete, or check-completed',
    );
  }
}

/// Gets today's daily challenge.
class _GetTodayCommand extends JsonCommand {
  final DailyChallengeRepository dailyChallengeRepository;

  @override
  final String name = 'get-today';

  @override
  final String description = "Get today's daily challenge";

  _GetTodayCommand(this.dailyChallengeRepository);

  @override
  Future<Map<String, dynamic>> execute() async {
    try {
      final challenge = await dailyChallengeRepository.getTodaysChallenge();

      if (challenge == null) {
        return {
          'success': true,
          'hasChallenge': false,
          'message': 'No daily challenge available for today',
        };
      }

      return {
        'success': true,
        'hasChallenge': true,
        'challenge': {
          'id': challenge.id,
          'date': challenge.date.toIso8601String(),
          'levelId': challenge.level.id,
          'completionCount': challenge.completionCount,
          'userCompleted': challenge.userBestTime != null,
          if (challenge.userBestTime != null) ...{
            'userBestTime': challenge.userBestTime,
            'userStars': challenge.userStars,
            'userRank': challenge.userRank,
          },
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': "Failed to get today's challenge",
      };
    }
  }
}

/// Submits a daily challenge completion.
class _CompleteCommand extends JsonCommand {
  final DailyChallengeRepository dailyChallengeRepository;

  @override
  final String name = 'complete';

  @override
  final String description = 'Submit daily challenge completion';

  _CompleteCommand(this.dailyChallengeRepository) {
    argParser.addOption('user-id', abbr: 'u', help: 'User ID', mandatory: true);
    argParser.addOption(
      'stars',
      abbr: 's',
      help: 'Number of stars earned',
      mandatory: true,
    );
    argParser.addOption(
      'time',
      abbr: 't',
      help: 'Completion time in milliseconds',
      mandatory: true,
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final userId = argResults!['user-id'] as String;
    final stars = int.parse(argResults!['stars'] as String);
    final time = int.parse(argResults!['time'] as String);

    try {
      final success = await dailyChallengeRepository.submitChallengeCompletion(
        userId: userId,
        stars: stars,
        completionTimeMs: time,
      );

      if (!success) {
        return {
          'success': false,
          'message': 'Daily challenge completion submission failed',
        };
      }

      return {
        'success': true,
        'message': 'Daily challenge completion submitted',
        'submission': {'userId': userId, 'stars': stars, 'time': time},
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to submit challenge completion',
      };
    }
  }
}

/// Checks if user has completed today's challenge.
class _CheckCompletedCommand extends JsonCommand {
  final DailyChallengeRepository dailyChallengeRepository;

  @override
  final String name = 'check-completed';

  @override
  final String description = "Check if user completed today's challenge";

  _CheckCompletedCommand(this.dailyChallengeRepository) {
    argParser.addOption('user-id', abbr: 'u', help: 'User ID', mandatory: true);
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final userId = argResults!['user-id'] as String;

    try {
      final completed = await dailyChallengeRepository.hasCompletedToday(
        userId,
      );

      return {
        'success': true,
        'completed': completed,
        'message': completed
            ? 'User has completed today\'s challenge'
            : 'User has not completed today\'s challenge',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to check completion status',
      };
    }
  }
}
