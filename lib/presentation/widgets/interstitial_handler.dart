import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/monetization_provider.dart';

/// Utility for triggering interstitial ads at level completion.
///
/// Encapsulates the logic for checking whether the user should see
/// an interstitial ad and delegates to [MonetizationNotifier] for
/// the actual display decision.
class InterstitialHandler {
  InterstitialHandler._();

  /// Called when a level is completed to potentially show an interstitial.
  ///
  /// Checks if ads are enabled (not removed via purchase), increments
  /// the level counter, and shows an interstitial if placement rules
  /// dictate it. Fails silently if monetization is not initialized.
  static Future<void> onLevelComplete(WidgetRef ref) async {
    try {
      final notifier = ref.read(monetizationProvider.notifier);
      await notifier.showInterstitialIfNeeded();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InterstitialHandler: skipped ad ($e)');
      }
    }
  }
}
