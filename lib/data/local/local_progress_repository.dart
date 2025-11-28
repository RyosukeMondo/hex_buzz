import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';

/// Local implementation of [ProgressRepository] using SharedPreferences.
///
/// Persists player progress to device local storage as JSON.
/// Handles corrupted data gracefully by returning an empty state.
class LocalProgressRepository implements ProgressRepository {
  static const String _storageKey = 'progress_state';

  final SharedPreferences _prefs;

  LocalProgressRepository(this._prefs);

  @override
  Future<ProgressState> load() async {
    final jsonString = _prefs.getString(_storageKey);
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
  Future<void> save(ProgressState state) async {
    final jsonString = jsonEncode(state.toJson());
    await _prefs.setString(_storageKey, jsonString);
  }

  @override
  Future<void> reset() async {
    await _prefs.remove(_storageKey);
  }
}
