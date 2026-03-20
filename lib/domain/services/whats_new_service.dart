import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/diagnostic_logger.dart';
import '../../core/logging/logger.dart';
import 'app_update_service.dart';

/// Tracks whether the "What's New" screen should be shown after an update.
///
/// Compares the last-seen version stored in [SharedPreferences] against
/// the current app version. When they differ, [shouldShowWhatsNew] returns
/// `true` and the caller should present the What's New screen.
class WhatsNewService {
  final SharedPreferences _prefs;
  static const _lastSeenVersionKey = 'last_seen_version';

  /// Creates a [WhatsNewService] backed by the given [SharedPreferences].
  WhatsNewService(this._prefs);

  /// Whether the What's New screen should be displayed.
  ///
  /// Returns `true` if the user has never seen the current version's
  /// changelog (either a fresh install or an update).
  bool shouldShowWhatsNew() {
    final lastSeenVersion = _prefs.getString(_lastSeenVersionKey);
    final currentVersion = AppUpdateService.getAppVersion();

    if (lastSeenVersion == null || lastSeenVersion != currentVersion) {
      DiagnosticLogger.logEvent(
        'whats_new_should_show',
        data: {
          'lastSeenVersion': lastSeenVersion,
          'currentVersion': currentVersion,
        },
        level: LogLevel.debug,
      );
      return true;
    }

    return false;
  }

  /// Marks the current version as seen so the dialog won't show again.
  Future<void> markSeen() async {
    final currentVersion = AppUpdateService.getAppVersion();
    await _prefs.setString(_lastSeenVersionKey, currentVersion);
    DiagnosticLogger.logEvent(
      'whats_new_marked_seen',
      data: {'version': currentVersion},
      level: LogLevel.info,
    );
  }
}
