import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/leaderboard_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/honey_theme.dart';

/// Leaderboard screen displaying global rankings and daily challenges.
///
/// Shows top players sorted by total stars with pagination support.
/// Displays user's current rank and provides tab navigation between
/// global leaderboard and daily challenge leaderboard.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(leaderboardProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: HoneyTheme.textPrimary,
          unselectedLabelColor: HoneyTheme.textSecondary,
          indicatorColor: HoneyTheme.deepHoney,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Daily Challenge'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalLeaderboard(),
          _buildDailyChallengeLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull;

    return leaderboardAsync.when(
      data: (state) => _buildGlobalLeaderboardData(state, user),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(error.toString(), () {
        ref.invalidate(leaderboardProvider);
      }),
    );
  }

  Widget _buildGlobalLeaderboardData(LeaderboardState state, user) {
    if (state.error != null) {
      return _buildError(state.error!, () {
        ref.read(leaderboardProvider.notifier).refresh();
      });
    }

    if (state.entries.isEmpty) {
      return _buildEmpty('No rankings yet. Be the first to play!');
    }

    return RefreshIndicator(
      onRefresh: () => _refreshGlobalLeaderboard(user),
      child: Column(
        children: [
          if (state.userEntry != null) _buildUserRankCard(state.userEntry!),
          Expanded(
            child: _buildLeaderboardList(state.entries, state.isLoading, user),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshGlobalLeaderboard(user) async {
    await ref.read(leaderboardProvider.notifier).refresh();
    if (user != null) {
      await ref.read(leaderboardProvider.notifier).fetchUserRank(user.id);
    }
  }

  Widget _buildLeaderboardList(
    List<LeaderboardEntry> entries,
    bool isLoading,
    user,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(HoneyTheme.spacingMd),
      itemCount: entries.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(HoneyTheme.spacingLg),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final entry = entries[index];
        final isCurrentUser = user?.id == entry.userId;
        return _buildLeaderboardCard(entry, isCurrentUser);
      },
    );
  }

  Widget _buildDailyChallengeLeaderboard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dailyLeaderboardAsync = ref.watch(
      dailyChallengeLeaderboardProvider(today),
    );
    final authAsync = ref.watch(authProvider);
    final user = authAsync.valueOrNull;

    return dailyLeaderboardAsync.when(
      data: (state) {
        if (state.error != null) {
          return _buildError(state.error!, () {
            ref
                .read(dailyChallengeLeaderboardProvider(today).notifier)
                .refresh();
          });
        }

        if (state.entries.isEmpty) {
          return _buildEmpty('No one has completed today\'s challenge yet!');
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(dailyChallengeLeaderboardProvider(today).notifier)
                .refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(HoneyTheme.spacingMd),
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              final isCurrentUser = user?.id == entry.userId;
              return _buildDailyChallengeCard(entry, isCurrentUser);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(error.toString(), () {
        ref.invalidate(dailyChallengeLeaderboardProvider(today));
      }),
    );
  }

  Widget _buildUserRankCard(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.all(HoneyTheme.spacingMd),
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _userRankCardDecoration(),
      child: Row(
        children: [
          _buildRankBadge(entry.rank, isHighlight: true),
          const SizedBox(width: HoneyTheme.spacingMd),
          Expanded(child: _buildUserRankInfo(entry.username)),
          _buildStarBadge(entry.totalStars),
        ],
      ),
    );
  }

  BoxDecoration _userRankCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          HoneyTheme.honeyGold,
          HoneyTheme.honeyGoldLight.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildUserRankInfo(String username) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Rank',
          style: TextStyle(
            fontSize: 14,
            color: HoneyTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          username,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingMd),
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _leaderboardCardDecoration(isCurrentUser),
      child: Row(
        children: [
          _buildRankBadge(entry.rank),
          const SizedBox(width: HoneyTheme.spacingMd),
          _buildAvatar(entry.avatarUrl, entry.username),
          const SizedBox(width: HoneyTheme.spacingMd),
          Expanded(
            child: Text(
              entry.username,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                color: HoneyTheme.textPrimary,
              ),
            ),
          ),
          _buildStarBadge(entry.totalStars),
        ],
      ),
    );
  }

  BoxDecoration _leaderboardCardDecoration(bool isCurrentUser) {
    return BoxDecoration(
      color: isCurrentUser
          ? HoneyTheme.honeyGoldLight.withValues(alpha: 0.3)
          : Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      border: isCurrentUser
          ? Border.all(color: HoneyTheme.honeyGold, width: 2)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? avatarUrl, String username) {
    if (avatarUrl != null) {
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl));
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: HoneyTheme.honeyGoldLight,
      child: Text(
        username[0].toUpperCase(),
        style: TextStyle(
          color: HoneyTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingMd),
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _leaderboardCardDecoration(isCurrentUser),
      child: Row(
        children: [
          _buildRankBadge(entry.rank),
          const SizedBox(width: HoneyTheme.spacingMd),
          _buildAvatar(entry.avatarUrl, entry.username),
          const SizedBox(width: HoneyTheme.spacingMd),
          Expanded(child: _buildDailyChallengeInfo(entry, isCurrentUser)),
          if (entry.stars != null) _buildStarBadge(entry.stars!),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeInfo(LeaderboardEntry entry, bool isCurrentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.username,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
            color: HoneyTheme.textPrimary,
          ),
        ),
        if (entry.completionTime != null)
          Text(
            _formatTime(entry.completionTime!),
            style: TextStyle(fontSize: 14.0, color: HoneyTheme.textSecondary),
          ),
      ],
    );
  }

  Widget _buildRankBadge(int rank, {bool isHighlight = false}) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32);
    } else {
      badgeColor = isHighlight
          ? HoneyTheme.deepHoney
          : HoneyTheme.brownAccentLight;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStarBadge(int stars) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingMd,
        vertical: HoneyTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: HoneyTheme.starFilled,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: HoneyTheme.iconSizeMd, color: Colors.black87),
          const SizedBox(width: HoneyTheme.spacingXs),
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: HoneyTheme.iconSizeXl,
              color: Colors.red,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: HoneyTheme.textSecondary),
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: HoneyTheme.honeyGold,
                foregroundColor: HoneyTheme.textPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.brownAccentLight,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: HoneyTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }
}
