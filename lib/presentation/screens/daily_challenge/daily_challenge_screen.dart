import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/daily_challenge_state.dart' as domain;
import '../../providers/auth_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/daily_challenge_completion_dialog.dart';
import '../game/game_screen.dart';

/// Daily challenge screen displaying today's challenge with state machine.
///
/// Shows different UI based on the sealed union state:
/// - Loading: Shows loading indicator
/// - NotStarted: Shows challenge preview with "Start Challenge" button
/// - Playing: Navigates to game screen
/// - Suspended: Shows "Challenge Paused" message with resume button
/// - Completed/AlreadyCompleted: Shows completion dialog
/// - Error: Shows error message
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for completion state to show dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupStateListener();
    });
  }

  void _setupStateListener() {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    ref.listen<domain.DailyChallengeState>(dailyChallengeProvider(user.id), (
      previous,
      next,
    ) {
      if (next is domain.DailyChallengeStateCompleted) {
        _showCompletionDialog(next);
      }
    });
  }

  void _showCompletionDialog(domain.DailyChallengeStateCompleted state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        DailyChallengeCompletionDialog.show(
          context,
          completion: state.completion,
          dateId: state.completion.dateId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: authAsync.when(
          data: (user) {
            if (user == null) {
              return _buildSignInRequired();
            }
            return _buildChallengeContent(user.id);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError('Authentication error: $error'),
        ),
      ),
    );
  }

  Widget _buildChallengeContent(String userId) {
    final state = ref.watch(dailyChallengeProvider(userId));

    return switch (state) {
      domain.DailyChallengeStateLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      domain.DailyChallengeStateNotStarted() => _buildNotStarted(state, userId),
      domain.DailyChallengeStatePlaying() => _buildPlaying(state, userId),
      domain.DailyChallengeStateSuspended() => _buildSuspended(state, userId),
      domain.DailyChallengeStateCompleted() => _buildCompleted(state),
      domain.DailyChallengeStateAlreadyCompleted() => _buildAlreadyCompleted(
        state,
      ),
      domain.DailyChallengeStateError(:final message) => _buildError(message),
    };
  }

  Widget _buildNotStarted(
    domain.DailyChallengeStateNotStarted state,
    String userId,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChallengeCard(
            context: context,
            title: 'Today\'s Challenge',
            subtitle: _formatDate(state.challenge.date),
            buttonText: 'Start Challenge',
            onPressed: () {
              ref
                  .read(dailyChallengeProvider(userId).notifier)
                  .startChallenge();
              // Navigate to game after starting
              _navigateToGame(state.challenge);
            },
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          _buildStatsCard(
            gridSize: state.challenge.level.size,
            checkpointCount: state.challenge.level.checkpointCount,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaying(domain.DailyChallengeStatePlaying state, String userId) {
    // Should not normally see this screen when playing, as we navigate to GameScreen
    // But if we do, show a message
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.games, size: 64, color: HoneyTheme.honeyGold),
          const SizedBox(height: HoneyTheme.spacingMd),
          const Text(
            'Challenge in Progress',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          ElevatedButton(
            onPressed: () => _navigateToGame(state.challenge),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspended(
    domain.DailyChallengeStateSuspended state,
    String userId,
  ) {
    final elapsedTime = DateTime.now().difference(state.startTime);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.honeyGold,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            const Text(
              'Challenge Paused',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(HoneyTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: HoneyTheme.spacingSm),
                  const Text(
                    'Timer is still running!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            Text(
              'Elapsed time: ${_formatDuration(elapsedTime)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: HoneyTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(dailyChallengeProvider(userId).notifier).resume();
                _navigateToGame(state.challenge);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume Challenge'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted(domain.DailyChallengeStateCompleted state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.honeyGold,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            const Text(
              'Challenge Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            Text(
              'Stars: ${state.completion.stars}/3',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: HoneyTheme.spacingSm),
            Text(
              'Time: ${_formatTime(state.completion.completionTimeMs)}',
              style: const TextStyle(fontSize: 18),
            ),
            if (state.completion.rank != null) ...[
              const SizedBox(height: HoneyTheme.spacingSm),
              Text(
                'Rank: #${state.completion.rank}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: HoneyTheme.spacingXl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: HoneyTheme.honeyGold,
                foregroundColor: HoneyTheme.textPrimary,
              ),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyCompleted(
    domain.DailyChallengeStateAlreadyCompleted state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.honeyGold,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            const Text(
              'Already Completed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            const Text(
              'You\'ve already completed today\'s challenge!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            Text(
              'Stars: ${state.completion.stars}/3',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: HoneyTheme.spacingSm),
            Text(
              'Time: ${_formatTime(state.completion.completionTimeMs)}',
              style: const TextStyle(fontSize: 18),
            ),
            if (state.completion.rank != null) ...[
              const SizedBox(height: HoneyTheme.spacingSm),
              Text(
                'Rank: #${state.completion.rank}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: HoneyTheme.spacingXl),
            const Text(
              'Come back tomorrow for a new challenge!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: HoneyTheme.honeyGold,
                foregroundColor: HoneyTheme.textPrimary,
              ),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: HoneyTheme.iconSizeXl,
              color: HoneyTheme.brownAccentLight,
            ),
            const SizedBox(height: HoneyTheme.spacingLg),
            const Text(
              'Sign In Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: HoneyTheme.spacingMd),
            Text(
              'Please sign in to participate in daily challenges',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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
              onPressed: () {
                final user = ref.read(authProvider).valueOrNull;
                if (user != null) {
                  ref
                      .read(dailyChallengeProvider(user.id).notifier)
                      .loadChallenge();
                }
              },
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

  Widget _buildChallengeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
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
          const Icon(
            Icons.calendar_today,
            size: HoneyTheme.iconSizeLg,
            color: HoneyTheme.textPrimary,
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: HoneyTheme.textSecondary),
          ),
          const SizedBox(height: HoneyTheme.spacingXl),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow),
            label: Text(buttonText),
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
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required int gridSize,
    required int checkpointCount,
  }) {
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
          const Text(
            'Challenge Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStatRow(Icons.grid_on, 'Grid Size', '$gridSize×$gridSize'),
          const SizedBox(height: HoneyTheme.spacingSm),
          _buildStatRow(Icons.location_on, 'Checkpoints', '$checkpointCount'),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HoneyTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _navigateToGame(DailyChallenge challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(dailyChallenge: challenge),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
