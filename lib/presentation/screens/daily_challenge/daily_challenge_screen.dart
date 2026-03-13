import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/daily_challenge_state.dart' as domain;
import '../../providers/auth_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/daily_challenge_completion_dialog.dart';
import '../game/game_screen.dart';
import 'daily_challenge_widgets.dart';

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
            if (user == null) return _buildSignInRequired();
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
      domain.DailyChallengeStatePlaying() => _buildPlaying(state),
      domain.DailyChallengeStateSuspended() => _buildSuspended(state, userId),
      domain.DailyChallengeStateCompleted() => ChallengeCompletionView(
        completion: state.completion,
        onBack: () => Navigator.of(context).pop(),
      ),
      domain.DailyChallengeStateAlreadyCompleted() => AlreadyCompletedView(
        completion: state.completion,
        onBack: () => Navigator.of(context).pop(),
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
          ChallengeCard(
            title: 'Today\'s Challenge',
            subtitle: formatChallengeDate(state.challenge.date),
            buttonText: 'Start Challenge',
            onPressed: () {
              ref
                  .read(dailyChallengeProvider(userId).notifier)
                  .startChallenge();
              _navigateToGame(state.challenge);
            },
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          ChallengeStatsCard(
            gridSize: state.challenge.level.size,
            checkpointCount: state.challenge.level.checkpointCount,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaying(domain.DailyChallengeStatePlaying state) {
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
    final elapsed = DateTime.now().difference(state.startTime);

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
            _buildTimerWarning(),
            const SizedBox(height: HoneyTheme.spacingMd),
            Text(
              'Elapsed time: ${formatDuration(elapsed)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: HoneyTheme.spacingXl),
            _buildResumeButton(state, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerWarning() {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: HoneyTheme.spacingSm),
          Text(
            'Timer is still running!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeButton(
    domain.DailyChallengeStateSuspended state,
    String userId,
  ) {
    return ElevatedButton.icon(
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
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  void _navigateToGame(DailyChallenge challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(dailyChallenge: challenge),
      ),
    );
  }
}
