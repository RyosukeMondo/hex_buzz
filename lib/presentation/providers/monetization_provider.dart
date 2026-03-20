import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/purchase.dart';
import '../../domain/services/ad_placement.dart';
import '../../domain/services/ad_service.dart';
import '../../domain/services/purchase_service.dart';

/// Provider for the ad service (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., PlaceholderAdService).
final adServiceProvider = Provider<AdService>((ref) {
  throw UnimplementedError(
    'adServiceProvider must be overridden with a concrete implementation',
  );
});

/// Provider for the purchase service (dependency injection point).
///
/// Override this provider in main.dart with a concrete implementation
/// (e.g., LocalPurchaseService).
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  throw UnimplementedError(
    'purchaseServiceProvider must be overridden with a concrete implementation',
  );
});

/// AsyncNotifier for managing monetization state.
///
/// Integrates ad display and in-app purchases into a single coherent
/// state manager. Tracks purchase state, interstitial ad counters,
/// and rewarded ad cooldowns. Provides convenience methods for the
/// most common monetization operations.
class MonetizationNotifier extends AsyncNotifier<PurchaseState> {
  int _levelsCompletedSinceLastAd = 0;
  DateTime? _lastRewardedAdTimestamp;

  @override
  Future<PurchaseState> build() async {
    final purchaseService = ref.watch(purchaseServiceProvider);

    // Listen to purchase state changes and update our state
    purchaseService.stateChanges.listen((newState) {
      state = AsyncValue.data(newState);
    });

    return purchaseService.currentState;
  }

  /// Purchases the "Remove Ads" product.
  Future<void> removeAds() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await purchaseService.purchase(ProductId.removeAds);
      return purchaseService.currentState;
    });
  }

  /// Purchases a hint pack (5 or 20 hints).
  Future<void> purchaseHints(ProductId packId) async {
    assert(
      packId == ProductId.hintPack5 || packId == ProductId.hintPack20,
      'packId must be hintPack5 or hintPack20',
    );

    final purchaseService = ref.read(purchaseServiceProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await purchaseService.purchase(packId);
      return purchaseService.currentState;
    });
  }

  /// Purchases premium themes.
  Future<void> purchasePremiumThemes() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await purchaseService.purchase(ProductId.premiumThemes);
      return purchaseService.currentState;
    });
  }

  /// Shows a rewarded ad and grants a free hint on completion.
  ///
  /// Returns the ad result. If [AdResult.completed], one hint has
  /// been added to the user's balance.
  Future<AdResult> watchAdForHint() async {
    if (!AdPlacement.canShowRewardedAd(_lastRewardedAdTimestamp)) {
      return AdResult.notReady;
    }

    final adService = ref.read(adServiceProvider);
    final result = await adService.showRewarded();

    if (result == AdResult.completed) {
      _lastRewardedAdTimestamp = DateTime.now();
      final purchaseService = ref.read(purchaseServiceProvider);
      await purchaseService.purchase(ProductId.hintPack5);

      // Refresh state after granting hint
      state = AsyncValue.data(purchaseService.currentState);
    }

    return result;
  }

  /// Whether ads should be displayed to the current user.
  ///
  /// Returns false if the user has purchased "Remove Ads".
  bool get shouldShowAds {
    final currentState = state.valueOrNull;
    if (currentState == null) return true;
    return !currentState.adsRemoved;
  }

  /// Shows an interstitial ad if the placement conditions are met.
  ///
  /// Call this after each level completion. Increments the internal
  /// counter and shows an interstitial every N levels (per [AdPlacement]).
  /// Does nothing if the user has purchased "Remove Ads".
  Future<void> showInterstitialIfNeeded() async {
    if (!shouldShowAds) return;

    _levelsCompletedSinceLastAd++;

    if (!AdPlacement.shouldShowInterstitial(_levelsCompletedSinceLastAd)) {
      return;
    }

    final adService = ref.read(adServiceProvider);
    final isReady = await adService.isAdReady(AdType.interstitial);
    if (!isReady) return;

    final result = await adService.showInterstitial();
    if (result == AdResult.shown || result == AdResult.dismissed) {
      _levelsCompletedSinceLastAd = 0;
    }

    if (kDebugMode) {
      debugPrint('Interstitial ad result: $result');
    }
  }

  /// Restores previous purchases from the store.
  Future<void> restorePurchases() async {
    final purchaseService = ref.read(purchaseServiceProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await purchaseService.restorePurchases();
      return purchaseService.currentState;
    });
  }
}

/// Provider for monetization state management.
final monetizationProvider =
    AsyncNotifierProvider<MonetizationNotifier, PurchaseState>(
  MonetizationNotifier.new,
);
