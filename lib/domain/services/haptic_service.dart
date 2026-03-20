import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Types of haptic feedback events in the game.
///
/// Each type maps to a specific [HapticFeedback] pattern appropriate
/// for the interaction's significance and user expectation.
enum HapticType {
  /// Light impact when entering/tapping a cell during path drawing.
  cellTap,

  /// Selection click feedback during continuous path drawing.
  pathDraw,

  /// Light impact on undoing the last move.
  undo,

  /// Medium impact when reaching a checkpoint cell.
  checkpoint,

  /// Heavy impact + vibrate on completing a level.
  completion,

  /// Vibrate pattern on invalid move attempt.
  error,

  /// Selection click on UI button press.
  buttonTap,

  /// Heavy impact on achievement unlock.
  achievement,

  /// Light impact when timer drops below 10 seconds.
  timerWarning,

  /// Heavy impact when time expires.
  timerExpired,
}

/// Provides haptic feedback for game interactions.
///
/// Uses Flutter's built-in [HapticFeedback] and [SystemSound] APIs.
/// All feedback is gated by [_isEnabled] which reads the user's
/// sound/haptic preference from SharedPreferences.
///
/// Platform-guarded: haptics only fire on mobile platforms (iOS/Android).
/// On web and desktop, calls are silently ignored by the framework.
class HapticService {
  final bool Function() _isEnabled;

  /// Creates a [HapticService] with an enabled-state callback.
  ///
  /// The [isEnabled] function is called on every trigger to check
  /// whether haptic feedback is currently enabled in user settings.
  HapticService({required bool Function() isEnabled})
      : _isEnabled = isEnabled;

  /// Whether haptics are supported on the current platform.
  ///
  /// Returns true on iOS and Android. On web and desktop, haptic
  /// APIs are available but may be no-ops.
  bool get _isPlatformSupported {
    // On web, HapticFeedback calls are no-ops but won't crash.
    // On desktop (Windows/macOS/Linux), same behavior.
    // We still call them and let the platform handle it gracefully.
    return !kIsWeb;
  }

  /// Triggers haptic feedback for the given [type].
  ///
  /// Does nothing if haptics are disabled in settings or
  /// if the current platform doesn't support haptic feedback.
  void trigger(HapticType type) {
    if (!_isEnabled() || !_isPlatformSupported) return;

    switch (type) {
      case HapticType.cellTap:
        HapticFeedback.lightImpact();
      case HapticType.pathDraw:
        HapticFeedback.selectionClick();
      case HapticType.undo:
        HapticFeedback.lightImpact();
      case HapticType.checkpoint:
        HapticFeedback.mediumImpact();
      case HapticType.buttonTap:
        HapticFeedback.selectionClick();
      case HapticType.completion:
        _triggerCompletion();
      case HapticType.error:
        HapticFeedback.vibrate();
      case HapticType.achievement:
        HapticFeedback.heavyImpact();
      case HapticType.timerWarning:
        HapticFeedback.lightImpact();
      case HapticType.timerExpired:
        HapticFeedback.heavyImpact();
    }
  }

  /// Triggers a two-part haptic for level completion:
  /// heavy impact followed by system click sound.
  void _triggerCompletion() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }
}
