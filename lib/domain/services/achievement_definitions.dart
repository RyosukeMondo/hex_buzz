import '../models/achievement.dart';

/// Central registry of all achievement definitions.
///
/// This is the single source of truth for all achievements in the game.
/// Each achievement has a unique ID, a category, and a required threshold
/// value that must be reached to unlock it.
class AchievementDefinitions {
  AchievementDefinitions._();

  // =============================================
  // Gameplay Achievements
  // =============================================

  static const firstSteps = Achievement(
    id: 'gameplay_first_steps',
    name: 'First Steps',
    description: 'Complete your first level',
    category: AchievementCategory.gameplay,
    iconName: 'directions_walk',
    requiredValue: 1,
  );

  static const pathfinder = Achievement(
    id: 'gameplay_pathfinder',
    name: 'Pathfinder',
    description: 'Complete 10 levels',
    category: AchievementCategory.gameplay,
    iconName: 'explore',
    requiredValue: 10,
  );

  static const masterExplorer = Achievement(
    id: 'gameplay_master_explorer',
    name: 'Master Explorer',
    description: 'Complete 50 levels',
    category: AchievementCategory.gameplay,
    iconName: 'public',
    requiredValue: 50,
  );

  // =============================================
  // Mastery Achievements
  // =============================================

  static const starCollector = Achievement(
    id: 'mastery_star_collector',
    name: 'Star Collector',
    description: 'Earn 10 stars total',
    category: AchievementCategory.mastery,
    iconName: 'star',
    requiredValue: 10,
  );

  static const starHoarder = Achievement(
    id: 'mastery_star_hoarder',
    name: 'Star Hoarder',
    description: 'Earn 50 stars total',
    category: AchievementCategory.mastery,
    iconName: 'stars',
    requiredValue: 50,
  );

  static const perfectionist = Achievement(
    id: 'mastery_perfectionist',
    name: 'Perfectionist',
    description: 'Earn 3 stars on 10 levels',
    category: AchievementCategory.mastery,
    iconName: 'workspace_premium',
    requiredValue: 10,
  );

  static const starSupernova = Achievement(
    id: 'mastery_star_supernova',
    name: 'Star Supernova',
    description: 'Earn 100 stars total',
    category: AchievementCategory.mastery,
    iconName: 'auto_awesome',
    requiredValue: 100,
  );

  // =============================================
  // Daily Achievements
  // =============================================

  static const dailyPlayer = Achievement(
    id: 'daily_player',
    name: 'Daily Player',
    description: 'Complete a daily challenge',
    category: AchievementCategory.daily,
    iconName: 'today',
    requiredValue: 1,
  );

  static const streakStarter = Achievement(
    id: 'daily_streak_starter',
    name: 'Streak Starter',
    description: 'Achieve a 3-day streak',
    category: AchievementCategory.daily,
    iconName: 'local_fire_department',
    requiredValue: 3,
  );

  static const weeklyWarrior = Achievement(
    id: 'daily_weekly_warrior',
    name: 'Weekly Warrior',
    description: 'Achieve a 7-day streak',
    category: AchievementCategory.daily,
    iconName: 'military_tech',
    requiredValue: 7,
  );

  // =============================================
  // Speed Achievements
  // =============================================

  static const quickThinker = Achievement(
    id: 'speed_quick_thinker',
    name: 'Quick Thinker',
    description: 'Complete a level in under 5 seconds',
    category: AchievementCategory.speed,
    iconName: 'bolt',
    requiredValue: 1,
  );

  static const speedDemon = Achievement(
    id: 'speed_speed_demon',
    name: 'Speed Demon',
    description: 'Complete 5 levels in under 10 seconds each',
    category: AchievementCategory.speed,
    iconName: 'speed',
    requiredValue: 5,
  );

  // =============================================
  // Social Achievements
  // =============================================

  static const socialButterfly = Achievement(
    id: 'social_butterfly',
    name: 'Social Butterfly',
    description: 'Share a result',
    category: AchievementCategory.social,
    iconName: 'share',
    requiredValue: 1,
  );

  static const secretBeekeeper = Achievement(
    id: 'social_secret_beekeeper',
    name: 'Secret Beekeeper',
    description: 'Unlock all other achievements',
    category: AchievementCategory.social,
    iconName: 'emoji_nature',
    requiredValue: 1,
    isSecret: true,
  );

  /// All achievement definitions in display order.
  static const List<Achievement> all = [
    // Gameplay
    firstSteps,
    pathfinder,
    masterExplorer,
    // Mastery
    starCollector,
    starHoarder,
    perfectionist,
    starSupernova,
    // Daily
    dailyPlayer,
    streakStarter,
    weeklyWarrior,
    // Speed
    quickThinker,
    speedDemon,
    // Social
    socialButterfly,
    secretBeekeeper,
  ];

  /// Returns achievements filtered by category.
  static List<Achievement> byCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Looks up an achievement by ID. Returns null if not found.
  static Achievement? byId(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }
}
