import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/models/social_leaderboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/leaderboard_entry_widget.dart';
import '../../theme/honey_theme.dart';

/// Screen displaying global, friends, and daily challenge leaderboards.
///
/// Uses three tabs: Global (all players), Friends (only friends + current user),
/// and Today's Challenge (daily challenge rankings).
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
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: HoneyTheme.textPrimary,
              unselectedLabelColor: HoneyTheme.textSecondary,
              indicatorColor: HoneyTheme.honeyGold,
              tabs: [
                Tab(text: 'Global'),
                Tab(text: 'Friends'),
                Tab(text: "Today's Challenge"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _GlobalLeaderboardTab(),
                  _FriendsLeaderboardTab(),
                  _DailyLeaderboardTab(),
                ],
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
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
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

class _FriendsLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsLeaderboardAsync = ref.watch(friendsLeaderboardProvider);

    return friendsLeaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyFriendsState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildSocialEntry(entry);
          },
        );
      },
    );
  }

  Widget _buildEmptyFriendsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.textSecondary,
            ),
            SizedBox(height: HoneyTheme.spacingLg),
            Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: HoneyTheme.textPrimary,
              ),
            ),
            SizedBox(height: HoneyTheme.spacingSm),
            Text(
              'Add friends to see how you compare!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HoneyTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialEntry(SocialLeaderboardEntry entry) {
    // Convert to a LeaderboardEntry for the shared widget
    final leaderboardEntry = LeaderboardEntry(
      userId: entry.userId,
      username: entry.username,
      totalStars: entry.stars,
      rank: entry.rank,
      updatedAt: DateTime.now(),
      completionTime: entry.completionTime,
    );

    return LeaderboardEntryWidget(
      entry: leaderboardEntry,
      isCurrentUser: entry.isCurrentUser,
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
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('No completions yet. Be the first!'),
          );
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
