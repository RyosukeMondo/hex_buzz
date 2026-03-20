import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/models/purchase.dart';

void main() {
  group('Product', () {
    const product = Product(
      id: ProductId.removeAds,
      name: 'Remove Ads',
      description: 'Remove all advertisements.',
      price: '\$2.99',
      isConsumable: false,
    );

    group('toJson', () {
      test('serializes all fields correctly', () {
        final json = product.toJson();
        expect(json['id'], 'removeAds');
        expect(json['name'], 'Remove Ads');
        expect(json['description'], 'Remove all advertisements.');
        expect(json['price'], '\$2.99');
        expect(json['isConsumable'], false);
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'id': 'removeAds',
          'name': 'Remove Ads',
          'description': 'Remove all advertisements.',
          'price': '\$2.99',
          'isConsumable': false,
        };

        final result = Product.fromJson(json);
        expect(result, product);
      });
    });

    group('roundtrip serialization', () {
      test('toJson/fromJson preserves equality', () {
        final json = product.toJson();
        final restored = Product.fromJson(json);
        expect(restored, product);
      });

      test('consumable product roundtrips correctly', () {
        const consumable = Product(
          id: ProductId.hintPack5,
          name: '5 Hints',
          description: 'Get 5 hints.',
          price: '\$0.99',
          isConsumable: true,
        );

        final restored = Product.fromJson(consumable.toJson());
        expect(restored, consumable);
        expect(restored.isConsumable, true);
      });
    });

    group('equality', () {
      test('equal products are equal', () {
        const other = Product(
          id: ProductId.removeAds,
          name: 'Remove Ads',
          description: 'Remove all advertisements.',
          price: '\$2.99',
          isConsumable: false,
        );
        expect(product, other);
        expect(product.hashCode, other.hashCode);
      });

      test('different id means not equal', () {
        const other = Product(
          id: ProductId.hintPack5,
          name: 'Remove Ads',
          description: 'Remove all advertisements.',
          price: '\$2.99',
          isConsumable: false,
        );
        expect(product, isNot(other));
      });
    });
  });

  group('PurchaseState', () {
    group('empty constructor', () {
      test('creates default empty state', () {
        const state = PurchaseState.empty();
        expect(state.adsRemoved, false);
        expect(state.extraHints, 0);
        expect(state.premiumThemes, false);
        expect(state.purchaseHistory, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with updated adsRemoved', () {
        const state = PurchaseState.empty();
        final updated = state.copyWith(adsRemoved: true);
        expect(updated.adsRemoved, true);
        expect(updated.extraHints, 0);
        expect(updated.premiumThemes, false);
      });

      test('creates copy with updated extraHints', () {
        const state = PurchaseState.empty();
        final updated = state.copyWith(extraHints: 10);
        expect(updated.adsRemoved, false);
        expect(updated.extraHints, 10);
      });

      test('creates copy with updated premiumThemes', () {
        const state = PurchaseState.empty();
        final updated = state.copyWith(premiumThemes: true);
        expect(updated.premiumThemes, true);
      });

      test('creates copy with updated purchaseHistory', () {
        const state = PurchaseState.empty();
        final updated = state.copyWith(
          purchaseHistory: [ProductId.removeAds],
        );
        expect(updated.purchaseHistory, [ProductId.removeAds]);
      });

      test('preserves unchanged fields', () {
        const state = PurchaseState(
          adsRemoved: true,
          extraHints: 5,
          premiumThemes: true,
          purchaseHistory: [ProductId.removeAds, ProductId.hintPack5],
        );
        final updated = state.copyWith(extraHints: 10);
        expect(updated.adsRemoved, true);
        expect(updated.extraHints, 10);
        expect(updated.premiumThemes, true);
        expect(updated.purchaseHistory.length, 2);
      });
    });

    group('toJson / fromJson', () {
      test('empty state roundtrips', () {
        const state = PurchaseState.empty();
        final restored = PurchaseState.fromJson(state.toJson());
        expect(restored, state);
      });

      test('populated state roundtrips', () {
        const state = PurchaseState(
          adsRemoved: true,
          extraHints: 15,
          premiumThemes: true,
          purchaseHistory: [
            ProductId.removeAds,
            ProductId.hintPack5,
            ProductId.hintPack20,
            ProductId.premiumThemes,
          ],
        );
        final restored = PurchaseState.fromJson(state.toJson());
        expect(restored, state);
      });

      test('handles missing fields gracefully', () {
        final state = PurchaseState.fromJson(<String, dynamic>{});
        expect(state.adsRemoved, false);
        expect(state.extraHints, 0);
        expect(state.premiumThemes, false);
        expect(state.purchaseHistory, isEmpty);
      });

      test('serializes purchaseHistory as string names', () {
        const state = PurchaseState(
          purchaseHistory: [ProductId.removeAds, ProductId.hintPack5],
        );
        final json = state.toJson();
        final historyJson = json['purchaseHistory'] as List;
        expect(historyJson, ['removeAds', 'hintPack5']);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const state1 = PurchaseState(
          adsRemoved: true,
          extraHints: 5,
          purchaseHistory: [ProductId.removeAds],
        );
        const state2 = PurchaseState(
          adsRemoved: true,
          extraHints: 5,
          purchaseHistory: [ProductId.removeAds],
        );
        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('different adsRemoved means not equal', () {
        const state1 = PurchaseState(adsRemoved: true);
        const state2 = PurchaseState(adsRemoved: false);
        expect(state1, isNot(state2));
      });

      test('different extraHints means not equal', () {
        const state1 = PurchaseState(extraHints: 5);
        const state2 = PurchaseState(extraHints: 10);
        expect(state1, isNot(state2));
      });

      test('different purchaseHistory means not equal', () {
        const state1 = PurchaseState(
          purchaseHistory: [ProductId.removeAds],
        );
        const state2 = PurchaseState(
          purchaseHistory: [ProductId.hintPack5],
        );
        expect(state1, isNot(state2));
      });

      test('different history length means not equal', () {
        const state1 = PurchaseState(
          purchaseHistory: [ProductId.removeAds],
        );
        const state2 = PurchaseState(
          purchaseHistory: [ProductId.removeAds, ProductId.hintPack5],
        );
        expect(state1, isNot(state2));
      });
    });

    group('toString', () {
      test('includes key fields', () {
        const state = PurchaseState(
          adsRemoved: true,
          extraHints: 5,
          premiumThemes: false,
          purchaseHistory: [ProductId.removeAds],
        );
        final str = state.toString();
        expect(str, contains('adsRemoved: true'));
        expect(str, contains('extraHints: 5'));
        expect(str, contains('premiumThemes: false'));
        expect(str, contains('purchases: 1'));
      });
    });
  });

  group('ProductId', () {
    test('has expected values', () {
      expect(ProductId.values.length, 4);
      expect(ProductId.values, contains(ProductId.removeAds));
      expect(ProductId.values, contains(ProductId.hintPack5));
      expect(ProductId.values, contains(ProductId.hintPack20));
      expect(ProductId.values, contains(ProductId.premiumThemes));
    });
  });
}
