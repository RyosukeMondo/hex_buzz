import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge_state.dart';
import '../../../domain/models/progress_state.dart';
import '../../../domain/models/user.dart';
import '../../../main.dart';
import '../../../platform/windows/keyboard_shortcuts.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/progress_provider.dart';
import '../../theme/honey_theme.dart';
import '../../widgets/assets/game_assets.dart';
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

    return KeyboardShortcuts(
      onBack: () {
        // Navigate back to front screen (Escape)
        Navigator.of(context).pushReplacementNamed(AppRoutes.front);
      },
      child: Scaffold(
        backgroundColor: HoneyTheme.warmCream,
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
    // Watch daily challenge state if user is logged in
    final dailyChallengeState = user != null
        ? ref.watch(dailyChallengeProvider(user.id))
        : null;

    return Column(
      children: [
        _buildHeader(
          context,
          ref,
          progressState,
          totalLevels,
          user,
          dailyChallengeState,
        ),
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
    DailyChallengeState? dailyChallengeState,
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
        image: const DecorationImage(
          image: AssetImage(GameAssetPaths.headerBanner),
          fit: BoxFit.cover,
          opacity: 0.3,
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
          _buildTitleRow(context, ref, user, dailyChallengeState),
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

  Widget _buildTitleRow(
    BuildContext context,
    WidgetRef ref,
    User? user,
    DailyChallengeState? dailyChallengeState,
  ) {
    final isLoggedIn = user != null;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
              icon: const Icon(Icons.settings),
              color: HoneyTheme.textPrimary,
              tooltip: 'Settings',
            ),
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
        ),
        const SizedBox(height: HoneyTheme.spacingMd),
        _buildNavigationChips(context, dailyChallengeState),
      ],
    );
  }

  Widget _buildNavigationChips(
    BuildContext context,
    DailyChallengeState? dailyChallengeState,
  ) {
    final showDailyBadge =
        dailyChallengeState is DailyChallengeStateNotStarted;
    final nav = Navigator.of(context);
    const gap = SizedBox(width: HoneyTheme.spacingSm);

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.03, 0.97, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: HoneyTheme.spacingMd,
          vertical: HoneyTheme.spacingXs,
        ),
        child: Row(
          children: [
            _buildChip(context, label: 'Daily', icon: Icons.event,
              showBadge: showDailyBadge,
              onPressed: () => nav.pushNamed(AppRoutes.dailyChallenge)),
            gap,
            _buildChip(context, label: 'Packs', icon: Icons.collections_bookmark,
              onPressed: () => nav.pushNamed(AppRoutes.levelPacks)),
            gap,
            _buildChip(context, label: 'Timed', icon: Icons.timer,
              onPressed: () => nav.pushNamed(AppRoutes.timedChallengeMenu)),
            gap,
            _buildAchievementsChip(context),
            gap,
            _buildChip(context, label: 'Friends', icon: Icons.people,
              onPressed: () => nav.pushNamed(AppRoutes.friends)),
            gap,
            _buildChip(context, label: 'Create', icon: Icons.edit,
              onPressed: () => nav.pushNamed(AppRoutes.myLevels)),
            gap,
            _buildChip(context, label: 'Store', icon: Icons.shopping_cart,
              onPressed: () => nav.pushNamed(AppRoutes.store)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsChip(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final count = ref.watch(achievementProvider).valueOrNull?.unlockedCount ?? 0;
      return _buildChip(context, label: 'Achievements', icon: Icons.emoji_events,
        badgeCount: count,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.achievements));
    });
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool showBadge = false,
    int? badgeCount,
  }) {
    final hasBadge = showBadge || (badgeCount != null && badgeCount > 0);

    final chip = Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
            side: const BorderSide(color: HoneyTheme.honeyGold, width: 1.5),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(HoneyTheme.radiusLg),
            splashColor: HoneyTheme.honeyGoldLight.withValues(alpha: 0.4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: HoneyTheme.iconSizeSm,
                        color: HoneyTheme.brownAccent,
                      ),
                    ),
                    const SizedBox(width: HoneyTheme.spacingXs),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HoneyTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!hasBadge) return chip;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        Positioned(
          right: -4,
          top: -4,
          child: ExcludeSemantics(
            child: badgeCount != null && badgeCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: HoneyTheme.honeyGold,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: HoneyTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
          ),
        ),
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
    return Semantics(
      label: '$totalStars of $maxStars stars collected',
      child: Container(
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
              semanticLabel: 'Star',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid columns based on screen width
        final int crossAxisCount;
        final double cellSize;
        final double spacing;

        if (constraints.maxWidth >= 1200) {
          // Desktop/Large tablets - 6 columns
          crossAxisCount = 6;
          cellSize = 140;
          spacing = 20;
        } else if (constraints.maxWidth >= 900) {
          // Tablets landscape - 5 columns
          crossAxisCount = 5;
          cellSize = 130;
          spacing = 18;
        } else if (constraints.maxWidth >= 600) {
          // Tablets portrait / large phones - 4 columns
          crossAxisCount = 4;
          cellSize = 120;
          spacing = 16;
        } else if (constraints.maxWidth >= 400) {
          // Medium phones - 3 columns
          crossAxisCount = 3;
          cellSize = 110;
          spacing = 14;
        } else {
          // Small phones - 2 columns
          crossAxisCount = 2;
          cellSize = 140;
          spacing = 12;
        }

        return Padding(
          padding: EdgeInsets.all(spacing),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
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
                size: cellSize,
                onTap: () => _navigateToLevel(context, ref, index),
              );
            },
          ),
        );
      },
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
