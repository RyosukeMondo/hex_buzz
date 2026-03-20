import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/diagnostic_logger.dart';
import '../../core/logging/logger.dart';

/// Configuration for the smart rating prompt system.
///
/// Controls when and how often users are prompted to rate the app,
/// ensuring prompts occur at optimal moments without being intrusive.
class RatingConfig {
  /// Minimum levels completed before showing a rating prompt.
  static const int minLevelsBeforePrompt = 5;

  /// Minimum days since first launch before showing a rating prompt.
  static const int minDaysBeforePrompt = 2;

  /// Cooldown period in days after a user declines or chooses "later".
  static const int promptCooldownDays = 30;

  /// Maximum number of rating prompts shown to a user.
  static const int maxPrompts = 3;

  RatingConfig._();
}

/// Manages smart rating prompts to encourage app store reviews.
///
/// Tracks user interaction history via [SharedPreferences] and determines
/// the optimal moments to show a rating dialog. Respects user choices
/// (rated, declined, later) and enforces cooldown periods.
class RatingService {
  final SharedPreferences _prefs;

  static const _hasRatedKey = 'rating_has_rated';
  static const _promptCountKey = 'rating_prompt_count';
  static const _lastPromptDateKey = 'rating_last_prompt_date';
  static const _firstLaunchDateKey = 'rating_first_launch_date';
  static const _declinedKey = 'rating_declined';

  /// Creates a [RatingService] backed by the given [SharedPreferences].
  RatingService(this._prefs) {
    _ensureFirstLaunchDate();
  }

  void _ensureFirstLaunchDate() {
    if (_prefs.getString(_firstLaunchDateKey) == null) {
      _prefs.setString(
        _firstLaunchDateKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// Whether the user should be shown a rating prompt.
  ///
  /// Returns `true` only when all conditions are met:
  /// - User has not already rated
  /// - User has not permanently declined
  /// - Prompt count is below [RatingConfig.maxPrompts]
  /// - Enough levels have been completed
  /// - Enough days have passed since first launch
  /// - Cooldown period has elapsed since last prompt
  bool shouldPromptForRating({
    required int levelsCompleted,
    required int totalStars,
  }) {
    if (_hasRated) return false;
    if (_hasDeclined) return false;
    if (_promptCount >= RatingConfig.maxPrompts) return false;
    if (levelsCompleted < RatingConfig.minLevelsBeforePrompt) return false;
    if (!_hasMinDaysPassed) return false;
    if (!_hasCooldownElapsed) return false;

    DiagnosticLogger.logEvent(
      'rating_prompt_eligible',
      data: {
        'levelsCompleted': levelsCompleted,
        'totalStars': totalStars,
        'promptCount': _promptCount,
      },
      level: LogLevel.debug,
    );

    return true;
  }

  /// Records that the user has rated the app. No further prompts will show.
  Future<void> markRated() async {
    await _prefs.setBool(_hasRatedKey, true);
    DiagnosticLogger.logEvent(
      'rating_user_rated',
      level: LogLevel.info,
    );
  }

  /// Records that the user permanently declined to rate.
  Future<void> markDeclined() async {
    await _prefs.setBool(_declinedKey, true);
    await _incrementPromptCount();
    await _updateLastPromptDate();
    DiagnosticLogger.logEvent(
      'rating_user_declined',
      level: LogLevel.info,
    );
  }

  /// Records that the user chose "Later", starting a cooldown period.
  Future<void> markLater() async {
    await _incrementPromptCount();
    await _updateLastPromptDate();
    DiagnosticLogger.logEvent(
      'rating_user_later',
      data: {'promptCount': _promptCount},
      level: LogLevel.info,
    );
  }

  bool get _hasRated => _prefs.getBool(_hasRatedKey) ?? false;

  bool get _hasDeclined => _prefs.getBool(_declinedKey) ?? false;

  int get _promptCount => _prefs.getInt(_promptCountKey) ?? 0;

  bool get _hasMinDaysPassed {
    final firstLaunchStr = _prefs.getString(_firstLaunchDateKey);
    if (firstLaunchStr == null) return false;

    final firstLaunch = DateTime.tryParse(firstLaunchStr);
    if (firstLaunch == null) return false;

    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    return daysSinceFirstLaunch >= RatingConfig.minDaysBeforePrompt;
  }

  bool get _hasCooldownElapsed {
    final lastPromptStr = _prefs.getString(_lastPromptDateKey);
    if (lastPromptStr == null) return true;

    final lastPrompt = DateTime.tryParse(lastPromptStr);
    if (lastPrompt == null) return true;

    final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
    return daysSinceLastPrompt >= RatingConfig.promptCooldownDays;
  }

  Future<void> _incrementPromptCount() async {
    await _prefs.setInt(_promptCountKey, _promptCount + 1);
  }

  Future<void> _updateLastPromptDate() async {
    await _prefs.setString(
      _lastPromptDateKey,
      DateTime.now().toIso8601String(),
    );
  }
}
