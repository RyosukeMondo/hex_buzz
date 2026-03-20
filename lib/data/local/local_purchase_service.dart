import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/purchase.dart';
import '../../domain/services/purchase_service.dart';

/// Mock implementation of [PurchaseService] using SharedPreferences.
///
/// Stores all purchase state locally for development and testing.
/// All purchases succeed immediately. In production, this would be
/// replaced with a real IAP implementation (StoreKit / Google Play Billing).
class LocalPurchaseService implements PurchaseService {
  static const String _storageKey = 'purchase_state';

  final SharedPreferences _prefs;
  final StreamController<PurchaseState> _stateController =
      StreamController<PurchaseState>.broadcast();

  PurchaseState _currentState = const PurchaseState.empty();

  LocalPurchaseService(this._prefs);

  @override
  Future<void> initialize() async {
    _currentState = _loadState();
    _stateController.add(_currentState);

    if (kDebugMode) {
      debugPrint('LocalPurchaseService initialized: $_currentState');
    }
  }

  @override
  Future<List<Product>> getProducts() async {
    return _availableProducts;
  }

  @override
  Future<bool> purchase(ProductId productId) async {
    final newState = _applyPurchase(productId, _currentState);
    await _saveState(newState);
    _currentState = newState;
    _stateController.add(_currentState);

    if (kDebugMode) {
      debugPrint('Purchase completed: ${productId.name} -> $_currentState');
    }
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    // In a real implementation, this would query the store.
    // For the mock, we reload from SharedPreferences.
    _currentState = _loadState();
    _stateController.add(_currentState);

    if (kDebugMode) {
      debugPrint('Purchases restored: $_currentState');
    }
  }

  @override
  PurchaseState get currentState => _currentState;

  @override
  Stream<PurchaseState> get stateChanges => _stateController.stream;

  /// Adds a single hint (e.g., from watching a rewarded ad).
  Future<void> addRewardedHint() async {
    final newState = _currentState.copyWith(
      extraHints: _currentState.extraHints + 1,
    );
    await _saveState(newState);
    _currentState = newState;
    _stateController.add(_currentState);
  }

  /// Consumes one hint from the user's balance.
  ///
  /// Returns true if a hint was available and consumed.
  Future<bool> consumeHint() async {
    if (_currentState.extraHints <= 0) return false;

    final newState = _currentState.copyWith(
      extraHints: _currentState.extraHints - 1,
    );
    await _saveState(newState);
    _currentState = newState;
    _stateController.add(_currentState);
    return true;
  }

  /// Applies a purchase to the current state, returning the updated state.
  PurchaseState _applyPurchase(ProductId productId, PurchaseState state) {
    final updatedHistory = [...state.purchaseHistory, productId];

    switch (productId) {
      case ProductId.removeAds:
        return state.copyWith(
          adsRemoved: true,
          purchaseHistory: updatedHistory,
        );
      case ProductId.hintPack5:
        return state.copyWith(
          extraHints: state.extraHints + 5,
          purchaseHistory: updatedHistory,
        );
      case ProductId.hintPack20:
        return state.copyWith(
          extraHints: state.extraHints + 20,
          purchaseHistory: updatedHistory,
        );
      case ProductId.premiumThemes:
        return state.copyWith(
          premiumThemes: true,
          purchaseHistory: updatedHistory,
        );
    }
  }

  PurchaseState _loadState() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return const PurchaseState.empty();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PurchaseState.fromJson(json);
    } on FormatException {
      return const PurchaseState.empty();
    } on TypeError {
      return const PurchaseState.empty();
    }
  }

  Future<void> _saveState(PurchaseState state) async {
    final jsonString = jsonEncode(state.toJson());
    await _prefs.setString(_storageKey, jsonString);
  }

  /// Releases the stream controller resources.
  void dispose() {
    _stateController.close();
  }
}

/// The catalog of products available for purchase.
const List<Product> _availableProducts = [
  Product(
    id: ProductId.removeAds,
    name: 'Remove Ads',
    description: 'Permanently remove all advertisements from HexBuzz.',
    price: '\$2.99',
    isConsumable: false,
  ),
  Product(
    id: ProductId.hintPack5,
    name: '5 Hints',
    description: 'Get 5 extra hints to help solve tricky puzzles.',
    price: '\$0.99',
    isConsumable: true,
  ),
  Product(
    id: ProductId.hintPack20,
    name: '20 Hints',
    description: 'Stock up on 20 hints for the toughest challenges.',
    price: '\$2.99',
    isConsumable: true,
  ),
  Product(
    id: ProductId.premiumThemes,
    name: 'Premium Themes',
    description: 'Unlock all premium visual themes for the game board.',
    price: '\$1.99',
    isConsumable: false,
  ),
];
