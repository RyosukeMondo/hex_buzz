import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/hex_cell.dart';
import '../../../domain/services/star_calculator.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/completion_overlay/completion_overlay.dart';
import '../../widgets/hex_grid/hex_grid_widget.dart';

/// Main game screen that displays the hexagonal grid and handles gameplay.
///
/// Uses Riverpod for state management, connecting [HexGridWidget] interactions
/// to [GameEngine] via [gameProvider].
///
/// Accepts an optional [levelIndex] parameter to load a specific level.
/// When [levelIndex] is provided, the game tracks progress and displays
/// star ratings on completion.
///
/// Accepts an optional [dailyChallenge] parameter to play the daily challenge.
/// When provided, this takes precedence over [levelIndex].
class GameScreen extends ConsumerStatefulWidget {
  /// Index of the level to load (null for random/practice mode).
  final int? levelIndex;

  /// Daily challenge to play (null for regular levels).
  final DailyChallenge? dailyChallenge;

  const GameScreen({super.key, this.levelIndex, this.dailyChallenge});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _levelLoaded = false;
  bool _scoreSubmitted = false;

  @override
  void initState() {
    super.initState();
    // Load level on first frame to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLevelIfNeeded();
    });
  }

  void _loadLevelIfNeeded() {
    if (_levelLoaded) return;

    if (widget.levelIndex != null) {
      final notifier = ref.read(gameProvider.notifier);
      notifier.loadLevelByIndex(widget.levelIndex!);
    }
    _levelLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in ProviderScope if daily challenge to override config
    if (widget.dailyChallenge != null) {
      return ProviderScope(
        overrides: [
          gameConfigProvider.overrideWithValue(
            GameConfig(
              level: widget.dailyChallenge!.level,
              mode: GameMode.daily,
              isDailyChallenge: true,
            ),
          ),
        ],
        child: _GameScreenContent(
          levelIndex: widget.levelIndex,
          isDailyChallenge: true,
          dailyChallenge: widget.dailyChallenge,
          scoreSubmitted: _scoreSubmitted,
          onScoreSubmitted: () {
            setState(() {
              _scoreSubmitted = true;
            });
          },
        ),
      );
    }

    return _GameScreenContent(
      levelIndex: widget.levelIndex,
      isDailyChallenge: false,
      dailyChallenge: null,
      scoreSubmitted: _scoreSubmitted,
      onScoreSubmitted: () {
        setState(() {
          _scoreSubmitted = true;
        });
      },
    );
  }
}

/// Internal content widget for GameScreen.
class _GameScreenContent extends ConsumerStatefulWidget {
  final int? levelIndex;
  final bool isDailyChallenge;
  final DailyChallenge? dailyChallenge;
  final bool scoreSubmitted;
  final VoidCallback onScoreSubmitted;

  const _GameScreenContent({
    required this.levelIndex,
    required this.isDailyChallenge,
    required this.dailyChallenge,
    required this.scoreSubmitted,
    required this.onScoreSubmitted,
  });

  @override
  ConsumerState<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends ConsumerState<_GameScreenContent> {
  @override
  void didUpdateWidget(_GameScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if game just completed
    final gameState = ref.read(gameProvider);
    if (gameState.isComplete && !widget.scoreSubmitted) {
      _submitScore();
    }
  }

  /// Submits the score to the appropriate leaderboard.
  Future<void> _submitScore() async {
    // Only submit if user is logged in
    final authAsync = ref.read(authProvider);
    final user = authAsync.valueOrNull;
    if (user == null) return;

    // Mark as submitted immediately to prevent duplicate submissions
    widget.onScoreSubmitted();

    final gameState = ref.read(gameProvider);
    final elapsedTime = gameState.elapsedTime;
    final elapsedTimeMs = elapsedTime.inMilliseconds;
    final stars = StarCalculator.calculateStars(elapsedTime);

    try {
      if (widget.isDailyChallenge && widget.dailyChallenge != null) {
        // Submit to daily challenge leaderboard
        await ref
            .read(dailyChallengeProvider.notifier)
            .submitCompletion(
              userId: user.id,
              stars: stars,
              completionTimeMs: elapsedTimeMs,
            );
      } else if (widget.levelIndex != null) {
        // Submit to global leaderboard
        final levelId = 'level_${widget.levelIndex}';
        await ref
            .read(leaderboardProvider.notifier)
            .submitScore(userId: user.id, stars: stars, levelId: levelId);
      }
    } catch (e) {
      // Log error but don't block the game completion
      debugPrint('Failed to submit score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final visitedCells = gameState.path.toSet();

    return KeyboardShortcuts(
      onUndo: () {
        // Undo last move (Ctrl+Z)
        final notifier = ref.read(gameProvider.notifier);
        notifier.undo();
      },
      onBack: () {
        // Navigate back to level select (Escape)
        _navigateToLevelSelect(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: _buildTitle(),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _buildBackButton(context),
          actions: [
            // Reset button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(gameProvider.notifier).reset(),
              tooltip: 'Reset (same level)',
            ),
            // New level button (only in practice mode, not daily challenge)
            if (widget.levelIndex == null && !widget.isDailyChallenge)
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () =>
                    ref.read(gameProvider.notifier).generateNewLevel(),
                tooltip: 'New Level',
              ),
          ],
        ),
        body: Stack(
          children: [
            _buildGameGrid(ref, gameState, visitedCells),
            _buildBottomControls(context, ref),
            if (gameState.isComplete) _buildCompletionOverlay(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    if (widget.isDailyChallenge) {
      return const Text('Daily Challenge');
    }
    if (widget.levelIndex != null) {
      return Text('Level ${widget.levelIndex! + 1}');
    }
    return const Text('HexBuzz');
  }

  Widget? _buildBackButton(BuildContext context) {
    // Show back button when navigated to (there's a previous route)
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => _navigateToLevelSelect(context),
      tooltip: 'Back to Level Select',
    );
  }

  Widget _buildGameGrid(
    WidgetRef ref,
    dynamic gameState,
    Set<HexCell> visitedCells,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // Space for bottom controls
      child: HexGridWidget(
        level: gameState.level,
        path: gameState.path,
        visitedCells: visitedCells,
        onCellEntered: (cell) => _handleCellEntered(ref, cell),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final gameState = ref.watch(gameProvider);
    final cellCount = gameState.level.cells.length;
    final visitedCount = gameState.path.length;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _bottomControlsDecoration(context),
        child: Row(
          children: [
            _buildProgressIndicator(context, visitedCount, cellCount),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
            // Only show Next button in practice mode (not daily challenge)
            if (widget.levelIndex == null && !widget.isDailyChallenge) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => notifier.generateNewLevel(),
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _bottomControlsDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int visited, int total) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress: $visited / $total',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? visited / total : 0,
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  void _handleCellEntered(WidgetRef ref, HexCell cell) {
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

    // Try to move forward
    notifier.tryMove(cell);
  }

  Widget _buildCompletionOverlay(BuildContext context, WidgetRef ref) {
    final gameState = ref.read(gameProvider);
    final elapsedTime = gameState.elapsedTime;
    final stars = StarCalculator.calculateStars(elapsedTime);
    final repository = ref.read(levelRepositoryProvider);
    final hasNextLevel =
        widget.levelIndex != null &&
        widget.levelIndex! + 1 < repository.totalLevelCount;

    return CompletionOverlay(
      stars: stars,
      completionTime: elapsedTime,
      hasNextLevel: hasNextLevel && !widget.isDailyChallenge,
      onNextLevel: hasNextLevel && !widget.isDailyChallenge
          ? () => _goToNextLevel(context, widget.levelIndex)
          : null,
      onReplay: () => ref.read(gameProvider.notifier).reset(),
      onLevelSelect: () => _navigateToLevelSelect(context),
    );
  }

  void _goToNextLevel(BuildContext context, int? currentIndex) {
    if (currentIndex == null) return;

    final nextIndex = currentIndex + 1;
    Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.game, arguments: nextIndex);
  }

  void _navigateToLevelSelect(BuildContext context) {
    // Pop back to level select if we were navigated here
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.levels);
    }
  }
}
