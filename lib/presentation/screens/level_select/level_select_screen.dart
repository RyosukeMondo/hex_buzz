import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/level_cell/level_cell_widget.dart';
import '../game/game_screen.dart';

/// Main level selection screen displaying a scrollable grid of levels.
///
/// Shows all available levels with their completion status (stars, locked state).
/// Tapping an unlocked level navigates to [GameScreen] with that level index.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final levelRepository = ref.watch(levelRepositoryProvider);
    final totalLevels = levelRepository.totalLevelCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Honeycomb One Pass'),
        backgroundColor: HoneyTheme.honeyGold,
      ),
      body: progressAsync.when(
        data: (progressState) =>
            _buildLevelGrid(context, ref, progressState, totalLevels),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading progress: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(progressProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelGrid(
    BuildContext context,
    WidgetRef ref,
    dynamic progressState,
    int totalLevels,
  ) {
    if (totalLevels == 0) {
      return const Center(child: Text('No levels available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: totalLevels,
        itemBuilder: (context, index) {
          final progress = progressState.getProgress(index);
          final isUnlocked = progressState.isUnlocked(index);

          return LevelCellWidget(
            levelNumber: index + 1,
            stars: progress.stars,
            isUnlocked: isUnlocked,
            isCompleted: progress.completed,
            onTap: () => _navigateToLevel(context, ref, index),
          );
        },
      ),
    );
  }

  void _navigateToLevel(BuildContext context, WidgetRef ref, int levelIndex) {
    final success = ref
        .read(gameProvider.notifier)
        .loadLevelByIndex(levelIndex);

    if (!success) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(levelIndex: levelIndex),
      ),
    );
  }
}
