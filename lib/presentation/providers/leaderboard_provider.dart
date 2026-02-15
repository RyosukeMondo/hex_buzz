import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../../domain/services/leaderboard_repository.dart';
import 'daily_challenge_provider.dart';

/// Provider for the leaderboard repository (dependency injection point).
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  throw UnimplementedError(
    'leaderboardRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// Provider that fetches the daily challenge leaderboard for a given date string (YYYY-MM-DD).
final dailyLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, dateId) async {
      final repository = ref.watch(dailyChallengeRepositoryProvider);
      final date = DateTime.parse(dateId);
      return repository.getChallengeLeaderboard(date: date, limit: 50);
    });

/// Provider that fetches the global leaderboard.
final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getTopPlayers(limit: 50);
});
