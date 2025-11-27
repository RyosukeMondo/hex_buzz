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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gameProvider.notifier).reset(),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildGameGrid(ref, gameState, visitedCells),
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
    return HexGridWidget(
      level: gameState.level,
      path: gameState.path,
      visitedCells: visitedCells,
      onCellEntered: (cell) => _handleCellEntered(ref, cell),
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
    final formattedTime = _formatDuration(elapsedTime);

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
                Text(
                  'Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time: $formattedTime',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(gameProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      ),
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
