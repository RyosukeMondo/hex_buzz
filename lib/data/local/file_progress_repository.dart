import 'dart:convert';
import 'dart:io';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';

/// File-based implementation of [ProgressRepository] for CLI use.
///
/// Persists player progress to JSON files on disk.
/// When using user-specific methods (loadForUser, saveForUser, resetForUser),
/// each user has their own progress file: {basePath}_{userId}.json
///
/// For backward compatibility with CLI tools, legacy methods (load, save, reset)
/// use the original single file: {path}.json
///
/// This implementation does not require Flutter and can be used in pure Dart
/// CLI applications.
class FileProgressRepository implements ProgressRepository {
  static const String defaultFileName = 'progress.json';

  final File _legacyFile;
  final String _basePath;

  FileProgressRepository(String path)
    : _legacyFile = File(path),
      _basePath = _removeExtension(path);

  /// Creates a repository with the default file name in the given directory.
  factory FileProgressRepository.inDirectory(String directory) {
    return FileProgressRepository('$directory/$defaultFileName');
  }

  /// Removes .json extension if present for consistent base path handling.
  static String _removeExtension(String path) {
    if (path.endsWith('.json')) {
      return path.substring(0, path.length - 5);
    }
    return path;
  }

  /// Gets the file for a specific user (user-keyed progress).
  File _getFileForUser(String userId) => File('${_basePath}_$userId.json');

  @override
  Future<ProgressState> loadForUser(String userId) async {
    final file = _getFileForUser(userId);
    if (!await file.exists()) {
      return const ProgressState.empty();
    }

    try {
      final jsonString = await file.readAsString();
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
    final file = _getFileForUser(userId);
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(state.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  Future<void> resetForUser(String userId) async {
    final file = _getFileForUser(userId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Legacy method for CLI use - loads progress from single file.
  Future<ProgressState> load() async {
    if (!await _legacyFile.exists()) {
      return const ProgressState.empty();
    }

    try {
      final jsonString = await _legacyFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProgressState.fromJson(json);
    } on FormatException {
      return const ProgressState.empty();
    } on TypeError {
      return const ProgressState.empty();
    }
  }

  /// Legacy method for CLI use - saves progress to single file.
  Future<void> save(ProgressState state) async {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(state.toJson());
    await _legacyFile.writeAsString(jsonString);
  }

  /// Legacy method for CLI use - resets progress by deleting single file.
  Future<void> reset() async {
    if (await _legacyFile.exists()) {
      await _legacyFile.delete();
    }
  }
}
