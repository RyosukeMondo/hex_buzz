import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/tutorial_repository.dart';

/// Persists tutorial completion state using SharedPreferences.
///
/// Tracks whether the user has completed the onboarding tutorial
/// so it is only shown once (unless explicitly reset).
class LocalTutorialRepository implements TutorialRepository {
  static const _completedKey = 'tutorial_completed';

  final SharedPreferences _prefs;

  LocalTutorialRepository(this._prefs);

  /// Returns true if the user has already completed the tutorial.
  @override
  bool hasCompletedTutorial() {
    return _prefs.getBool(_completedKey) ?? false;
  }

  /// Marks the tutorial as completed so it won't show again.
  @override
  Future<void> markCompleted() async {
    await _prefs.setBool(_completedKey, true);
  }

  /// Resets the tutorial state so it will show again on next launch.
  @override
  Future<void> reset() async {
    await _prefs.remove(_completedKey);
  }
}
