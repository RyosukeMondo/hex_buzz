import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/progress_state.dart';
import '../../../domain/models/user.dart';
import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/level_cell/level_cell_widget.dart';

/// Main level selection screen displaying a scrollable grid of levels.
///
/// Shows all available levels with their completion status (stars, locked state).
/// Tapping an unlocked level navigates to [GameScreen] with that level index.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final authAsync = ref.watch(authProvider);
    final levelRepository = ref.watch(levelRepositoryProvider);
    final totalLevels = levelRepository.totalLevelCount;

    return Scaffold(
      body: SafeArea(
        child: progressAsync.when(
          data: (progressState) => _buildContent(
            context,
            ref,
            progressState,
            totalLevels,
            authAsync.valueOrNull,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: HoneyTheme.iconSizeLg,
                  color: Colors.red,
                ),
                const SizedBox(height: HoneyTheme.spacingLg),
                Text('Error loading progress: $error'),
                const SizedBox(height: HoneyTheme.spacingLg),
                ElevatedButton(
                  onPressed: () => ref.invalidate(progressProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProgressState progressState,
    int totalLevels,
    User? user,
  ) {
    return Column(
      children: [
        _buildHeader(context, ref, progressState, totalLevels, user),
        Expanded(
          child: _buildLevelGrid(context, ref, progressState, totalLevels),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ProgressState progressState,
    int totalLevels,
    User? user,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingXl,
        vertical: HoneyTheme.spacingXl - 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HoneyTheme.honeyGold,
            HoneyTheme.honeyGoldLight.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: HoneyTheme.brownAccent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTitleRow(context, ref, user),
          if (user != null) _buildUserGreeting(context, user),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStarsCounter(
            context,
            progressState.totalStars,
            totalLevels * 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, WidgetRef ref, User? user) {
    final isLoggedIn = user != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: isLoggedIn ? 40 : 0),
        Expanded(
          child: Text(
            'HexBuzz',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isLoggedIn
            ? IconButton(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout),
                color: HoneyTheme.textPrimary,
                tooltip: 'Logout',
              )
            : const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildUserGreeting(BuildContext context, User user) {
    return Column(
      children: [
        const SizedBox(height: HoneyTheme.spacingXs),
        Text(
          'Hi, ${user.username}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HoneyTheme.textPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStarsCounter(
    BuildContext context,
    int totalStars,
    int maxStars,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingLg,
        vertical: HoneyTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusXl),
        border: Border.all(
          color: HoneyTheme.honeyGoldDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: HoneyTheme.starFilled,
            size: HoneyTheme.iconSizeMd,
          ),
          const SizedBox(width: HoneyTheme.spacingSm),
          Text(
            '$totalStars / $maxStars',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.front, (route) => false);
    }
  }

  Widget _buildLevelGrid(
    BuildContext context,
    WidgetRef ref,
    ProgressState progressState,
    int totalLevels,
  ) {
    if (totalLevels == 0) {
      return const Center(child: Text('No levels available'));
    }

    return Padding(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: HoneyTheme.gridColumns,
          mainAxisSpacing: HoneyTheme.gridSpacing,
          crossAxisSpacing: HoneyTheme.gridSpacing,
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
            bestTime: progress.bestTime,
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

    Navigator.of(context).pushNamed(AppRoutes.game, arguments: levelIndex);
  }
}
