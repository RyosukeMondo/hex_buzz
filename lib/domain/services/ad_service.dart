import 'package:flutter/widgets.dart';

/// Types of advertisements supported by the app.
enum AdType { banner, interstitial, rewarded }

/// Result of attempting to show an advertisement.
enum AdResult { shown, dismissed, completed, failed, notReady }

/// Abstract interface for advertisement display and management.
///
/// Provides methods to initialize, check readiness, and show ads.
/// Implementations can use different ad backends (AdMob, placeholder, etc.)
/// while consumers depend only on this interface for dependency injection.
abstract class AdService {
  /// Initializes the ad service and pre-loads ad inventory.
  Future<void> initialize();

  /// Returns true if an ad of the given [type] is loaded and ready to show.
  Future<bool> isAdReady(AdType type);

  /// Shows a full-screen interstitial ad.
  ///
  /// Returns [AdResult.shown] if displayed successfully,
  /// [AdResult.notReady] if no ad is loaded,
  /// [AdResult.failed] on error.
  Future<AdResult> showInterstitial();

  /// Shows a rewarded video ad that the user must watch in full.
  ///
  /// Returns [AdResult.completed] if the user watched the entire ad,
  /// [AdResult.dismissed] if the user closed early,
  /// [AdResult.notReady] if no ad is loaded.
  Future<AdResult> showRewarded();

  /// Builds a banner ad widget for embedding in layouts.
  ///
  /// Returns a widget displaying banner ad content, or an empty
  /// container if ads are not available.
  Widget buildBannerAd();

  /// Releases ad resources and cancels pending loads.
  void dispose();
}
