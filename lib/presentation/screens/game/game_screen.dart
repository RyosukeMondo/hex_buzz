import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/hex_cell.dart';
import '../../providers/game_provider.dart';
import '../../widgets/hex_grid/hex_grid_widget.dart';

/// Main game screen that displays the hexagonal grid and handles gameplay.
///
/// Uses Riverpod for state management, connecting [HexGridWidget] interactions
/// to [GameEngine] via [gameProvider].
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final visitedCells = gameState.path.toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Honeycomb One Pass'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gameProvider.notifier).reset(),
            tooltip: 'Reset (same level)',
          ),
          // New level button
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () => ref.read(gameProvider.notifier).generateNewLevel(),
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
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => notifier.generateNewLevel(),
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('Next'),
            ),
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
    final formattedTime = _formatDuration(gameState.elapsedTime);
    final notifier = ref.read(gameProvider.notifier);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                _buildCompletionTitle(context),
                const SizedBox(height: 8),
                Text(
                  'Time: $formattedTime',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildCompletionButtons(notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionTitle(BuildContext context) {
    return Text(
      'Complete!',
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCompletionButtons(GameNotifier notifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => notifier.reset(),
          icon: const Icon(Icons.refresh),
          label: const Text('Play Again'),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => notifier.generateNewLevel(),
          icon: const Icon(Icons.skip_next),
          label: const Text('Next Level'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}.'
          '${milliseconds.toString().padLeft(2, '0')}';
    }
    return '$seconds.${milliseconds.toString().padLeft(2, '0')}s';
  }
}
