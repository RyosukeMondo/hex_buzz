import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/local/local_purchase_service.dart';
import 'package:hex_buzz/domain/models/purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LocalPurchaseService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = LocalPurchaseService(prefs);
    await service.initialize();
  });

  tearDown(() {
    service.dispose();
  });

  group('LocalPurchaseService', () {
    group('initialize', () {
      test('starts with empty state', () {
        expect(service.currentState, const PurchaseState.empty());
      });

      test('loads existing state from SharedPreferences', () async {
        // Pre-populate SharedPreferences
        SharedPreferences.setMockInitialValues({
          'purchase_state':
              '{"adsRemoved":true,"extraHints":5,"premiumThemes":false,"purchaseHistory":["removeAds"]}',
        });
        final loadedPrefs = await SharedPreferences.getInstance();
        final loadedService = LocalPurchaseService(loadedPrefs);
        await loadedService.initialize();

        expect(loadedService.currentState.adsRemoved, true);
        expect(loadedService.currentState.extraHints, 5);
        expect(
          loadedService.currentState.purchaseHistory,
          [ProductId.removeAds],
        );

        loadedService.dispose();
      });
    });

    group('getProducts', () {
      test('returns list of available products', () async {
        final products = await service.getProducts();
        expect(products.length, 4);

        final ids = products.map((p) => p.id).toList();
        expect(ids, contains(ProductId.removeAds));
        expect(ids, contains(ProductId.hintPack5));
        expect(ids, contains(ProductId.hintPack20));
        expect(ids, contains(ProductId.premiumThemes));
      });

      test('products have prices and descriptions', () async {
        final products = await service.getProducts();
        for (final product in products) {
          expect(product.name, isNotEmpty);
          expect(product.description, isNotEmpty);
          expect(product.price, isNotEmpty);
        }
      });
    });

    group('purchase', () {
      test('removeAds sets adsRemoved to true', () async {
        final result = await service.purchase(ProductId.removeAds);
        expect(result, true);
        expect(service.currentState.adsRemoved, true);
      });

      test('hintPack5 adds 5 hints', () async {
        await service.purchase(ProductId.hintPack5);
        expect(service.currentState.extraHints, 5);
      });

      test('hintPack20 adds 20 hints', () async {
        await service.purchase(ProductId.hintPack20);
        expect(service.currentState.extraHints, 20);
      });

      test('premiumThemes sets premiumThemes to true', () async {
        await service.purchase(ProductId.premiumThemes);
        expect(service.currentState.premiumThemes, true);
      });

      test('multiple hint purchases are cumulative', () async {
        await service.purchase(ProductId.hintPack5);
        await service.purchase(ProductId.hintPack5);
        await service.purchase(ProductId.hintPack20);
        expect(service.currentState.extraHints, 30);
      });

      test('adds to purchase history', () async {
        await service.purchase(ProductId.removeAds);
        await service.purchase(ProductId.hintPack5);

        expect(service.currentState.purchaseHistory, [
          ProductId.removeAds,
          ProductId.hintPack5,
        ]);
      });

      test('persists to SharedPreferences', () async {
        await service.purchase(ProductId.removeAds);

        // Create a new service from the same prefs
        final newService = LocalPurchaseService(prefs);
        await newService.initialize();

        expect(newService.currentState.adsRemoved, true);
        newService.dispose();
      });

      test('emits state change via stream', () async {
        final states = <PurchaseState>[];
        service.stateChanges.listen(states.add);

        await service.purchase(ProductId.removeAds);

        // Allow stream events to propagate
        await Future.delayed(Duration.zero);

        expect(states, isNotEmpty);
        expect(states.last.adsRemoved, true);
      });
    });

    group('restorePurchases', () {
      test('reloads state from SharedPreferences', () async {
        await service.purchase(ProductId.removeAds);

        // Verify state is set
        expect(service.currentState.adsRemoved, true);

        // Restore should reload from storage
        await service.restorePurchases();
        expect(service.currentState.adsRemoved, true);
      });
    });

    group('addRewardedHint', () {
      test('adds one hint', () async {
        await service.addRewardedHint();
        expect(service.currentState.extraHints, 1);
      });

      test('multiple calls add multiple hints', () async {
        await service.addRewardedHint();
        await service.addRewardedHint();
        await service.addRewardedHint();
        expect(service.currentState.extraHints, 3);
      });
    });

    group('consumeHint', () {
      test('returns false when no hints available', () async {
        final result = await service.consumeHint();
        expect(result, false);
        expect(service.currentState.extraHints, 0);
      });

      test('returns true and decrements when hints available', () async {
        await service.purchase(ProductId.hintPack5);
        expect(service.currentState.extraHints, 5);

        final result = await service.consumeHint();
        expect(result, true);
        expect(service.currentState.extraHints, 4);
      });

      test('consumes down to zero', () async {
        await service.addRewardedHint();
        await service.addRewardedHint();

        await service.consumeHint();
        await service.consumeHint();
        final result = await service.consumeHint();

        expect(result, false);
        expect(service.currentState.extraHints, 0);
      });
    });

    group('corrupted data handling', () {
      test('returns empty state for corrupted JSON', () async {
        SharedPreferences.setMockInitialValues({
          'purchase_state': 'not valid json',
        });
        final corruptPrefs = await SharedPreferences.getInstance();
        final corruptService = LocalPurchaseService(corruptPrefs);
        await corruptService.initialize();

        expect(corruptService.currentState, const PurchaseState.empty());
        corruptService.dispose();
      });

      test('returns empty state for wrong JSON type', () async {
        SharedPreferences.setMockInitialValues({
          'purchase_state': '"just a string"',
        });
        final corruptPrefs = await SharedPreferences.getInstance();
        final corruptService = LocalPurchaseService(corruptPrefs);
        await corruptService.initialize();

        expect(corruptService.currentState, const PurchaseState.empty());
        corruptService.dispose();
      });
    });
  });
}
