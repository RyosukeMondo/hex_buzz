import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/haptic_service.dart';
import 'notification_provider.dart';

/// SharedPreferences key for the sound/haptic enabled setting.
///
/// Shared with the settings screen's sound toggle so both
/// haptic feedback and future audio use the same preference.
const String soundEnabledKey = 'sound_enabled';

/// Provider for [HapticService], wired to the user's sound preference.
///
/// Reads the 'sound_enabled' key from [sharedPreferencesProvider].
/// Defaults to enabled (true) when no preference is stored.
final hapticServiceProvider = Provider<HapticService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HapticService(
    isEnabled: () => prefs.getBool(soundEnabledKey) ?? true,
  );
});
