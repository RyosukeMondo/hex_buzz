import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../domain/models/timed_challenge_state.dart';
import '../../theme/honey_theme.dart';

/// Game over overlay displayed when the timed challenge ends.
///
/// Shows final stats: score, puzzles solved, best streak, average time.
/// Provides "Play Again" and "Back to Menu" actions.
class TimedChallengeGameOver extends StatelessWidget {
  final TimedChallengeState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const TimedChallengeGameOver({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Announce game over for screen readers
    final view = View.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.sendAnnouncement(
        view,
        "Time's up. Score ${state.score}, "
        '${state.puzzlesSolved} puzzles solved',
        TextDirection.ltr,
      );
    });

    return Semantics(
      label: "Time's up. Score ${state.score}, "
          '${state.puzzlesSolved} puzzles solved',
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
          margin: const EdgeInsets.all(HoneyTheme.spacingXxl),
          padding: const EdgeInsets.symmetric(
            horizontal: HoneyTheme.spacingXxl,
            vertical: HoneyTheme.spacingXl,
          ),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(context),
              const SizedBox(height: HoneyTheme.spacingXl),
              _buildScoreDisplay(context),
              const SizedBox(height: HoneyTheme.spacingLg),
              _buildStatsGrid(context),
              const SizedBox(height: HoneyTheme.spacingXl),
              _buildActions(context),
            ],
          ),
        ),
      ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
      border: Border.all(color: HoneyTheme.honeyGold, width: 3),
      boxShadow: [
        BoxShadow(
          color: HoneyTheme.brownAccent.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.timer_off,
            size: HoneyTheme.iconSizeXl,
            color: HoneyTheme.deepHoney,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        Text(
          "Time's Up!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: HoneyTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(BuildContext context) {
    return Semantics(
      label: 'Final Score: ${state.score} points',
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingXl,
        vertical: HoneyTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoneyTheme.honeyGold,
            HoneyTheme.honeyGoldLight,
          ],
        ),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            'Final Score',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: HoneyTheme.textPrimary,
                ),
          ),
          const SizedBox(height: HoneyTheme.spacingXs),
          Text(
            '${state.score}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: HoneyTheme.textPrimary,
                ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        color: HoneyTheme.warmCream,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        border: Border.all(
          color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.extension,
            label: 'Puzzles Solved',
            value: '${state.puzzlesSolved}',
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStatRow(
            context,
            icon: Icons.local_fire_department,
            label: 'Best Streak',
            value: '${state.bestStreak}',
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStatRow(
            context,
            icon: Icons.speed,
            label: 'Avg. Time',
            value: _formatAverageTime(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: HoneyTheme.brownAccent),
          ),
        const SizedBox(width: HoneyTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HoneyTheme.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: HoneyTheme.textPrimary,
              ),
        ),
      ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPlayAgain,
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: FilledButton.styleFrom(
              backgroundColor: HoneyTheme.honeyGold,
              foregroundColor: HoneyTheme.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                vertical: HoneyTheme.spacingMd,
              ),
            ),
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingMd),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBackToMenu,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Menu'),
          ),
        ),
      ],
    );
  }

  String _formatAverageTime() {
    final avg = state.averageSolveTime;
    if (avg <= 0) return '--';
    final seconds = avg / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }
}
