/// Identifiers for all purchasable products in the app.
enum ProductId {
  /// One-time purchase to permanently remove all advertisements.
  removeAds,

  /// Consumable purchase granting 5 extra hints.
  hintPack5,

  /// Consumable purchase granting 20 extra hints.
  hintPack20,

  /// One-time purchase to unlock all premium visual themes.
  premiumThemes,
}

/// A purchasable product with display information.
class Product {
  final ProductId id;
  final String name;
  final String description;
  final String price;
  final bool isConsumable;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isConsumable,
  });

  /// Serializes the product to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'name': name,
      'description': description,
      'price': price,
      'isConsumable': isConsumable,
    };
  }

  /// Creates a Product from JSON data.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: ProductId.values.firstWhere((e) => e.name == json['id'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      isConsumable: json['isConsumable'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.isConsumable == isConsumable;
  }

  @override
  int get hashCode => Object.hash(id, name, description, price, isConsumable);

  @override
  String toString() {
    return 'Product(id: ${id.name}, name: $name, price: $price)';
  }
}

/// The current state of all purchases for the active user.
///
/// Tracks non-consumable entitlements (ads removed, premium themes)
/// and consumable balances (extra hints), plus a history of all
/// purchases for audit/restore purposes.
class PurchaseState {
  final bool adsRemoved;
  final int extraHints;
  final bool premiumThemes;
  final List<ProductId> purchaseHistory;

  const PurchaseState({
    this.adsRemoved = false,
    this.extraHints = 0,
    this.premiumThemes = false,
    this.purchaseHistory = const [],
  });

  /// Creates an empty purchase state with no purchases.
  const PurchaseState.empty()
      : adsRemoved = false,
        extraHints = 0,
        premiumThemes = false,
        purchaseHistory = const [];

  /// Creates a copy with optional updated fields.
  PurchaseState copyWith({
    bool? adsRemoved,
    int? extraHints,
    bool? premiumThemes,
    List<ProductId>? purchaseHistory,
  }) {
    return PurchaseState(
      adsRemoved: adsRemoved ?? this.adsRemoved,
      extraHints: extraHints ?? this.extraHints,
      premiumThemes: premiumThemes ?? this.premiumThemes,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    );
  }

  /// Serializes the purchase state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'adsRemoved': adsRemoved,
      'extraHints': extraHints,
      'premiumThemes': premiumThemes,
      'purchaseHistory': purchaseHistory.map((e) => e.name).toList(),
    };
  }

  /// Creates a PurchaseState from JSON data.
  factory PurchaseState.fromJson(Map<String, dynamic> json) {
    final historyJson = json['purchaseHistory'] as List<dynamic>? ?? [];
    return PurchaseState(
      adsRemoved: json['adsRemoved'] as bool? ?? false,
      extraHints: json['extraHints'] as int? ?? 0,
      premiumThemes: json['premiumThemes'] as bool? ?? false,
      purchaseHistory: historyJson
          .map(
            (e) => ProductId.values.firstWhere(
              (p) => p.name == e as String,
              orElse: () => ProductId.removeAds,
            ),
          )
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PurchaseState) return false;
    if (other.adsRemoved != adsRemoved) return false;
    if (other.extraHints != extraHints) return false;
    if (other.premiumThemes != premiumThemes) return false;
    if (other.purchaseHistory.length != purchaseHistory.length) return false;
    for (int i = 0; i < purchaseHistory.length; i++) {
      if (other.purchaseHistory[i] != purchaseHistory[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        adsRemoved,
        extraHints,
        premiumThemes,
        Object.hashAll(purchaseHistory),
      );

  @override
  String toString() {
    return 'PurchaseState(adsRemoved: $adsRemoved, extraHints: $extraHints, '
        'premiumThemes: $premiumThemes, purchases: ${purchaseHistory.length})';
  }
}
