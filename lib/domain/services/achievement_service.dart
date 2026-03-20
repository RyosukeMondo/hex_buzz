import '../models/achievement.dart';
import '../models/progress_state.dart';
import 'achievement_definitions.dart';

/// Context containing all metrics needed to evaluate achievements.
///
/// Aggregates game state from multiple sources into a single object
/// for the [AchievementService] to evaluate against definitions.
class AchievementContext {
  final ProgressState progress;
  final int dailyChallengesCompleted;
  final int dailyChallengeStreak;
  final int fastCompletionsUnder10s;
  final bool hasCompletedUnder5s;
  final int shareCount;

  const AchievementContext({
    required this.progress,
    this.dailyChallengesCompleted = 0,
    this.dailyChallengeStreak = 0,
    this.fastCompletionsUnder10s = 0,
    this.hasCompletedUnder5s = false,
    this.shareCount = 0,
  });
}

/// Pure service that evaluates achievement progress against definitions.
///
/// Computes current metric values from game state and compares them
/// to achievement thresholds. Returns only newly unlocked achievements
/// (those that were not previously unlocked but now meet the threshold).
class AchievementService {
  const AchievementService();

  /// Checks all achievements and returns those newly unlocked.
  ///
  /// Compares current state against all achievement definitions. Returns
  /// achievements that meet their threshold but were not previously unlocked.
  /// Updates [currentState] progress values for all achievements.
  AchievementCheckResult checkForNewUnlocks({
    required AchievementState currentState,
    required AchievementContext context,
  }) {
    final newUnlocks = <Achievement>[];
    var updatedState = currentState;

    for (final achievement in AchievementDefinitions.all) {
      final currentValue = _computeMetric(achievement, context, updatedState);
      final wasUnlocked =
          currentState.getProgress(achievement.id)?.unlocked ?? false;
      final isNowUnlocked = currentValue >= achievement.requiredValue;

      final updatedProgress = AchievementProgress(
        achievementId: achievement.id,
        currentValue: currentValue,
        unlocked: wasUnlocked || isNowUnlocked,
        unlockedAt: wasUnlocked
            ? currentState.getProgress(achievement.id)?.unlockedAt
            : (isNowUnlocked ? DateTime.now() : null),
      );

      updatedState = updatedState.withProgress(
        achievement.id,
        updatedProgress,
      );

      if (!wasUnlocked && isNowUnlocked) {
        newUnlocks.add(achievement);
      }
    }

    return AchievementCheckResult(
      newlyUnlocked: newUnlocks,
      updatedState: updatedState,
    );
  }

  /// Computes the current metric value for a specific achievement.
  int _computeMetric(
    Achievement achievement,
    AchievementContext context,
    AchievementState currentState,
  ) {
    switch (achievement.id) {
      // Gameplay: completed levels count
      case 'gameplay_first_steps':
      case 'gameplay_pathfinder':
      case 'gameplay_master_explorer':
        return context.progress.completedLevels;

      // Mastery: total stars
      case 'mastery_star_collector':
      case 'mastery_star_hoarder':
      case 'mastery_star_supernova':
        return context.progress.totalStars;

      // Mastery: 3-star levels count
      case 'mastery_perfectionist':
        return _countThreeStarLevels(context.progress);

      // Daily: challenges completed
      case 'daily_player':
        return context.dailyChallengesCompleted;

      // Daily: streak
      case 'daily_streak_starter':
      case 'daily_weekly_warrior':
        return context.dailyChallengeStreak;

      // Speed: fast completion under 5s
      case 'speed_quick_thinker':
        return context.hasCompletedUnder5s ? 1 : 0;

      // Speed: levels completed under 10s
      case 'speed_speed_demon':
        return context.fastCompletionsUnder10s;

      // Social: share count
      case 'social_butterfly':
        return context.shareCount;

      // Secret: all other achievements unlocked
      case 'social_secret_beekeeper':
        return _countUnlockedExcluding(currentState, achievement.id);

      default:
        return 0;
    }
  }

  /// Counts levels with exactly 3 stars.
  int _countThreeStarLevels(ProgressState progress) {
    return progress.levels.values.where((lp) => lp.stars == 3).length;
  }

  /// Counts unlocked achievements excluding one by ID.
  int _countUnlockedExcluding(AchievementState state, String excludeId) {
    final totalNonSecret = AchievementDefinitions.all
        .where((a) => a.id != excludeId)
        .length;
    final unlockedNonSecret = AchievementDefinitions.all
        .where((a) => a.id != excludeId)
        .where((a) => state.getProgress(a.id)?.unlocked ?? false)
        .length;
    return unlockedNonSecret >= totalNonSecret ? 1 : 0;
  }
}

/// Result of checking achievements for new unlocks.
class AchievementCheckResult {
  /// Achievements that were newly unlocked in this check.
  final List<Achievement> newlyUnlocked;

  /// The updated achievement state with current progress values.
  final AchievementState updatedState;

  const AchievementCheckResult({
    required this.newlyUnlocked,
    required this.updatedState,
  });
}
