import 'dart:convert';
import 'dart:io';

import '../../domain/models/progress_state.dart';
import '../../domain/services/progress_repository.dart';

/// File-based implementation of [ProgressRepository] for CLI use.
///
/// Persists player progress to a JSON file on disk.
/// This implementation does not require Flutter and can be used in pure Dart
/// CLI applications.
class FileProgressRepository implements ProgressRepository {
  static const String defaultFileName = 'progress.json';

  final File _file;

  FileProgressRepository(String path) : _file = File(path);

  /// Creates a repository with the default file name in the given directory.
  factory FileProgressRepository.inDirectory(String directory) {
    return FileProgressRepository('$directory/$defaultFileName');
  }

  @override
  Future<ProgressState> load() async {
    if (!await _file.exists()) {
      return const ProgressState.empty();
    }

    try {
      final jsonString = await _file.readAsString();
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
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(state.toJson());
    await _file.writeAsString(jsonString);
  }

  @override
  Future<void> reset() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }
}
