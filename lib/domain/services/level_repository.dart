import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/level.dart';

/// Repository for loading and managing pre-generated levels.
///
/// Loads levels from bundled assets and provides random level selection
/// by size, ensuring instant level availability without generation delay.
class LevelRepository {
  static const defaultAssetPath = 'assets/levels/pregenerated.json';

  final String _assetPath;
  final Random _random;
  final Future<String> Function(String) _assetLoader;

  Map<int, List<Level>>? _levelsBySize;
  final Map<int, Set<String>> _usedLevelIds = {};

  LevelRepository({
    String? assetPath,
    Random? random,
    Future<String> Function(String)? assetLoader,
  }) : _assetPath = assetPath ?? defaultAssetPath,
       _random = random ?? Random(),
       _assetLoader = assetLoader ?? rootBundle.loadString;

  /// Whether levels have been loaded.
  bool get isLoaded => _levelsBySize != null;

  /// Available level sizes.
  List<int> get availableSizes => _levelsBySize?.keys.toList() ?? [];

  /// Gets the count of available levels for a given size.
  int getLevelCount(int size) => _levelsBySize?[size]?.length ?? 0;

  /// Gets the count of unused levels for a given size.
  int getUnusedCount(int size) {
    final total = getLevelCount(size);
    final used = _usedLevelIds[size]?.length ?? 0;
    return total - used;
  }

  /// Loads pre-generated levels from assets.
  ///
  /// Must be called before using [getRandomLevel].
  /// Safe to call multiple times (will reload if called again).
  Future<void> load() async {
    final jsonString = await _assetLoader(_assetPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final levelsList = data['levels'] as List<dynamic>;
    _levelsBySize = {};

    for (final levelJson in levelsList) {
      final level = Level.fromJson(levelJson as Map<String, dynamic>);
      _levelsBySize!.putIfAbsent(level.size, () => []).add(level);
    }

    // Reset used tracking on reload
    _usedLevelIds.clear();
  }

  /// Gets a random level of the specified size.
  ///
  /// Returns null if no levels are available for that size.
  /// Tracks used levels to avoid repetition until all are used.
  Level? getRandomLevel(int size) {
    if (_levelsBySize == null) {
      throw StateError('LevelRepository not loaded. Call load() first.');
    }

    final levels = _levelsBySize![size];
    if (levels == null || levels.isEmpty) {
      return null;
    }

    // Get unused levels
    final usedIds = _usedLevelIds.putIfAbsent(size, () => {});
    final unusedLevels = levels.where((l) => !usedIds.contains(l.id)).toList();

    // Reset if all used
    if (unusedLevels.isEmpty) {
      usedIds.clear();
      return getRandomLevel(size); // Recurse with cleared set
    }

    // Pick random unused level
    final level = unusedLevels[_random.nextInt(unusedLevels.length)];
    usedIds.add(level.id);
    return level;
  }

  /// Gets a specific level by ID.
  Level? getLevelById(String id) {
    if (_levelsBySize == null) return null;

    for (final levels in _levelsBySize!.values) {
      for (final level in levels) {
        if (level.id == id) return level;
      }
    }
    return null;
  }

  /// Resets the used level tracking, allowing all levels to be selected again.
  void resetUsedTracking() {
    _usedLevelIds.clear();
  }
}
