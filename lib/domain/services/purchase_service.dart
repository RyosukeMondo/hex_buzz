import '../models/purchase.dart';

/// Abstract interface for in-app purchase management.
///
/// Provides methods to list products, make purchases, and restore
/// previous purchases. Implementations can use different IAP backends
/// (StoreKit, Google Play Billing, mock) while consumers depend only
/// on this interface for dependency injection.
abstract class PurchaseService {
  /// Initializes the purchase service and connects to the store.
  Future<void> initialize();

  /// Returns the list of available products for purchase.
  Future<List<Product>> getProducts();

  /// Attempts to purchase the product identified by [productId].
  ///
  /// Returns true if the purchase completed successfully,
  /// false if the purchase was cancelled or failed.
  Future<bool> purchase(ProductId productId);

  /// Restores previously completed non-consumable purchases.
  ///
  /// Re-applies purchases like "Remove Ads" or "Premium Themes"
  /// that were made on a different device or after a reinstall.
  Future<void> restorePurchases();

  /// The current purchase state reflecting all completed purchases.
  PurchaseState get currentState;

  /// A stream that emits updated [PurchaseState] whenever a purchase
  /// completes, is consumed, or is restored.
  Stream<PurchaseState> get stateChanges;
}
