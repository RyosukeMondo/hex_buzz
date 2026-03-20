import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_level.dart';
import '../../domain/services/user_level_repository.dart';

/// Local implementation of [UserLevelRepository] using SharedPreferences.
///
/// Stores user-created levels as a JSON list in SharedPreferences,
/// keyed by user ID. Handles corrupted data gracefully by returning
/// empty lists or null.
class LocalUserLevelRepository implements UserLevelRepository {
  static const String _storageKeyPrefix = 'user_levels_';

  final SharedPreferences _prefs;

  LocalUserLevelRepository(this._prefs);

  /// Gets the storage key for a specific user.
  String _getStorageKey(String userId) => '$_storageKeyPrefix$userId';

  @override
  Future<List<UserLevel>> getMyLevels(String userId) async {
    final jsonString = _prefs.getString(_getStorageKey(userId));
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => UserLevel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<void> saveLevel(UserLevel level) async {
    final levels = await getMyLevels(level.creatorId);
    final existingIndex = levels.indexWhere((l) => l.id == level.id);

    if (existingIndex >= 0) {
      levels[existingIndex] = level;
    } else {
      levels.add(level);
    }

    await _persistLevels(level.creatorId, levels);
  }

  @override
  Future<void> deleteLevel(String levelId) async {
    // Search across all users' levels for the level to delete
    final allKeys = _prefs.getKeys().where(
      (k) => k.startsWith(_storageKeyPrefix),
    );

    for (final key in allKeys) {
      final userId = key.substring(_storageKeyPrefix.length);
      final levels = await getMyLevels(userId);
      final filtered = levels.where((l) => l.id != levelId).toList();

      if (filtered.length != levels.length) {
        await _persistLevels(userId, filtered);
        return;
      }
    }
  }

  @override
  Future<UserLevel?> getLevelByShareCode(String code) async {
    final allKeys = _prefs.getKeys().where(
      (k) => k.startsWith(_storageKeyPrefix),
    );

    for (final key in allKeys) {
      final userId = key.substring(_storageKeyPrefix.length);
      final levels = await getMyLevels(userId);

      for (final level in levels) {
        if (level.shareCode == code) return level;
      }
    }

    return null;
  }

  /// Persists the full list of levels for a user.
  Future<void> _persistLevels(String userId, List<UserLevel> levels) async {
    final jsonList = levels.map((l) => l.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_getStorageKey(userId), jsonString);
  }
}
