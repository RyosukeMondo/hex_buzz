import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/services/timed_challenge_service.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/timed_challenge_provider.dart';
import '../../theme/honey_theme.dart';

/// Menu screen for selecting a timed challenge mode.
///
/// Displays three preset modes (Blitz, Sprint, Marathon) as cards,
/// each showing the mode name, time limit, bonus per solve, and best score.
class TimedChallengeMenuScreen extends ConsumerWidget {
  const TimedChallengeMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestScoresAsync = ref.watch(timedChallengeBestScoresProvider);

    return KeyboardShortcuts(
      onBack: () => _navigateBack(context),
      child: Scaffold(
        backgroundColor: HoneyTheme.warmCream,
        appBar: AppBar(
          title: const Text('Timed Challenge'),
          backgroundColor: HoneyTheme.honeyGold,
          foregroundColor: HoneyTheme.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HoneyTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: HoneyTheme.spacingXl),
                ...TimedChallengeConfig.presets.map((config) {
                  final bestScore = bestScoresAsync.whenOrNull(
                    data: (scores) => scores[config.id] ?? 0,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: HoneyTheme.spacingLg,
                    ),
                    child: _buildModeCard(
                      context,
                      config: config,
                      bestScore: bestScore ?? 0,
                      onStart: () => _startChallenge(context, ref, config),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          ExcludeSemantics(
            child: Icon(
              Icons.timer,
              size: HoneyTheme.iconSizeLg,
              color: HoneyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            'Race Against Time',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: HoneyTheme.textPrimary,
                ),
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          Text(
            'Solve as many puzzles as possible before time runs out. '
            'Each solve earns bonus time!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HoneyTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required TimedChallengeConfig config,
    required int bestScore,
    required VoidCallback onStart,
  }) {
    final icon = _getModeIcon(config.id);
    final description = _getModeDescription(config.id);
    final timeText = _formatDuration(config.timeLimit);
    final bestScoreLabel = bestScore > 0
        ? ', best score $bestScore'
        : '';

    return Semantics(
      label: '${config.name} mode, $timeText$bestScoreLabel',
      child: Container(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
        border: Border.all(
          color: HoneyTheme.honeyGold.withValues(alpha: 0.3),
        ),
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
          Row(
            children: [
              Icon(icon, size: 32, color: HoneyTheme.deepHoney),
              const SizedBox(width: HoneyTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HoneyTheme.textPrimary,
                          ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: HoneyTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildModeDetails(context, config),
          const SizedBox(height: HoneyTheme.spacingMd),
          Row(
            children: [
              if (bestScore > 0)
                Expanded(
                  child: _buildBestScore(context, bestScore),
                )
              else
                const Spacer(),
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoneyTheme.deepHoney,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: HoneyTheme.spacingXl,
                    vertical: HoneyTheme.spacingMd,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildModeDetails(
    BuildContext context,
    TimedChallengeConfig config,
  ) {
    final timeText = _formatDuration(config.timeLimit);
    final bonusText = '${config.bonusTimePerSolve.inSeconds}s';

    return Row(
      children: [
        _buildDetailChip(
          context,
          icon: Icons.timer,
          label: timeText,
        ),
        const SizedBox(width: HoneyTheme.spacingMd),
        _buildDetailChip(
          context,
          icon: Icons.add_circle_outline,
          label: '+$bonusText/solve',
        ),
      ],
    );
  }

  Widget _buildDetailChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingSm,
        vertical: HoneyTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: HoneyTheme.warmCream,
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 14, color: HoneyTheme.brownAccent),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: HoneyTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestScore(BuildContext context, int score) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events,
          size: 18,
          color: HoneyTheme.starFilled,
        ),
        const SizedBox(width: 4),
        Text(
          'Best: $score',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: HoneyTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  IconData _getModeIcon(String configId) {
    switch (configId) {
      case 'blitz':
        return Icons.flash_on;
      case 'sprint':
        return Icons.directions_run;
      case 'marathon':
        return Icons.terrain;
      default:
        return Icons.timer;
    }
  }

  String _getModeDescription(String configId) {
    switch (configId) {
      case 'blitz':
        return 'Fast and furious. 60 seconds of pure speed.';
      case 'sprint':
        return 'A balanced 2-minute challenge.';
      case 'marathon':
        return 'Endurance test. 5 minutes of puzzling.';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    }
    return '${duration.inSeconds}s';
  }

  void _startChallenge(
    BuildContext context,
    WidgetRef ref,
    TimedChallengeConfig config,
  ) {
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.timedChallengeStarted,
      properties: {'mode': config.id},
    );
    Navigator.of(context).pushNamed(
      AppRoutes.timedChallenge,
      arguments: config,
    );
  }

  void _navigateBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.levels);
    }
  }
}
