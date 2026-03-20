import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/level_pack.dart';
import '../../domain/services/level_pack_definitions.dart';
import '../../domain/services/level_pack_generator.dart';
import '../../domain/services/level_pack_repository.dart';

/// Local implementation of [LevelPackRepository].
///
/// Generates pack levels on first access using [LevelPackGenerator] and
/// caches them in memory. Persists pack progress to SharedPreferences.
class LocalLevelPackRepository implements LevelPackRepository {
  static const String _progressKeyPrefix = 'level_pack_progress_';

  final SharedPreferences _prefs;
  final LevelPackGenerator _generator;

  /// Cached generated packs (lazy-loaded).
  final Map<String, LevelPack> _cachedPacks = {};
  bool _packsGenerated = false;

  LocalLevelPackRepository({
    required SharedPreferences prefs,
    LevelPackGenerator? generator,
  }) : _prefs = prefs,
       _generator = generator ?? LevelPackGenerator();

  @override
  Future<List<LevelPack>> getAvailablePacks() async {
    _ensurePacksGenerated();
    return LevelPackDefinitions.allPacks
        .map((meta) => _cachedPacks[meta.id]!)
        .toList();
  }

  @override
  Future<LevelPack?> getPack(String packId) async {
    _ensurePacksGenerated();
    return _cachedPacks[packId];
  }

  @override
  Future<LevelPackProgress> getPackProgress(String packId) async {
    final key = _getProgressKey(packId);
    final jsonString = _prefs.getString(key);

    if (jsonString == null) {
      return LevelPackProgress.empty(packId);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return LevelPackProgress.fromJson(json);
    } on FormatException {
      return LevelPackProgress.empty(packId);
    } on TypeError {
      return LevelPackProgress.empty(packId);
    }
  }

  @override
  Future<void> savePackProgress(
    String packId,
    LevelPackProgress progress,
  ) async {
    final key = _getProgressKey(packId);
    final jsonString = jsonEncode(progress.toJson());
    await _prefs.setString(key, jsonString);
  }

  /// Generates all packs if not already done.
  ///
  /// This is called lazily on first access. Each pack's levels are
  /// generated using deterministic seeds for reproducibility.
  void _ensurePacksGenerated() {
    if (_packsGenerated) return;

    for (final meta in LevelPackDefinitions.allPacks) {
      final levels = _generator.generatePack(meta);
      _cachedPacks[meta.id] = LevelPack(
        id: meta.id,
        name: meta.name,
        description: meta.description,
        difficulty: meta.difficulty,
        levelCount: meta.levelCount,
        iconName: meta.iconName,
        isBuiltIn: true,
        levels: levels,
      );
    }

    _packsGenerated = true;
  }

  String _getProgressKey(String packId) => '$_progressKeyPrefix$packId';
}
