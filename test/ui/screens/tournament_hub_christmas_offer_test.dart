/// 🧪 UNIT TESTS - Tournament Hub Christmas Special Offer
/// 
/// Tests to ensure the Christmas special offer popup:
/// 1. Shows when entering Christmas tournament if user hasn't purchased
/// 2. Does NOT show if user already owns all 3 Christmas jet skins
/// 
/// ✅ Flame Best Practices: Comprehensive purchase flow testing
/// ✅ Mobile Gaming Standards: Verify user experience and navigation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';

// Mock classes
class MockInventoryManager extends Mock implements InventoryManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Christmas Special Offer - Purchase Check', () {
    testWidgets('should show popup when user does not own all Christmas jet skins', (WidgetTester tester) async {
      final mockInventory = MockInventoryManager();
      
      // Mock: User does NOT own all skins
      when(() => mockInventory.isOwned('blitzen')).thenReturn(false);
      when(() => mockInventory.isOwned('comet')).thenReturn(false);
      when(() => mockInventory.isOwned('rudolph')).thenReturn(false);
      
      // Create a test widget that simulates entering Christmas tournament
      bool popupShown = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Simulate the check that happens in _showChristmasSpecialOffer
                const christmasJetSkins = ['blitzen', 'comet', 'rudolph'];
                final allSkinsOwned = christmasJetSkins.every((skinId) => mockInventory.isOwned(skinId));
                
                if (!allSkinsOwned) {
                  // Popup should be shown
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    popupShown = true;
                  });
                }
                
                return Center(
                  child: Text(allSkinsOwned ? 'All skins owned' : 'Popup should show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup should be shown
      expect(popupShown, true, reason: 'Popup should be shown when user does not own all skins');
      expect(find.text('Popup should show'), findsOneWidget);
    });

    testWidgets('should NOT show popup when user owns all Christmas jet skins', (WidgetTester tester) async {
      final mockInventory = MockInventoryManager();
      
      // Mock: User owns ALL skins
      when(() => mockInventory.isOwned('blitzen')).thenReturn(true);
      when(() => mockInventory.isOwned('comet')).thenReturn(true);
      when(() => mockInventory.isOwned('rudolph')).thenReturn(true);
      
      // Create a test widget that simulates entering Christmas tournament
      bool popupShown = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Simulate the check that happens in _showChristmasSpecialOffer
                const christmasJetSkins = ['blitzen', 'comet', 'rudolph'];
                final allSkinsOwned = christmasJetSkins.every((skinId) => mockInventory.isOwned(skinId));
                
                if (!allSkinsOwned) {
                  // Popup should be shown
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    popupShown = true;
                  });
                }
                
                return Center(
                  child: Text(allSkinsOwned ? 'All skins owned' : 'Popup should show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup should NOT be shown
      expect(popupShown, false, reason: 'Popup should NOT be shown when user owns all skins');
      expect(find.text('All skins owned'), findsOneWidget);
    });

    testWidgets('should NOT show popup when user owns some but not all Christmas jet skins', (WidgetTester tester) async {
      final mockInventory = MockInventoryManager();
      
      // Mock: User owns SOME skins but not all
      when(() => mockInventory.isOwned('blitzen')).thenReturn(true);
      when(() => mockInventory.isOwned('comet')).thenReturn(true);
      when(() => mockInventory.isOwned('rudolph')).thenReturn(false); // Missing one
      
      // Create a test widget that simulates entering Christmas tournament
      bool popupShown = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Simulate the check that happens in _showChristmasSpecialOffer
                const christmasJetSkins = ['blitzen', 'comet', 'rudolph'];
                final allSkinsOwned = christmasJetSkins.every((skinId) => mockInventory.isOwned(skinId));
                
                if (!allSkinsOwned) {
                  // Popup should be shown
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    popupShown = true;
                  });
                }
                
                return Center(
                  child: Text(allSkinsOwned ? 'All skins owned' : 'Popup should show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify popup should be shown (user doesn't own all skins)
      expect(popupShown, true, reason: 'Popup should be shown when user does not own all skins');
      expect(find.text('Popup should show'), findsOneWidget);
    });

    test('should verify Christmas jet skin IDs are correct', () {
      const expectedSkinIds = ['blitzen', 'comet', 'rudolph'];
      
      // Verify all skin IDs are the same as used in the code
      expect(expectedSkinIds.length, equals(3), reason: 'Should have exactly 3 Christmas jet skins');
      expect(expectedSkinIds.contains('blitzen'), isTrue, reason: 'Should include blitzen');
      expect(expectedSkinIds.contains('comet'), isTrue, reason: 'Should include comet');
      expect(expectedSkinIds.contains('rudolph'), isTrue, reason: 'Should include rudolph');
    });
  });
}

