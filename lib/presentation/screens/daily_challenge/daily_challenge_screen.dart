import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../theme/honey_theme.dart';
import '../game/game_screen.dart';

/// Daily challenge screen displaying today's challenge.
///
/// Shows the daily challenge level, completion status, user's best result,
/// and leaderboard rankings. Allows users to start or replay the challenge.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(dailyChallengeProvider);
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: HoneyTheme.warmCream,
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: challengeAsync.when(
          data: (state) => _buildContent(context, ref, state, authAsync),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(error.toString(), () {
            ref.invalidate(dailyChallengeProvider);
          }),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DailyChallengeState state,
    authAsync,
  ) {
    if (state.error != null) {
      return _buildError(state.error!, () {
        ref.read(dailyChallengeProvider.notifier).refresh();
      });
    }

    if (state.challenge == null) {
      return _buildEmpty(
        'No daily challenge available today. Check back later!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dailyChallengeProvider.notifier).refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChallengeCard(context, ref, state.challenge!, authAsync),
            const SizedBox(height: HoneyTheme.spacingLg),
            _buildStatsCard(state.challenge!),
            if (state.challenge!.hasUserCompleted) ...[
              const SizedBox(height: HoneyTheme.spacingLg),
              _buildUserResultCard(state.challenge!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    WidgetRef ref,
    DailyChallenge challenge,
    authAsync,
  ) {
    final user = authAsync.valueOrNull;
    final hasCompleted = challenge.hasUserCompleted;

    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HoneyTheme.honeyGold,
            HoneyTheme.honeyGoldLight.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today,
            size: HoneyTheme.iconSizeLg,
            color: HoneyTheme.textPrimary,
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          Text(
            'Today\'s Challenge',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            _formatDate(challenge.date),
            style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
          ),
          const SizedBox(height: HoneyTheme.spacingXl),
          ElevatedButton.icon(
            onPressed: user == null
                ? null
                : () => _startChallenge(context, ref, challenge),
            icon: Icon(hasCompleted ? Icons.replay : Icons.play_arrow),
            label: Text(hasCompleted ? 'Play Again' : 'Start Challenge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoneyTheme.deepHoney,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: HoneyTheme.spacingXl,
                vertical: HoneyTheme.spacingMd,
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (user == null)
            Padding(
              padding: const EdgeInsets.only(top: HoneyTheme.spacingSm),
              child: Text(
                'Sign in to participate',
                style: TextStyle(
                  fontSize: 14,
                  color: HoneyTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(DailyChallenge challenge) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStatRow(
            Icons.people,
            'Completions',
            '${challenge.completionCount}',
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildStatRow(
            Icons.grid_on,
            'Grid Size',
            '${challenge.level.size}×${challenge.level.size}',
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildStatRow(
            Icons.location_on,
            'Checkpoints',
            '${challenge.level.checkpointCount}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HoneyTheme.brownAccent),
        const SizedBox(width: HoneyTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserResultCard(DailyChallenge challenge) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: _userResultCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHeader(),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildResultStats(challenge),
        ],
      ),
    );
  }

  BoxDecoration _userResultCardDecoration() {
    return BoxDecoration(
      color: HoneyTheme.honeyGoldLight.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
      border: Border.all(color: HoneyTheme.honeyGold, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildResultHeader() {
    return Row(
      children: [
        Icon(Icons.emoji_events, color: HoneyTheme.deepHoney, size: 24),
        const SizedBox(width: HoneyTheme.spacingSm),
        Text(
          'Your Best Result',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultStats(DailyChallenge challenge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildResultStat('Rank', '#${challenge.userRank}', Icons.leaderboard),
        _buildResultStat('Stars', '${challenge.userStars}', Icons.star),
        _buildResultStat(
          'Time',
          _formatTime(challenge.userBestTime!),
          Icons.timer,
        ),
      ],
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: HoneyTheme.deepHoney),
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: HoneyTheme.textSecondary),
        ),
      ],
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
              style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
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
              Icons.calendar_today_outlined,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.brownAccentLight,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _startChallenge(
    BuildContext context,
    WidgetRef ref,
    DailyChallenge challenge,
  ) {
    // TODO: Extend GameProvider to support starting with a specific Level
    // For now, just navigate to game screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GameScreen()));
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }
}
