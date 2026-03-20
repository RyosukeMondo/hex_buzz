import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../domain/models/achievement.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/honey_theme.dart';

/// Screen displaying all achievements grouped by category.
///
/// Shows each achievement with an icon, name, description, progress bar,
/// and unlock status. Secret achievements show "???" until unlocked.
class AchievementScreen extends ConsumerStatefulWidget {
  const AchievementScreen({super.key});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackEvent(
        AnalyticsEventType.achievementScreenOpened,
        properties: {'screen': 'achievement_screen'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementAsync = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: HoneyTheme.honeyGold,
        foregroundColor: HoneyTheme.textOnPrimary,
      ),
      backgroundColor: HoneyTheme.warmCream,
      body: achievementAsync.when(
        data: (_) => _buildContent(context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: HoneyTheme.spacingLg),
              Text('Error loading achievements: $error'),
              const SizedBox(height: HoneyTheme.spacingLg),
              ElevatedButton(
                onPressed: () => ref.invalidate(achievementProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = ref.read(achievementProvider.notifier).getAchievementsList();
    final categories = AchievementCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.all(HoneyTheme.spacingLg),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryItems = items
            .where((i) => i.achievement.category == category)
            .toList();
        if (categoryItems.isEmpty) return const SizedBox.shrink();

        return _AchievementCategorySection(
          category: category,
          items: categoryItems,
        );
      },
    );
  }
}

/// Section header and list of achievements for a single category.
class _AchievementCategorySection extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementWithProgress> items;

  const _AchievementCategorySection({
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: HoneyTheme.spacingMd,
            ),
            child: Text(
              _categoryLabel(category),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: HoneyTheme.brownAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        ...items.map((item) => _AchievementTile(item: item)),
        const SizedBox(height: HoneyTheme.spacingSm),
      ],
    );
  }

  String _categoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.daily:
        return 'Daily Challenges';
      case AchievementCategory.speed:
        return 'Speed';
      case AchievementCategory.social:
        return 'Social';
    }
  }
}

/// Individual achievement tile showing icon, name, description, and progress.
class _AchievementTile extends StatelessWidget {
  final AchievementWithProgress item;

  const _AchievementTile({required this.item});

  String _buildSemanticLabel(bool isLocked, bool isSecret) {
    if (isSecret) {
      return 'Secret achievement, not yet unlocked';
    }
    final name = item.achievement.name;
    final status = item.progress.unlocked ? 'unlocked' : 'locked';
    final current = item.progress.currentValue;
    final required = item.achievement.requiredValue;
    final progress = item.progress.unlocked
        ? 'completed'
        : '$current of $required progress';
    return '$name, $status, $progress';
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !item.progress.unlocked;
    final isSecret = item.achievement.isSecret && isLocked;

    return Semantics(
      label: _buildSemanticLabel(isLocked, isSecret),
      child: Card(
      margin: const EdgeInsets.only(bottom: HoneyTheme.spacingSm),
      elevation: isLocked ? 0 : 2,
      color: isLocked
          ? HoneyTheme.warmCreamDark.withValues(alpha: 0.5)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoneyTheme.radiusMd),
        side: BorderSide(
          color: isLocked
              ? HoneyTheme.lockColor.withValues(alpha: 0.3)
              : HoneyTheme.honeyGold,
          width: isLocked ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(HoneyTheme.spacingMd),
        child: Row(
          children: [
            ExcludeSemantics(child: _buildIcon(isLocked, isSecret)),
            const SizedBox(width: HoneyTheme.spacingMd),
            Expanded(
              child: _buildDetails(context, isLocked, isSecret),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildIcon(bool isLocked, bool isSecret) {
    final iconData = isSecret
        ? Icons.help_outline
        : _resolveIcon(item.achievement.iconName);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isLocked
            ? HoneyTheme.lockColor.withValues(alpha: 0.15)
            : HoneyTheme.honeyGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(HoneyTheme.radiusSm),
      ),
      child: Icon(
        iconData,
        size: HoneyTheme.iconSizeMd,
        color: isLocked ? HoneyTheme.lockColor : HoneyTheme.deepHoney,
      ),
    );
  }

  Widget _buildDetails(BuildContext context, bool isLocked, bool isSecret) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSecret ? '???' : item.achievement.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isLocked ? HoneyTheme.lockColor : HoneyTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isSecret ? 'Secret achievement' : item.achievement.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isLocked
                ? HoneyTheme.lockColor
                : HoneyTheme.textSecondary,
          ),
        ),
        const SizedBox(height: HoneyTheme.spacingSm),
        _buildProgressBar(context, isLocked, isSecret),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    bool isLocked,
    bool isSecret,
  ) {
    if (isSecret) {
      return const SizedBox.shrink();
    }

    final fraction = item.progressFraction;
    final current = item.progress.currentValue;
    final required = item.achievement.requiredValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: isLocked
                ? HoneyTheme.lockColor.withValues(alpha: 0.15)
                : HoneyTheme.warmCreamDark,
            valueColor: AlwaysStoppedAnimation<Color>(
              item.progress.unlocked
                  ? HoneyTheme.honeyGold
                  : HoneyTheme.deepHoneyLight,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.progress.unlocked
              ? 'Unlocked!'
              : '$current / $required',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: item.progress.unlocked
                ? HoneyTheme.deepHoney
                : HoneyTheme.textSecondary,
            fontWeight: item.progress.unlocked
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Maps icon name strings to Material IconData.
  IconData _resolveIcon(String iconName) {
    const iconMap = <String, IconData>{
      'directions_walk': Icons.directions_walk,
      'explore': Icons.explore,
      'public': Icons.public,
      'star': Icons.star,
      'stars': Icons.stars,
      'workspace_premium': Icons.workspace_premium,
      'auto_awesome': Icons.auto_awesome,
      'today': Icons.today,
      'local_fire_department': Icons.local_fire_department,
      'military_tech': Icons.military_tech,
      'bolt': Icons.bolt,
      'speed': Icons.speed,
      'share': Icons.share,
      'emoji_nature': Icons.emoji_nature,
    };
    return iconMap[iconName] ?? Icons.emoji_events;
  }
}
