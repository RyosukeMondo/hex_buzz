import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/leaderboard_entry_widget.dart';
import '../../theme/honey_theme.dart';

/// Screen displaying global and daily challenge leaderboards.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: HoneyTheme.honeyGold,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: HoneyTheme.textPrimary,
              unselectedLabelColor: HoneyTheme.textSecondary,
              indicatorColor: HoneyTheme.honeyGold,
              tabs: [
                Tab(text: 'Global'),
                Tab(text: "Today's Challenge"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_GlobalLeaderboardTab(), _DailyLeaderboardTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);
    final currentUserId = ref.watch(authProvider).valueOrNull?.id;

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No rankings yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return LeaderboardEntryWidget(
              entry: entry,
              isCurrentUser: entry.userId == currentUserId,
            );
          },
        );
      },
    );
  }
}

class _DailyLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().toUtc();
    final dateId =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final leaderboardAsync = ref.watch(dailyLeaderboardProvider(dateId));
    final currentUserId = ref.watch(authProvider).valueOrNull?.id;

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No completions yet. Be the first!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return LeaderboardEntryWidget(
              entry: entry,
              isCurrentUser: entry.userId == currentUserId,
              showCompletionTime: true,
            );
          },
        );
      },
    );
  }
}
