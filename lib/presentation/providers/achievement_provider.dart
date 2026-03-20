import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_event.dart';
import '../../domain/models/achievement.dart';
import '../../domain/services/achievement_definitions.dart';
import '../../domain/services/achievement_repository.dart';
import '../../domain/services/achievement_service.dart';
import 'analytics_provider.dart';
import 'auth_provider.dart';

/// Provider for the achievement repository (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., LocalAchievementRepository).
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  throw UnimplementedError(
    'achievementRepositoryProvider must be overridden '
    'with a concrete implementation',
  );
});

/// Provider for the achievement service (pure business logic).
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return const AchievementService();
});

/// AsyncNotifier for managing achievement state.
///
/// Handles loading from repository, checking for new unlocks, and
/// persisting updated state. Integrates with [AchievementRepository]
/// for storage and [AuthProvider] for user-specific achievements.
class AchievementNotifier extends AsyncNotifier<AchievementState> {
  late AchievementRepository _repository;
  String? _currentUserId;

  @override
  Future<AchievementState> build() async {
    _repository = ref.watch(achievementRepositoryProvider);

    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) => _loadForUser(user?.isGuest == true ? 'guest' : user?.id),
      loading: () => const AchievementState.empty(),
      error: (_, __) => const AchievementState.empty(),
    );
  }

  /// Loads achievement state for the given user ID.
  Future<AchievementState> _loadForUser(String? userId) async {
    if (userId == null) {
      _currentUserId = null;
      return const AchievementState.empty();
    }

    _currentUserId = userId;
    return _repository.loadForUser(userId);
  }

  /// Checks for new achievement unlocks and updates state.
  ///
  /// Evaluates all achievements against the provided context. Persists
  /// updated state and returns any newly unlocked achievements.
  Future<List<Achievement>> checkAndUpdate(
    AchievementContext context,
  ) async {
    if (_currentUserId == null) return [];

    final service = ref.read(achievementServiceProvider);
    final currentState = state.valueOrNull ?? const AchievementState.empty();

    final result = service.checkForNewUnlocks(
      currentState: currentState,
      context: context,
    );

    state = await AsyncValue.guard(() async {
      await _repository.saveForUser(_currentUserId!, result.updatedState);
      return result.updatedState;
    });

    // Track newly unlocked achievements
    final analytics = ref.read(analyticsServiceProvider);
    for (final achievement in result.newlyUnlocked) {
      analytics.trackEvent(
        AnalyticsEventType.achievementUnlocked,
        properties: {
          'achievementId': achievement.id,
          'achievementName': achievement.name,
          'category': achievement.category.name,
        },
      );
    }

    return result.newlyUnlocked;
  }

  /// Returns all achievement definitions with their current progress.
  List<AchievementWithProgress> getAchievementsList() {
    final currentState = state.valueOrNull ?? const AchievementState.empty();

    return AchievementDefinitions.all.map((achievement) {
      final progress = currentState.getProgress(achievement.id);
      return AchievementWithProgress(
        achievement: achievement,
        progress: progress ??
            AchievementProgress(achievementId: achievement.id),
      );
    }).toList();
  }

  /// Resets all achievements for the current user.
  Future<void> resetAchievements() async {
    if (_currentUserId == null) return;

    state = await AsyncValue.guard(() async {
      await _repository.resetForUser(_currentUserId!);
      return const AchievementState.empty();
    });
  }
}

/// Combines an achievement definition with its progress for display.
class AchievementWithProgress {
  final Achievement achievement;
  final AchievementProgress progress;

  const AchievementWithProgress({
    required this.achievement,
    required this.progress,
  });

  /// Progress as a fraction from 0.0 to 1.0.
  double get progressFraction {
    if (achievement.requiredValue <= 0) return 1.0;
    final fraction = progress.currentValue / achievement.requiredValue;
    return fraction.clamp(0.0, 1.0);
  }
}

/// Provider for achievement state management.
final achievementProvider =
    AsyncNotifierProvider<AchievementNotifier, AchievementState>(
  AchievementNotifier.new,
);
