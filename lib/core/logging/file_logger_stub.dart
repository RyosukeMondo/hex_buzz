import 'dart:async';

/// Stub FileLogger for web platform where dart:io is not available.
///
/// All operations are no-ops. The real implementation is in file_logger.dart.
class FileLogger {
  final String logDirectory;
  final int maxFileSizeBytes;
  final int maxFileCount;

  FileLogger({
    required this.logDirectory,
    this.maxFileSizeBytes = 1024 * 1024,
    this.maxFileCount = 5,
  });

  bool get isInitialized => false;

  Stream<Map<String, dynamic>> get logStream => const Stream.empty();

  Future<void> initialize() async {}

  void write(Map<String, dynamic> logEntry) {}

  Future<List<Map<String, dynamic>>> readLogs({
    int limit = 100,
    String? level,
    String? event,
    DateTime? since,
  }) async => [];

  Future<List<String>> getLogFiles() async => [];

  Future<List<Map<String, dynamic>>> getLogFilesWithMeta() async => [];

  Future<Map<String, dynamic>> getStats() async => {
    'totalEntries': 0,
    'fileCount': 0,
    'totalSizeBytes': 0,
    'levelCounts': <String, int>{},
    'available': false,
  };

  Future<void> rotateLogs() async {}

  Future<String> getLogContent(String filename) async => '';

  Future<void> clearAll() async {}

  void dispose() {}
}
