import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/hex_cell.dart';
import '../../../domain/services/timed_challenge_service.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/timed_challenge_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/hex_grid.dart';
import 'timed_challenge_game_over.dart';

/// Main timed challenge gameplay screen.
///
/// Displays a countdown timer, stats bar, and the hex grid puzzle.
/// When a puzzle is solved, awards bonus time and auto-loads the next puzzle.
/// When time runs out, shows the game over overlay.
class TimedChallengeScreen extends ConsumerStatefulWidget {
  final TimedChallengeConfig config;

  const TimedChallengeScreen({super.key, required this.config});

  @override
  ConsumerState<TimedChallengeScreen> createState() =>
      _TimedChallengeScreenState();
}

class _TimedChallengeScreenState extends ConsumerState<TimedChallengeScreen> {
  DateTime? _puzzleStartTime;
  bool _challengeStarted = false;
  String? _bonusText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChallenge();
    });
  }

  void _startChallenge() {
    if (_challengeStarted) return;
    _challengeStarted = true;
    _puzzleStartTime = DateTime.now();
    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.timedChallengeStarted,
      properties: {
        'mode': widget.config.id,
        'timeLimitSeconds': widget.config.timeLimit.inSeconds,
      },
    );
    ref.read(timedChallengeProvider.notifier).startChallenge(widget.config);
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(timedChallengeProvider);
    final gameState = ref.watch(gameProvider);

    // Listen for puzzle completion
    ref.listen(gameProvider, (previous, next) {
      if (previous != null &&
          !previous.isComplete &&
          next.isComplete &&
          challengeState.isActive &&
          !challengeState.isGameOver) {
        _onPuzzleSolved();
      }
    });

    // Listen for game over
    ref.listen(timedChallengeProvider, (previous, next) {
      if (previous != null && !previous.isGameOver && next.isGameOver) {
        ref.read(analyticsServiceProvider).trackEvent(
          AnalyticsEventType.timedChallengeGameOver,
          properties: {
            'mode': widget.config.id,
            'score': next.score,
            'puzzlesSolved': next.puzzlesSolved,
            'bestStreak': next.bestStreak,
          },
        );
      }
    });

    return ProviderScope(
      overrides: [
        gameConfigProvider.overrideWithValue(
          GameConfig(mode: GameMode.timed, edgeSize: widget.config.startingEdgeSize),
        ),
      ],
      child: KeyboardShortcuts(
        onBack: () => _navigateBack(context),
        child: Scaffold(
          backgroundColor: HoneyTheme.warmCream,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTimerBar(context, challengeState),
                    _buildStatsBar(context, challengeState),
                    Expanded(
                      child: _buildGameArea(gameState),
                    ),
                    _buildBottomControls(context, challengeState),
                  ],
                ),
                if (_bonusText != null)
                  _buildBonusAnimation(context),
                if (challengeState.isGameOver)
                  TimedChallengeGameOver(
                    state: challengeState,
                    onPlayAgain: _playAgain,
                    onBackToMenu: () => _navigateBack(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar(
    BuildContext context,
    dynamic challengeState,
  ) {
    final remaining = challengeState.timeRemainingMs;
    final total = widget.config.timeLimit.inMilliseconds;
    final fraction = total > 0 ? remaining / total : 0.0;
    final timerColor = _getTimerColor(remaining);
    final seconds = remaining / 1000;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: timerColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: timerColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _navigateBack(context),
                icon: const Icon(Icons.arrow_back),
                color: HoneyTheme.textPrimary,
                tooltip: 'Back',
              ),
              Semantics(
                label: '${seconds.ceil()} seconds remaining',
                liveRegion: true,
                child: Text(
                  _formatTimer(seconds),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: HoneyTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    dynamic challengeState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingSm,
      ),
      color: HoneyTheme.warmCreamDark.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            context,
            icon: Icons.extension,
            label: 'Solved',
            value: '${challengeState.puzzlesSolved}',
          ),
          _buildStatChip(
            context,
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${challengeState.currentStreak}',
            highlight: challengeState.currentStreak >= 3,
          ),
          _buildStatChip(
            context,
            icon: Icons.star,
            label: 'Score',
            value: '${challengeState.score}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 16,
                  color: highlight
                      ? HoneyTheme.deepHoney
                      : HoneyTheme.brownAccent,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: highlight
                          ? HoneyTheme.deepHoney
                          : HoneyTheme.textPrimary,
                    ),
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HoneyTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(dynamic gameState) {
    final visitedCells = gameState.path.toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HexGridWidget(
        level: gameState.level,
        path: gameState.path,
        visitedCells: visitedCells,
        onCellEntered: (cell) => _handleCellEntered(cell),
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    dynamic challengeState,
  ) {
    if (!challengeState.isActive || challengeState.isGameOver) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ref.read(gameProvider.notifier).reset(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: HoneyTheme.spacingMd),
          Expanded(
            child: FilledButton.icon(
              onPressed: _onSkip,
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('Skip'),
              style: FilledButton.styleFrom(
                backgroundColor: HoneyTheme.brownAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusAnimation(BuildContext context) {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 0.0),
          duration: const Duration(milliseconds: 1200),
          onEnd: () {
            if (mounted) {
              setState(() => _bonusText = null);
            }
          },
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HoneyTheme.spacingLg,
              vertical: HoneyTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _bonusText ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCellEntered(HexCell cell) {
    final notifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);

    // Check if moving back to previous cell (undo)
    if (gameState.path.length >= 2) {
      final previousCell = gameState.path[gameState.path.length - 2];
      if (cell.q == previousCell.q && cell.r == previousCell.r) {
        notifier.undo();
        return;
      }
    }

    notifier.tryMove(cell);
  }

  void _onPuzzleSolved() {
    final solveTime = _puzzleStartTime != null
        ? DateTime.now().difference(_puzzleStartTime!)
        : Duration.zero;

    final config = widget.config;
    final service = ref.read(timedChallengeServiceProvider);
    final challengeState = ref.read(timedChallengeProvider);
    final bonus = service.getBonusTime(config, challengeState.puzzlesSolved);
    final bonusSeconds = bonus.inMilliseconds / 1000;

    setState(() {
      _bonusText = 'Solved! +${bonusSeconds.toStringAsFixed(0)}s';
    });

    ref.read(timedChallengeProvider.notifier).onPuzzleSolved(solveTime);
    _puzzleStartTime = DateTime.now();
  }

  void _onSkip() {
    ref.read(timedChallengeProvider.notifier).onPuzzleSkipped();
    _puzzleStartTime = DateTime.now();
  }

  void _playAgain() {
    setState(() {
      _bonusText = null;
      _puzzleStartTime = DateTime.now();
    });
    ref.read(timedChallengeProvider.notifier).startChallenge(widget.config);
  }

  void _navigateBack(BuildContext context) {
    ref.read(timedChallengeProvider.notifier).endChallenge();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.timedChallengeMenu);
    }
  }

  Color _getTimerColor(int remainingMs) {
    if (remainingMs > 30000) return Colors.green.shade700;
    if (remainingMs > 10000) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _formatTimer(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    final tenths = ((seconds * 10) % 10).floor();
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}.$tenths';
    }
    return '$secs.$tenths';
  }
}
