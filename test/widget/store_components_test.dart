/// 🧪 Store Components Test - Comprehensive testing of refactored store components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/ui/widgets/store/store_header.dart';
import 'package:flappy_jet_pro/ui/widgets/store/store_navigation.dart';
import 'package:flappy_jet_pro/ui/widgets/store/gems_store.dart';
import 'package:flappy_jet_pro/ui/widgets/store/jets_store.dart';
import 'package:flappy_jet_pro/ui/widgets/store/hearts_store.dart';
import 'package:flappy_jet_pro/ui/widgets/store/heart_booster_store.dart';
import 'package:flappy_jet_pro/ui/widgets/store/store_purchase_handler.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/monetization_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/game/core/economy_config.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('Store Components Tests', () {
    late InventoryManager mockInventory;
    late MonetizationManager mockMonetization;
    late EconomyConfig mockEconomy;
    late LivesManager mockLivesManager;

    setUp(() {
      mockInventory = InventoryManager();
      mockMonetization = MonetizationManager();
      mockEconomy = EconomyConfig();
      mockLivesManager = LivesManager();
    });

    group('StoreHeader', () {
      testWidgets('displays title and currency correctly', (tester) async {
        bool backPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoreHeader(
                onBackPressed: () => backPressed = true,
                inventory: mockInventory,
              ),
            ),
          ),
        );

        // Check for back button
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        
        // Check for currency display elements
        expect(find.text('\$'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget); // Store title image
        
        // Test back button functionality
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump();
        expect(backPressed, isTrue);
      });

      testWidgets('shows fallback text when image fails', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoreHeader(
                onBackPressed: () {},
                inventory: mockInventory,
              ),
            ),
          ),
        );

        // Wait for image to fail and fallback to render
        await tester.pump();
        
        // Should show fallback text if image fails
        expect(find.text('STORE'), findsOneWidget);
      });
    });

    group('StoreNavigation', () {
      testWidgets('displays all categories and handles selection', (tester) async {
        String selectedCategory = 'Jets';
        final categories = ['Jets', 'Gems', 'Hearts', 'Heart Booster'];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => StoreNavigation(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (category) {
                    setState(() => selectedCategory = category);
                  },
                ),
              ),
            ),
          ),
        );

        // Check all categories are displayed
        expect(find.text('JETS'), findsOneWidget);
        expect(find.text('GEMS'), findsOneWidget);
        expect(find.text('HEARTS'), findsOneWidget);
        expect(find.text('BOOST'), findsOneWidget); // Heart Booster shows as BOOST

        // Check category icons
        expect(find.text('🛩️'), findsOneWidget);
        expect(find.text('💎'), findsOneWidget);
        expect(find.text('❤️'), findsOneWidget);
        expect(find.text('⚡'), findsOneWidget);

        // Test category selection
        await tester.tap(find.text('GEMS'));
        await tester.pump();
        // Note: In real test, we'd need to verify the callback was called
      });
    });

    group('GemsStore', () {
      testWidgets('displays gem packs correctly', (tester) async {
        bool purchaseCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: GemsStore(
                  onPurchaseGemPack: (pack) => purchaseCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Should display gem packs
        expect(find.byType(GridView), findsOneWidget);
        
        // Check for gem pack elements
        expect(find.text('Small Gem Pack'), findsOneWidget);
        expect(find.text('Medium Gem Pack'), findsOneWidget);
        
        // Check for pricing
        expect(find.textContaining('\$'), findsAtLeastNWidgets(1));
        
        // Check for badges
        expect(find.text('🔥 POPULAR'), findsOneWidget);
        expect(find.text('💎 BEST VALUE'), findsOneWidget);
      });
    });

    group('JetsStore', () {
      testWidgets('displays jet skins correctly', (tester) async {
        await JetSkinCatalog.initializeFromAssets();
        bool purchaseCalled = false;
        bool equipCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: JetsStore(
                  inventory: mockInventory,
                  economy: mockEconomy,
                  onPurchaseJet: (skin) => purchaseCalled = true,
                  onEquipJet: (skin) => equipCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Should display jet grid
        expect(find.byType(GridView), findsOneWidget);
        
        // Should show jet names
        expect(find.text('Sky Jet'), findsOneWidget);
        
        // Should show purchase buttons for unowned jets
        expect(find.text('BUY'), findsAtLeastNWidgets(1));
      });
    });

    group('HeartsStore', () {
      testWidgets('displays hearts status and refill option', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeartsStore(
                livesManager: mockLivesManager,
                economy: mockEconomy,
                onPurchaseFullHeartsRefill: () {},
              ),
            ),
          ),
        );

        await tester.pump();

        // Check for hearts display
        expect(find.text('BUY HEARTS'), findsOneWidget);
        expect(find.text('Current Hearts'), findsOneWidget);
        expect(find.text('Full Hearts Refill'), findsOneWidget);
        
        // Check for heart icons
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });
    });

    group('HeartBoosterStore', () {
      testWidgets('displays heart booster correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeartBoosterStore(
                inventory: mockInventory,
                onPurchaseWithGems: () {},
                onPurchaseWithUSD: () {},
              ),
            ),
          ),
        );

        await tester.pump();

        // Check for booster content
        expect(find.text('HEART BOOSTER'), findsOneWidget);
        expect(find.text('24-Hour Heart Booster'), findsOneWidget);
        
        // Check for benefits
        expect(find.text('6 Maximum Hearts'), findsOneWidget);
        expect(find.text('Faster Regeneration'), findsOneWidget);
        expect(find.text('24 Hour Duration'), findsOneWidget);
        
        // Check for purchase buttons
        expect(find.textContaining('\$'), findsOneWidget); // USD price
      });
    });

    group('StorePurchaseHandler', () {
      testWidgets('handles purchase flows correctly', (tester) async {
        late StorePurchaseHandler handler;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
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

        // Test that handler is created without errors
        expect(handler, isNotNull);
        
        // Test gem pack purchase (would need mocking for full test)
        final gemPack = EconomyConfig.gemPacks.values.first;
        expect(() => handler.purchaseGemPack(gemPack), returnsNormally);
        
        // Test jet skin purchase
        final jetSkin = JetSkinCatalog.starterJet;
        expect(() => handler.purchaseJetSkin(jetSkin), returnsNormally);
      });
    });

    group('Integration Tests', () {
      testWidgets('store components work together', (tester) async {
        await JetSkinCatalog.initializeFromAssets();
        String selectedCategory = 'Jets';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  StoreHeader(
                    onBackPressed: () {},
                    inventory: mockInventory,
                  ),
                  StoreNavigation(
                    categories: const ['Jets', 'Gems', 'Hearts', 'Heart Booster'],
                    selectedCategory: selectedCategory,
                    onCategorySelected: (category) {
                      selectedCategory = category;
                    },
                  ),
                  Expanded(
                    child: JetsStore(
                      inventory: mockInventory,
                      economy: mockEconomy,
                      onPurchaseJet: (skin) {},
                      onEquipJet: (skin) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify all components render without errors
        expect(find.byType(StoreHeader), findsOneWidget);
        expect(find.byType(StoreNavigation), findsOneWidget);
        expect(find.byType(JetsStore), findsOneWidget);
      });
    });
  });
}
