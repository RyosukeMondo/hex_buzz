import '../../../domain/services/leaderboard_repository.dart';
import '../cli_runner.dart';

/// CLI command for leaderboard operations.
///
/// Provides subcommands for getting leaderboard and submitting scores.
/// All output is JSON formatted for AI agent parsing.
class LeaderboardCommand extends JsonCommand {
  final LeaderboardRepository leaderboardRepository;

  @override
  final String name = 'leaderboard';

  @override
  final String description = 'Manage leaderboard';

  LeaderboardCommand(this.leaderboardRepository) {
    addSubcommand(_GetLeaderboardCommand(leaderboardRepository));
    addSubcommand(_SubmitScoreCommand(leaderboardRepository));
    addSubcommand(_GetRankCommand(leaderboardRepository));
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    // This is called when no subcommand is provided
    throw ArgumentError('A subcommand is required: get, submit, or rank');
  }
}

/// Gets the top players from the leaderboard.
class _GetLeaderboardCommand extends JsonCommand {
  final LeaderboardRepository leaderboardRepository;

  @override
  final String name = 'get';

  @override
  final String description = 'Get top players from leaderboard';

  _GetLeaderboardCommand(this.leaderboardRepository) {
    argParser.addOption(
      'top',
      abbr: 't',
      help: 'Number of top players to retrieve',
      defaultsTo: '10',
    );
    argParser.addFlag(
      'daily',
      abbr: 'd',
      help: 'Get daily challenge leaderboard instead',
      negatable: false,
    );
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final topCount = int.parse(argResults!['top'] as String);
    final daily = argResults!['daily'] as bool;

    try {
      final entries = daily
          ? await leaderboardRepository.getDailyChallengeLeaderboard(
              date: DateTime.now(),
              limit: topCount,
            )
          : await leaderboardRepository.getTopPlayers(limit: topCount);

      return {
        'success': true,
        'type': daily ? 'daily_challenge' : 'global',
        'count': entries.length,
        'entries': entries.map((entry) {
          return {
            'rank': entry.rank,
            'userId': entry.userId,
            'username': entry.username,
            'avatarUrl': entry.avatarUrl,
            'totalStars': entry.totalStars,
            'updatedAt': entry.updatedAt.toIso8601String(),
            if (entry.completionTime != null)
              'completionTime': entry.completionTime,
            if (entry.stars != null) 'stars': entry.stars,
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to get leaderboard',
      };
    }
  }
}

/// Submits a score to the leaderboard.
class _SubmitScoreCommand extends JsonCommand {
  final LeaderboardRepository leaderboardRepository;

  @override
  final String name = 'submit';

  @override
  final String description = 'Submit a score to the leaderboard';

  _SubmitScoreCommand(this.leaderboardRepository) {
    argParser.addOption('user-id', abbr: 'u', help: 'User ID', mandatory: true);
    argParser.addOption(
      'stars',
      abbr: 's',
      help: 'Number of stars earned',
      mandatory: true,
    );
    argParser.addOption('level', abbr: 'l', help: 'Level ID');
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final userId = argResults!['user-id'] as String;
    final stars = int.parse(argResults!['stars'] as String);
    final levelId = argResults!['level'] as String?;

    try {
      final success = await leaderboardRepository.submitScore(
        userId: userId,
        stars: stars,
        levelId: levelId,
      );

      if (!success) {
        return {'success': false, 'message': 'Score submission failed'};
      }

      return {
        'success': true,
        'message': 'Score submitted successfully',
        'submission': {
          'userId': userId,
          'stars': stars,
          if (levelId != null) 'levelId': levelId,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to submit score',
      };
    }
  }
}

/// Gets the current user's rank.
class _GetRankCommand extends JsonCommand {
  final LeaderboardRepository leaderboardRepository;

  @override
  final String name = 'rank';

  @override
  final String description = 'Get current user rank';

  _GetRankCommand(this.leaderboardRepository) {
    argParser.addOption('user-id', abbr: 'u', help: 'User ID', mandatory: true);
  }

  @override
  Future<Map<String, dynamic>> execute() async {
    final userId = argResults!['user-id'] as String;

    try {
      final entry = await leaderboardRepository.getUserRank(userId);

      if (entry == null) {
        return {
          'success': true,
          'hasRank': false,
          'message': 'User has no rank yet (no scores submitted)',
        };
      }

      return {
        'success': true,
        'hasRank': true,
        'rank': entry.rank,
        'totalStars': entry.totalStars,
        'username': entry.username,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to get user rank',
      };
    }
  }
}
