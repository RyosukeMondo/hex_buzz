import '../../core/logging/diagnostic_logger.dart';
import '../../core/logging/logger.dart';

/// Manages app update detection and version information.
///
/// Provides a placeholder implementation for checking if a newer version
/// is available. The [isUpdateAvailable] method currently returns `false`
/// and should be connected to platform-specific store APIs in production.
class AppUpdateService {
  /// The current version of the application.
  final String currentVersion;

  /// Creates an [AppUpdateService] with the given [currentVersion].
  AppUpdateService({required this.currentVersion});

  /// Checks if a newer version of the app is available.
  ///
  /// Returns `false` as a placeholder. In production, this should query
  /// the App Store / Play Store API for the latest version.
  Future<bool> isUpdateAvailable() async {
    DiagnosticLogger.logEvent(
      'update_check',
      data: {'currentVersion': currentVersion},
      level: LogLevel.debug,
    );
    return false;
  }

  /// Returns the current app version string.
  ///
  /// Hardcoded to `'1.0.0'` for now. Should use `package_info_plus`
  /// in production to read the actual version from pubspec.
  static String getAppVersion() => '1.0.0';
}
