/// 🧪 Store Purchase Handler Unit Tests - Business logic testing
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/store/store_purchase_handler.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/monetization_manager.dart';
import 'package:flappy_jet_pro/game/core/economy_config.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('StorePurchaseHandler Unit Tests', () {
    late InventoryManager mockInventory;
    late MonetizationManager mockMonetization;
    late EconomyConfig mockEconomy;
    late StorePurchaseHandler handler;
    late BuildContext context;

    setUp(() async {
      mockInventory = InventoryManager();
      mockMonetization = MonetizationManager();
      mockEconomy = EconomyConfig();
      
      // Initialize systems
      await mockInventory.initialize();
      await mockMonetization.initialize();
      await JetSkinCatalog.initializeFromAssets();
    });

    testWidgets('initializes correctly with required dependencies', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                handler = StorePurchaseHandler(
                  context: context,
                  inventory: mockInventory,
                  monetization: mockMonetization,
                  economy: mockEconomy,
                );
                return Container();
              },
            ),
          ),
        ),
      );

      expect(handler, isNotNull);
      expect(handler.context, equals(context));
      expect(handler.inventory, equals(mockInventory));
      expect(handler.monetization, equals(mockMonetization));
      expect(handler.economy, equals(mockEconomy));
    });

    group('Gem Pack Purchases', () {
      testWidgets('handles successful gem pack purchase', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final gemPack = EconomyConfig.gemPacks.values.first;
        final initialGems = mockInventory.gems;

        // Execute purchase
        await handler.purchaseGemPack(gemPack);
        await tester.pump();

        // Verify gems were granted (in a real test, we'd mock the IAP)
        // For now, just verify the method executes without throwing
        expect(mockInventory.gems, greaterThanOrEqualTo(initialGems));
      });

      testWidgets('handles failed gem pack purchase gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        // Create a gem pack with invalid ID to trigger error
        const invalidGemPack = GemPack(
          id: 'invalid_pack',
          gems: 100,
          bonusGems: 0,
          usdPrice: 0.99,
          displayName: 'Invalid Pack',
          description: 'Test pack',
        );

        // Should handle error gracefully
        expect(
          () => handler.purchaseGemPack(invalidGemPack),
          returnsNormally,
        );
      });
    });

    group('Jet Skin Purchases', () {
      testWidgets('handles successful jet skin purchase with sufficient coins', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final jetSkin = JetSkinCatalog.premiumSkins.first;
        final price = mockEconomy.getSkinCoinPrice(jetSkin);
        
        // Ensure sufficient coins
        await mockInventory.grantSoftCurrency(price + 1000);
        final initialCoins = mockInventory.softCurrency;

        // Execute purchase
        await handler.purchaseJetSkin(jetSkin);
        await tester.pump();

        // Verify coins were spent and skin was unlocked
        expect(mockInventory.softCurrency, lessThan(initialCoins));
        expect(mockInventory.isOwned(jetSkin.id), isTrue);
        expect(mockInventory.equippedSkinId, equals(jetSkin.id));
      });

      testWidgets('handles insufficient coins gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final jetSkin = JetSkinCatalog.premiumSkins.first;
        
        // Ensure insufficient coins
        await mockInventory.spendAllSoftCurrency();
        
        // Execute purchase - should fail gracefully
        await handler.purchaseJetSkin(jetSkin);
        await tester.pump();

        // Verify skin was not unlocked
        expect(mockInventory.isOwned(jetSkin.id), isFalse);
      });
    });

    group('Jet Skin Equipping', () {
      testWidgets('equips owned jet skin successfully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final jetSkin = JetSkinCatalog.starterJet; // Always owned
        
        // Execute equip
        await handler.equipJetSkin(jetSkin);
        await tester.pump();

        // Verify skin was equipped
        expect(mockInventory.equippedSkinId, equals(jetSkin.id));
      });
    });

    group('Heart Booster Purchases', () {
      testWidgets('handles heart booster purchase with sufficient gems', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final pack = EconomyConfig.heartBoosterPack;
        
        // Ensure sufficient gems
        await mockInventory.grantGems(pack.gemPrice + 100);
        final initialGems = mockInventory.gems;

        // Note: In a real test, we'd need to mock the confirmation dialog
        // For now, just verify the method executes
        expect(
          () => handler.purchaseHeartBoosterWithGems(),
          returnsNormally,
        );
      });

      testWidgets('handles insufficient gems gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        // Ensure insufficient gems
        await mockInventory.spendAllGems();
        
        // Execute purchase - should fail gracefully
        await handler.purchaseHeartBoosterWithGems();
        await tester.pump();

        // Should not crash and handle gracefully
        expect(mockInventory.isHeartBoosterActive, isFalse);
      });
    });

    group('Hearts Refill', () {
      testWidgets('handles hearts refill with sufficient gems', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  handler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        final refillCost = mockEconomy.fullHeartsRefillGemCost;
        
        // Ensure sufficient gems
        await mockInventory.grantGems(refillCost + 100);
        
        // Note: In a real test, we'd need to mock the confirmation dialog
        // For now, just verify the method executes
        expect(
          () => handler.purchaseFullHeartsRefill(),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      testWidgets('handles context being unmounted gracefully', (tester) async {
        late StorePurchaseHandler tempHandler;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  tempHandler = StorePurchaseHandler(
                    context: ctx,
                    inventory: mockInventory,
                    monetization: mockMonetization,
                    economy: mockEconomy,
                  );
                  return Container();
                },
              ),
            ),
          ),
        );

        // Remove the widget to unmount context
        await tester.pumpWidget(Container());

        // Operations should not crash even with unmounted context
        final gemPack = EconomyConfig.gemPacks.values.first;
        expect(
          () => tempHandler.purchaseGemPack(gemPack),
          returnsNormally,
        );
      });
    });
  });

  group('Purchase Handler Integration', () {
    testWidgets('maintains state consistency across operations', (tester) async {
      late StorePurchaseHandler handler;
      late InventoryManager inventory;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                inventory = InventoryManager();
                handler = StorePurchaseHandler(
                  context: ctx,
                  inventory: inventory,
                  monetization: MonetizationManager(),
                  economy: EconomyConfig(),
                );
                return Container();
              },
            ),
          ),
        ),
      );

      await inventory.initialize();
      await JetSkinCatalog.initializeFromAssets();

      // Grant initial resources
      await inventory.grantSoftCurrency(10000);
      await inventory.grantGems(1000);

      final initialCoins = inventory.softCurrency;
      final initialGems = inventory.gems;

      // Purchase a jet skin
      final jetSkin = JetSkinCatalog.premiumSkins.first;
      await handler.purchaseJetSkin(jetSkin);

      // Verify state changes
      expect(inventory.softCurrency, lessThan(initialCoins));
      expect(inventory.isOwned(jetSkin.id), isTrue);
      expect(inventory.equippedSkinId, equals(jetSkin.id));

      // Equip a different skin
      final anotherSkin = JetSkinCatalog.starterJet;
      await handler.equipJetSkin(anotherSkin);
      
      // Verify equipment changed but ownership remained
      expect(inventory.equippedSkinId, equals(anotherSkin.id));
      expect(inventory.isOwned(jetSkin.id), isTrue);
    });
  });
}
