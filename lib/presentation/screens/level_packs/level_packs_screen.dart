import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/level_pack.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/level_pack_provider.dart';
import '../../theme/honey_theme.dart';

/// Screen showing all available level packs.
///
/// Displays each pack as a card with icon, name, description,
/// difficulty badge, and progress bar. Tapping a pack navigates
/// to [PackLevelsScreen] to show the levels within that pack.
class LevelPacksScreen extends ConsumerWidget {
  const LevelPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(levelPackProvider);

    return KeyboardShortcuts(
      onBack: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.levels);
      },
      child: Scaffold(
        backgroundColor: HoneyTheme.warmCream,
        body: SafeArea(
          child: packsAsync.when(
            data: (packs) => _buildContent(context, ref, packs),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => _buildError(context, ref, error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<LevelPack> packs,
  ) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(HoneyTheme.spacingLg),
            itemCount: packs.length,
            itemBuilder: (context, index) => _PackCard(pack: packs[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            color: HoneyTheme.textPrimary,
          ),
          Expanded(
            child: Text(
              'Level Packs',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: HoneyTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: HoneyTheme.iconSizeLg,
            color: Colors.red,
          ),
          const SizedBox(height: HoneyTheme.spacingLg),
          Text('Error loading packs: $error'),
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

/// Card widget for a single level pack.
class _PackCard extends ConsumerWidget {
  final LevelPack pack;

  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(packProgressProvider(pack.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: HoneyTheme.spacingMd),
      child: progressAsync.when(
        data: (progress) => _buildCard(context, ref, progress),
        loading: () => _buildCard(context, ref, LevelPackProgress.empty(pack.id)),
        error: (_, __) => _buildCard(context, ref, LevelPackProgress.empty(pack.id)),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, LevelPackProgress progress) {
    final difficultyColor = _getDifficultyColor(pack.difficulty);
    final completionPct = progress.completionPercentage(pack.levelCount);
    final maxStars = pack.levelCount * 3;

    return Semantics(
      label: '${pack.name}, ${pack.difficulty.displayName}, '
          '${progress.completedCount} of ${pack.levelCount} levels completed',
      button: true,
      child: GestureDetector(
        onTap: () {
          ref.read(analyticsServiceProvider).trackEvent(
            AnalyticsEventType.levelPackOpened,
            properties: {
              'packId': pack.id,
              'packName': pack.name,
              'difficulty': pack.difficulty.name,
            },
          );
          Navigator.of(context).pushNamed(
            AppRoutes.packLevels,
            arguments: pack.id,
          );
        },
        child: Container(
        padding: const EdgeInsets.all(HoneyTheme.spacingLg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
          border: Border.all(
            color: difficultyColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HoneyTheme.brownAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(context, difficultyColor),
            const SizedBox(height: HoneyTheme.spacingSm),
            _buildDescription(context),
            const SizedBox(height: HoneyTheme.spacingMd),
            _buildProgressSection(context, progress, completionPct, maxStars),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, Color difficultyColor) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
            ),
            child: Icon(
              _getPackIcon(pack.iconName),
              color: difficultyColor,
              size: HoneyTheme.iconSizeMd,
            ),
          ),
        ),
        const SizedBox(width: HoneyTheme.spacingMd),
        Expanded(
          child: Text(
            pack.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: HoneyTheme.textPrimary,
            ),
          ),
        ),
        _buildDifficultyBadge(context, difficultyColor),
      ],
    );
  }

  Widget _buildDifficultyBadge(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HoneyTheme.spacingSm,
        vertical: HoneyTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        pack.difficulty.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      pack.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: HoneyTheme.textSecondary,
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    LevelPackProgress progress,
    double completionPct,
    int maxStars,
  ) {
    final difficultyColor = _getDifficultyColor(pack.difficulty);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.completedCount}/${pack.levelCount} levels',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HoneyTheme.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: HoneyTheme.starFilled,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.totalStars}/$maxStars',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HoneyTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completionPct,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(difficultyColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  static Color _getDifficultyColor(LevelPackDifficulty difficulty) {
    switch (difficulty) {
      case LevelPackDifficulty.beginner:
        return const Color(0xFF4CAF50); // Green
      case LevelPackDifficulty.intermediate:
        return const Color(0xFFFFC107); // Amber/Yellow
      case LevelPackDifficulty.advanced:
        return const Color(0xFFFF9800); // Orange
      case LevelPackDifficulty.expert:
        return const Color(0xFFF44336); // Red
    }
  }

  static IconData _getPackIcon(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'flag':
        return Icons.flag;
      case 'wall':
        return Icons.border_all;
      case 'military_tech':
        return Icons.military_tech;
      default:
        return Icons.extension;
    }
  }
}
