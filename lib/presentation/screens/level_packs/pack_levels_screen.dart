import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/level.dart';
import '../../../domain/models/level_pack.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/level_pack_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/level_cell/level_cell_widget.dart';

/// Screen showing levels within a specific pack.
///
/// Displays a grid of levels similar to [LevelSelectScreen] but scoped
/// to a single pack. Shows pack name in header, progress stats, and
/// allows navigating to individual pack levels.
class PackLevelsScreen extends ConsumerWidget {
  final String packId;

  const PackLevelsScreen({super.key, required this.packId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(levelPackProvider);

    return KeyboardShortcuts(
      onBack: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: HoneyTheme.warmCream,
        body: SafeArea(
          child: packsAsync.when(
            data: (packs) {
              final pack = packs.where((p) => p.id == packId).firstOrNull;
              if (pack == null) return _buildNotFound(context);
              return _PackLevelsContent(pack: pack);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildError(context, ref, error),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: HoneyTheme.iconSizeLg,
            color: HoneyTheme.textSecondary,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          Text(
            'Pack not found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: HoneyTheme.iconSizeLg,
              color: Colors.red),
          const SizedBox(height: HoneyTheme.spacingLg),
          Text('Error: $error'),
          const SizedBox(height: HoneyTheme.spacingLg),
          ElevatedButton(
            onPressed: () => ref.invalidate(levelPackProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Content widget for pack levels, separated to manage progress state.
class _PackLevelsContent extends ConsumerWidget {
  final LevelPack pack;

  const _PackLevelsContent({required this.pack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(packProgressProvider(pack.id));

    return progressAsync.when(
      data: (progress) => _buildBody(context, ref, progress),
      loading: () => _buildBody(
        context, ref, LevelPackProgress.empty(pack.id),
      ),
      error: (_, __) => _buildBody(
        context, ref, LevelPackProgress.empty(pack.id),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LevelPackProgress progress,
  ) {
    return Column(
      children: [
        _buildHeader(context, progress),
        Expanded(
          child: _buildLevelGrid(context, ref, progress),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, LevelPackProgress progress) {
    final maxStars = pack.levelCount * 3;
    final difficultyColor = _getDifficultyColor(pack.difficulty);

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
          _buildTitleRow(context, difficultyColor),
          const SizedBox(height: HoneyTheme.spacingMd),
          _buildStatsRow(context, progress, maxStars),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, Color difficultyColor) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: HoneyTheme.textPrimary,
        ),
        Expanded(
          child: Text(
            pack.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: HoneyTheme.spacingSm,
            vertical: HoneyTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
            border: Border.all(color: difficultyColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            pack.difficulty.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: difficultyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    LevelPackProgress progress,
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
          Text(
            '${progress.completedCount}/${pack.levelCount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: HoneyTheme.spacingLg),
          const Icon(
            Icons.star,
            color: HoneyTheme.starFilled,
            size: HoneyTheme.iconSizeMd,
          ),
          const SizedBox(width: HoneyTheme.spacingSm),
          Text(
            '${progress.totalStars}/$maxStars',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HoneyTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid(
    BuildContext context,
    WidgetRef ref,
    LevelPackProgress progress,
  ) {
    if (pack.levels.isEmpty) {
      return const Center(child: Text('No levels in this pack'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridConfig = _computeGridConfig(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.all(gridConfig.spacing),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridConfig.columns,
              mainAxisSpacing: gridConfig.spacing,
              crossAxisSpacing: gridConfig.spacing,
              childAspectRatio: 1,
            ),
            itemCount: pack.levels.length,
            itemBuilder: (context, index) {
              final levelProgress = progress.getProgress(index);
              final isUnlocked = progress.isUnlocked(index);

              return LevelCellWidget(
                levelNumber: index + 1,
                stars: levelProgress.stars,
                isUnlocked: isUnlocked,
                isCompleted: levelProgress.completed,
                bestTime: levelProgress.bestTime,
                size: gridConfig.cellSize,
                onTap: () => _navigateToLevel(context, ref, index),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToLevel(
    BuildContext context,
    WidgetRef ref,
    int levelIndex,
  ) {
    if (levelIndex >= pack.levels.length) return;

    final level = pack.levels[levelIndex];

    ref.read(analyticsServiceProvider).trackEvent(
      AnalyticsEventType.packLevelStarted,
      properties: {
        'packId': pack.id,
        'levelIndex': levelIndex,
      },
    );

    // Navigate to game screen with pack context
    Navigator.of(context).pushNamed(
      AppRoutes.game,
      arguments: PackLevelArgs(
        packId: pack.id,
        levelIndex: levelIndex,
        level: level,
      ),
    );
  }

  static Color _getDifficultyColor(LevelPackDifficulty difficulty) {
    switch (difficulty) {
      case LevelPackDifficulty.beginner:
        return const Color(0xFF4CAF50);
      case LevelPackDifficulty.intermediate:
        return const Color(0xFFFFC107);
      case LevelPackDifficulty.advanced:
        return const Color(0xFFFF9800);
      case LevelPackDifficulty.expert:
        return const Color(0xFFF44336);
    }
  }

  static _GridConfig _computeGridConfig(double maxWidth) {
    if (maxWidth >= 1200) {
      return const _GridConfig(columns: 6, cellSize: 140, spacing: 20);
    } else if (maxWidth >= 900) {
      return const _GridConfig(columns: 5, cellSize: 130, spacing: 18);
    } else if (maxWidth >= 600) {
      return const _GridConfig(columns: 4, cellSize: 120, spacing: 16);
    } else if (maxWidth >= 400) {
      return const _GridConfig(columns: 3, cellSize: 110, spacing: 14);
    } else {
      return const _GridConfig(columns: 2, cellSize: 140, spacing: 12);
    }
  }
}

/// Grid configuration for responsive layout.
class _GridConfig {
  final int columns;
  final double cellSize;
  final double spacing;

  const _GridConfig({
    required this.columns,
    required this.cellSize,
    required this.spacing,
  });
}

/// Arguments for navigating to a pack level game.
class PackLevelArgs {
  final String packId;
  final int levelIndex;
  final Level level;

  const PackLevelArgs({
    required this.packId,
    required this.levelIndex,
    required this.level,
  });
}
