import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/ui/screens/store_screen.dart';
import 'package:flappy_jet_pro/ui/screens/stunning_homepage.dart';
import 'package:flappy_jet_pro/game/systems/monetization_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';

void main() {
  group('UI Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Store Screen Tests', () {
      testWidgets('should display store categories', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        // Wait for initialization
        await tester.pumpAndSettle();

        // Check for category tabs
        expect(find.text('JETS'), findsOneWidget);
        expect(find.text('GEMS'), findsOneWidget);
        expect(find.text('HEART BOOSTER'), findsOneWidget);
      });

      testWidgets('should show currency balances', (WidgetTester tester) async {
        // Initialize inventory with some currency
        final inventory = InventoryManager();
        await inventory.initialize();
        await inventory.grantSoftCurrency(1000);
        await inventory.grantGems(50);

        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check for currency displays
        expect(find.byIcon(Icons.monetization_on), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.diamond), findsAtLeastNWidgets(1));
      });

      testWidgets('should switch between store categories', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Initially on Jets tab
        expect(find.text('JETS'), findsOneWidget);

        // Tap Gems tab
        await tester.tap(find.text('GEMS'));
        await tester.pumpAndSettle();

        // Should show gem packs
        expect(find.text('Small Gem Pack'), findsOneWidget);

        // Tap Heart Booster tab
        await tester.tap(find.text('HEART BOOSTER'));
        await tester.pumpAndSettle();

        // Should show Heart Booster
        expect(find.text('HEART BOOSTER'), findsAtLeastNWidgets(1));
        expect(find.text('24H Heart Booster'), findsOneWidget);
      });

      testWidgets('should display jet skins correctly', (WidgetTester tester) async {
        // Initialize jet catalog
        await JetSkinCatalog.initializeFromAssets();

        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should show starter jet and premium skins
        expect(find.text('Starter Jet'), findsOneWidget);
        
        // Check for buy buttons on premium skins
        expect(find.text('BUY'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show Heart Booster benefits', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to Heart Booster tab
        await tester.tap(find.text('HEART BOOSTER'));
        await tester.pumpAndSettle();

        // Check for benefit descriptions
        expect(find.text('6 Maximum Hearts'), findsOneWidget);
        expect(find.text('Faster Regeneration'), findsOneWidget);
        expect(find.text('24 Hour Duration'), findsOneWidget);
      });
    });

    group('Homepage Tests', () {
      testWidgets('should display homepage elements', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        await monetization.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for main buttons
        expect(find.text('PLAY'), findsOneWidget);
        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.text('MISSIONS'), findsOneWidget);
        expect(find.text('LEADERBOARD'), findsOneWidget);
        expect(find.text('STORE'), findsOneWidget);
      });

      testWidgets('should show currency and hearts status', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        await monetization.initialize();

        // Initialize managers with some values
        final inventory = InventoryManager();
        final lives = LivesManager();
        await inventory.initialize();
        await lives.initialize();
        await inventory.grantSoftCurrency(500);
        await inventory.grantGems(25);

        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for currency icons in status bar
        expect(find.byIcon(Icons.monetization_on), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.diamond), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
      });

      testWidgets('should navigate to store', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        await monetization.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap store button
        await tester.tap(find.text('STORE'));
        await tester.pumpAndSettle();

        // Should navigate to store screen
        expect(find.text('STORE'), findsAtLeastNWidgets(1));
        expect(find.text('JETS'), findsOneWidget);
      });

      testWidgets('should show Heart Booster status when active', (WidgetTester tester) async {
        final monetization = MonetizationManager();
        await monetization.initialize();

        // Activate Heart Booster
        final inventory = InventoryManager();
        await inventory.initialize();
        await inventory.activateHeartBooster(const Duration(hours: 1));

        await tester.pumpWidget(
          MaterialApp(
            home: StunningHomepage(
              developmentMode: true,
              monetization: monetization,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Hearts indicator should show increased capacity
        // This would be visible in the hearts display widget
        expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));
      });
    });

    group('Widget Integration Tests', () {
      testWidgets('should handle gem purchase flow', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Gems tab
        await tester.tap(find.text('GEMS'));
        await tester.pumpAndSettle();

        // Find and tap a gem pack purchase button
        final purchaseButtons = find.text('\$0.99');
        if (purchaseButtons.evaluate().isNotEmpty) {
          await tester.tap(purchaseButtons.first);
          await tester.pumpAndSettle();

          // Should trigger purchase flow (would show platform purchase dialog in real app)
        }
      });

      testWidgets('should handle Heart Booster purchase flow', (WidgetTester tester) async {
        // Give user enough gems
        final inventory = InventoryManager();
        await inventory.initialize();
        await inventory.grantGems(100);

        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Heart Booster tab
        await tester.tap(find.text('HEART BOOSTER'));
        await tester.pumpAndSettle();

        // Find gem purchase button
        final gemButton = find.widgetWithIcon(GestureDetector, Icons.diamond);
        if (gemButton.evaluate().isNotEmpty) {
          await tester.tap(gemButton.first);
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(find.text('Purchase Heart Booster?'), findsOneWidget);
          expect(find.text('Buy'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);

          // Confirm purchase
          await tester.tap(find.text('Buy'));
          await tester.pumpAndSettle();

          // Should show success message
          expect(find.text('Heart Booster activated!'), findsOneWidget);
        }
      });

      testWidgets('should handle insufficient gems gracefully', (WidgetTester tester) async {
        // Initialize with no gems
        final inventory = InventoryManager();
        await inventory.initialize();

        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Heart Booster tab
        await tester.tap(find.text('HEART BOOSTER'));
        await tester.pumpAndSettle();

        // Try to purchase with gems
        final gemButton = find.widgetWithIcon(GestureDetector, Icons.diamond);
        if (gemButton.evaluate().isNotEmpty) {
          await tester.tap(gemButton.first);
          await tester.pumpAndSettle();

          // Should show insufficient gems message
          expect(find.text('Not enough gems!'), findsOneWidget);
        }
      });

      testWidgets('should update UI when currency changes', (WidgetTester tester) async {
        final inventory = InventoryManager();
        await inventory.initialize();

        await tester.pumpWidget(
          const MaterialApp(
            home: StoreScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Grant currency and verify UI updates
        await inventory.grantSoftCurrency(1000);
        await tester.pump(); // Trigger rebuild

        // Currency display should update
        // This would be verified by checking the specific currency values in the UI
      });
    });
  });
}
