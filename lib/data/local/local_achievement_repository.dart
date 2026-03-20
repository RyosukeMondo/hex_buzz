import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/achievement.dart';
import '../../domain/services/achievement_repository.dart';

/// Local implementation of [AchievementRepository] using SharedPreferences.
///
/// Persists achievement progress to device local storage as JSON.
/// Supports user-specific storage using unique storage keys per user.
/// Handles corrupted data gracefully by returning an empty state.
class LocalAchievementRepository implements AchievementRepository {
  static const String _storageKeyPrefix = 'achievement_state_';

  final SharedPreferences _prefs;

  LocalAchievementRepository(this._prefs);

  /// Gets the storage key for a specific user.
  String _getStorageKey(String userId) => '$_storageKeyPrefix$userId';

  @override
  Future<AchievementState> loadForUser(String userId) async {
    final jsonString = _prefs.getString(_getStorageKey(userId));
    if (jsonString == null) {
      return const AchievementState.empty();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AchievementState.fromJson(json);
    } on FormatException {
      // Corrupted JSON data - return empty state
      return const AchievementState.empty();
    } on TypeError {
      // Invalid data structure - return empty state
      return const AchievementState.empty();
    }
  }

  @override
  Future<void> saveForUser(String userId, AchievementState state) async {
    final jsonString = jsonEncode(state.toJson());
    await _prefs.setString(_getStorageKey(userId), jsonString);
  }

  @override
  Future<void> resetForUser(String userId) async {
    await _prefs.remove(_getStorageKey(userId));
  }
}
