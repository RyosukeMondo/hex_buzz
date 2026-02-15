import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/leaderboard_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import 'leaderboard_entry_widget.dart';

/// Widget displaying the daily leaderboard for a specific challenge.
///
/// Fetches leaderboard data via [dailyLeaderboardProvider] (which uses
/// [DailyChallengeRepository.getChallengeLeaderboard]) and renders entries
/// using [LeaderboardEntryWidget]. Highlights the current user's position.
class DailyLeaderboard extends ConsumerWidget {
  final String dateId;

  const DailyLeaderboard({super.key, required this.dateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final currentUserId = authAsync.valueOrNull?.id;
    final leaderboardAsync = ref.watch(dailyLeaderboardProvider(dateId));

    return leaderboardAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading leaderboard: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) => _buildLeaderboard(entries, currentUserId),
    );
  }

  Widget _buildLeaderboard(
    List<LeaderboardEntry> entries,
    String? currentUserId,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No completions yet. Be the first!',
            style: TextStyle(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Daily Leaderboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return LeaderboardEntryWidget(
                entry: entry,
                isCurrentUser: entry.userId == currentUserId,
                showCompletionTime: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
