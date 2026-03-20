/// Configuration and logic for ad placement timing.
///
/// Centralizes all ad frequency and cooldown rules so that placement
/// decisions are consistent across the app. All constants and logic
/// live here as a single source of truth for monetization behavior.
class AdPlacement {
  /// Number of levels completed before showing an interstitial ad.
  static const int levelsBeforeInterstitial = 3;

  /// Maximum number of free hints a user can earn per calendar day.
  static const int freeHintsPerDay = 3;

  /// Minimum seconds between rewarded ad requests for hints.
  static const int hintAdCooldownSeconds = 60;

  AdPlacement._();

  /// Returns true if an interstitial ad should be shown based on the
  /// number of levels completed since the last interstitial was displayed.
  ///
  /// Shows an interstitial every [levelsBeforeInterstitial] levels.
  /// Returns false when [levelsCompletedSinceLastAd] is zero.
  static bool shouldShowInterstitial(int levelsCompletedSinceLastAd) {
    if (levelsCompletedSinceLastAd <= 0) return false;
    return levelsCompletedSinceLastAd % levelsBeforeInterstitial == 0;
  }

  /// Returns true if enough time has passed since the last rewarded ad
  /// to allow another one.
  ///
  /// [lastAdTimestamp] is the time the last rewarded ad was shown.
  /// Returns true if [lastAdTimestamp] is null (never shown before).
  static bool canShowRewardedAd(DateTime? lastAdTimestamp) {
    if (lastAdTimestamp == null) return true;
    final elapsed = DateTime.now().difference(lastAdTimestamp);
    return elapsed.inSeconds >= hintAdCooldownSeconds;
  }

  /// Returns true if the user has remaining free hints for today.
  ///
  /// [hintsUsedToday] is the number of rewarded-ad hints claimed today.
  static bool hasRemainingFreeHints(int hintsUsedToday) {
    return hintsUsedToday < freeHintsPerDay;
  }
}
