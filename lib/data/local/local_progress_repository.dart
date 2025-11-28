import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';

/// Local implementation of [ProgressRepository] using SharedPreferences.
///
/// Persists player progress to device local storage as JSON.
/// Supports user-specific progress storage using unique storage keys per user.
/// Handles corrupted data gracefully by returning an empty state.
class LocalProgressRepository implements ProgressRepository {
  static const String _storageKeyPrefix = 'progress_state_';

  final SharedPreferences _prefs;

  LocalProgressRepository(this._prefs);

  /// Gets the storage key for a specific user.
  String _getStorageKey(String userId) => '$_storageKeyPrefix$userId';

  @override
  Future<ProgressState> loadForUser(String userId) async {
    final jsonString = _prefs.getString(_getStorageKey(userId));
    if (jsonString == null) {
      return const ProgressState.empty();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProgressState.fromJson(json);
    } on FormatException {
      // Corrupted JSON data - return empty state
      return const ProgressState.empty();
    } on TypeError {
      // Invalid data structure - return empty state
      return const ProgressState.empty();
    }
  }

  @override
  Future<void> saveForUser(String userId, ProgressState state) async {
    final jsonString = jsonEncode(state.toJson());
    await _prefs.setString(_getStorageKey(userId), jsonString);
  }

  @override
  Future<void> resetForUser(String userId) async {
    await _prefs.remove(_getStorageKey(userId));
  }
}
