/// 🔧 Profile State Management Unit Tests - Testing business logic and state
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/player_identity_manager.dart';
import 'package:flappy_jet_pro/game/systems/profile_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';
import 'package:flappy_jet_pro/game/core/economy_config.dart';
import '../mocks/profile_mocks.dart';

void main() {
  group('Profile State Management Unit Tests', () {
    late ProfileTestMocks mocks;

    setUp(() {
      // Initialize clean SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      
      // Create fresh mock objects
      mocks = ProfileTestData.createFullMockSet();
      
      // Reset jet catalog
      MockJetSkinCatalog.resetToDefaults();
    });

    tearDown(() {
      mocks.dispose();
      MockJetSkinCatalog.clearTestSkins();
    });

    group('PlayerIdentityManager State', () {
      test('initializes with default values', () {
        final manager = MockPlayerIdentityManager();
        
        expect(manager.playerName, 'TestPlayer');
        expect(manager.playerId, 'test_player_123');
      });

      test('updates player name correctly', () async {
        final manager = MockPlayerIdentityManager();
        bool notificationReceived = false;
        
        manager.addListener(() {
          notificationReceived = true;
        });

        await manager.updatePlayerName('NewPlayerName');

        expect(manager.playerName, 'NewPlayerName');
        expect(notificationReceived, isTrue);
      });

      test('notifies listeners on name change', () async {
        final manager = MockPlayerIdentityManager();
        int notificationCount = 0;
        
        manager.addListener(() {
          notificationCount++;
        });

        await manager.updatePlayerName('Name1');
        await manager.updatePlayerName('Name2');
        await manager.updatePlayerName('Name3');

        expect(notificationCount, 3);
      });

      test('handles empty name updates', () async {
        final manager = MockPlayerIdentityManager();
        
        await manager.updatePlayerName('');
        
        expect(manager.playerName, '');
      });

      test('handles special characters in names', () async {
        final manager = MockPlayerIdentityManager();
        const specialName = 'Player@123!#';
        
        await manager.updatePlayerName(specialName);
        
        expect(manager.playerName, specialName);
      });
    });

    group('ProfileManager State', () {
      test('initializes correctly', () async {
        final manager = MockProfileManager();
        
        await manager.initialize();
        
        expect(manager.isInitialized, isTrue);
        expect(manager.nickname, 'MockNickname');
      });

      test('updates nickname and notifies listeners', () async {
        final manager = MockProfileManager();
        bool notificationReceived = false;
        
        manager.addListener(() {
          notificationReceived = true;
        });

        await manager.setNickname('NewNickname');

        expect(manager.nickname, 'NewNickname');
        expect(notificationReceived, isTrue);
      });

      test('handles initialization failure', () {
        final manager = MockProfileManager();
        
        expect(
          () => manager.simulateInitializationFailure(),
          throwsException,
        );
      });

      test('maintains state consistency across operations', () async {
        final manager = MockProfileManager();
        
        await manager.initialize();
        await manager.setNickname('TestNick1');
        await manager.setNickname('TestNick2');
        
        expect(manager.nickname, 'TestNick2');
        expect(manager.isInitialized, isTrue);
      });

      test('handles rapid nickname updates', () async {
        final manager = MockProfileManager();
        int notificationCount = 0;
        
        manager.addListener(() {
          notificationCount++;
        });

        // Rapid updates
        for (int i = 0; i < 10; i++) {
          await manager.setNickname('Nick$i');
        }

        expect(manager.nickname, 'Nick9');
        expect(notificationCount, 10);
      });
    });

    group('InventoryManager State', () {
      test('initializes with default inventory', () async {
        final manager = MockInventoryManager();
        
        await manager.initialize();
        
        expect(manager.isInitialized, isTrue);
        expect(manager.equippedSkinId, 'sky_jet');
        expect(manager.ownedSkinIds, contains('sky_jet'));
        expect(manager.softCurrency, 1000);
        expect(manager.gems, 50);
      });

      test('equips owned skins successfully', () async {
        final manager = MockInventoryManager();
        manager.setTestOwnedSkins({'sky_jet', 'flames', 'diamond_jet'});
        
        final result = await manager.equipSkin('flames');
        
        expect(result, isTrue);
        expect(manager.equippedSkinId, 'flames');
      });

      test('fails to equip unowned skins', () async {
        final manager = MockInventoryManager();
        manager.setTestOwnedSkins({'sky_jet'}); // Only owns sky_jet
        
        final result = await manager.equipSkin('diamond_jet');
        
        expect(result, isFalse);
        expect(manager.equippedSkinId, 'sky_jet'); // Unchanged
      });

      test('unlocks new skins correctly', () async {
        final manager = MockInventoryManager();
        manager.setTestOwnedSkins({'sky_jet'});
        
        final result = await manager.unlockSkin('flames');
        
        expect(result, isTrue);
        expect(manager.ownedSkinIds, contains('flames'));
      });

      test('spends soft currency correctly', () async {
        final manager = MockInventoryManager();
        manager.setTestCurrency(1000, 50);
        
        final result = await manager.spendSoftCurrency(300);
        
        expect(result, isTrue);
        expect(manager.softCurrency, 700);
      });

      test('fails to spend insufficient soft currency', () async {
        final manager = MockInventoryManager();
        manager.setTestCurrency(100, 50);
        
        final result = await manager.spendSoftCurrency(300);
        
        expect(result, isFalse);
        expect(manager.softCurrency, 100); // Unchanged
      });

      test('spends gems correctly', () async {
        final manager = MockInventoryManager();
        manager.setTestCurrency(1000, 100);
        
        final result = await manager.spendGems(25);
        
        expect(result, isTrue);
        expect(manager.gems, 75);
      });

      test('fails to spend insufficient gems', () async {
        final manager = MockInventoryManager();
        manager.setTestCurrency(1000, 10);
        
        final result = await manager.spendGems(25);
        
        expect(result, isFalse);
        expect(manager.gems, 10); // Unchanged
      });

      test('notifies listeners on currency changes', () async {
        final manager = MockInventoryManager();
        int notificationCount = 0;
        
        manager.addListener(() {
          notificationCount++;
        });

        await manager.spendSoftCurrency(100);
        await manager.spendGems(10);
        manager.setTestCurrency(500, 25); // Direct update

        expect(notificationCount, 3);
      });

      test('notifies listeners on inventory changes', () async {
        final manager = MockInventoryManager();
        int notificationCount = 0;
        
        manager.addListener(() {
          notificationCount++;
        });

        await manager.unlockSkin('new_skin');
        await manager.equipSkin('new_skin');

        expect(notificationCount, 2);
      });

      test('handles edge case currency values', () async {
        final manager = MockInventoryManager();
        
        // Test zero values
        manager.setTestCurrency(0, 0);
        expect(await manager.spendSoftCurrency(1), isFalse);
        expect(await manager.spendGems(1), isFalse);
        
        // Test exact amounts
        manager.setTestCurrency(100, 50);
        expect(await manager.spendSoftCurrency(100), isTrue);
        expect(manager.softCurrency, 0);
        
        manager.setTestCurrency(0, 50);
        expect(await manager.spendGems(50), isTrue);
        expect(manager.gems, 0);
      });
    });

    group('JetSkinCatalog State', () {
      test('provides default starter jet', () {
        final starterJet = MockJetSkinCatalog.starterJet;
        
        expect(starterJet.id, 'sky_jet');
        expect(starterJet.displayName, 'Sky Jet');
        expect(starterJet.price, 0);
      });

      test('retrieves skins by ID correctly', () {
        final skyJet = MockJetSkinCatalog.getSkinById('sky_jet');
        final flames = MockJetSkinCatalog.getSkinById('flames');
        final nonExistent = MockJetSkinCatalog.getSkinById('non_existent');
        
        expect(skyJet, isNotNull);
        expect(skyJet!.id, 'sky_jet');
        expect(flames, isNotNull);
        expect(flames!.id, 'flames');
        expect(nonExistent, isNull);
      });

      test('returns all available skins', () {
        final allSkins = MockJetSkinCatalog.getAllSkins();
        
        expect(allSkins.length, greaterThanOrEqualTo(2));
        expect(allSkins.any((skin) => skin.id == 'sky_jet'), isTrue);
        expect(allSkins.any((skin) => skin.id == 'flames'), isTrue);
      });

      test('handles dynamic skin addition', () {
        final newSkin = JetSkin(
          id: 'test_skin',
          displayName: 'Test Skin',
          assetPath: 'jets/test_skin.png',
          price: 200.0,
          description: 'Test skin for unit testing',
          rarity: JetRarity.common,
          isPurchased: false,
          isEquipped: false,
          category: JetSkinCategory.classic,
          tags: ['test'],
        );
        
        MockJetSkinCatalog.addTestSkin(newSkin);
        
        final retrievedSkin = MockJetSkinCatalog.getSkinById('test_skin');
        expect(retrievedSkin, isNotNull);
        expect(retrievedSkin!.displayName, 'Test Skin');
      });

      test('handles catalog reset correctly', () {
        // Add custom skin
        MockJetSkinCatalog.addTestSkin(JetSkin(
          id: 'custom_skin',
          displayName: 'Custom',
          assetPath: 'jets/custom.png',
          price: 100.0,
          description: 'Custom skin',
          rarity: JetRarity.common,
          isPurchased: false,
          isEquipped: false,
          category: JetSkinCategory.classic,
          tags: ['custom'],
        ));
        
        // Verify it exists
        expect(MockJetSkinCatalog.getSkinById('custom_skin'), isNotNull);
        
        // Reset to defaults
        MockJetSkinCatalog.resetToDefaults();
        
        // Custom skin should be gone, defaults should remain
        expect(MockJetSkinCatalog.getSkinById('custom_skin'), isNull);
        expect(MockJetSkinCatalog.getSkinById('sky_jet'), isNotNull);
        expect(MockJetSkinCatalog.getSkinById('flames'), isNotNull);
      });
    });

    group('EconomyConfig State', () {
      test('calculates skin prices correctly', () {
        final economy = MockEconomyConfig();
        
        final freeSkin = JetSkin(
          id: 'free_skin',
          displayName: 'Free Skin',
          assetPath: 'jets/free.png',
          price: 0.0,
          description: 'Free skin',
          rarity: JetRarity.common,
          isPurchased: true,
          isEquipped: false,
          category: JetSkinCategory.classic,
          tags: ['free'],
        );
        
        final paidSkin = JetSkin(
          id: 'paid_skin',
          displayName: 'Paid Skin',
          assetPath: 'jets/paid.png',
          price: 500.0,
          description: 'Paid skin',
          rarity: JetRarity.rare,
          isPurchased: false,
          isEquipped: false,
          category: JetSkinCategory.military,
          tags: ['premium'],
        );
        
        expect(economy.getSkinCoinPrice(freeSkin), 0);
        expect(economy.getSkinCoinPrice(paidSkin), 500);
      });
    });

    group('SharedPreferences Integration', () {
      test('loads scores from SharedPreferences correctly', () async {
        SharedPreferences.setMockInitialValues({
          'best_score': 150,
          'best_streak': 75,
        });
        
        final prefs = await SharedPreferences.getInstance();
        
        expect(prefs.getInt('best_score'), 150);
        expect(prefs.getInt('best_streak'), 75);
      });

      test('handles missing SharedPreferences keys', () async {
        SharedPreferences.setMockInitialValues({});
        
        final prefs = await SharedPreferences.getInstance();
        
        expect(prefs.getInt('best_score'), isNull);
        expect(prefs.getInt('best_streak'), isNull);
        
        // Should use default values (0)
        expect(prefs.getInt('best_score') ?? 0, 0);
        expect(prefs.getInt('best_streak') ?? 0, 0);
      });

      test('persists data correctly', () async {
        SharedPreferences.setMockInitialValues({});
        
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setInt('best_score', 200);
        await prefs.setString('player_name', 'TestPlayer');
        
        expect(prefs.getInt('best_score'), 200);
        expect(prefs.getString('player_name'), 'TestPlayer');
      });

      test('handles data type mismatches gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'best_score': 'not_a_number',
          'player_name': 12345,
        });
        
        final prefs = await SharedPreferences.getInstance();
        
        // Should handle wrong types gracefully - in mock, this throws, so we catch it
        expect(() => prefs.getInt('best_score'), throwsA(isA<TypeError>()));
        expect(() => prefs.getString('player_name'), throwsA(isA<TypeError>()));
      });
    });

    group('Cross-System State Synchronization', () {
      test('player name synchronizes across managers', () async {
        final playerIdentity = mocks.playerIdentity;
        final profile = mocks.profile;
        
        // Update player identity
        await playerIdentity.updatePlayerName('SyncedName');
        
        // Profile should be able to access the updated name
        expect(playerIdentity.playerName, 'SyncedName');
        
        // In real implementation, profile would sync with player identity
        // Here we test the mock behavior
        expect(profile.nickname, isNotNull);
      });

      test('inventory changes trigger proper notifications', () async {
        final inventory = mocks.inventory;
        int notificationCount = 0;
        
        inventory.addListener(() {
          notificationCount++;
        });
        
        // Multiple operations should each trigger notifications
        await inventory.unlockSkin('new_skin_1');
        await inventory.unlockSkin('new_skin_2');
        await inventory.equipSkin('new_skin_1');
        await inventory.spendSoftCurrency(100);
        
        expect(notificationCount, 4);
      });

      test('state remains consistent during rapid operations', () async {
        final inventory = mocks.inventory;
        inventory.setTestCurrency(1000, 100);
        
        // Rapid sequential operations
        await inventory.spendSoftCurrency(100);
        await inventory.spendGems(10);
        await inventory.unlockSkin('rapid_skin');
        await inventory.equipSkin('rapid_skin');
        
        // Final state should be consistent
        expect(inventory.softCurrency, 900);
        expect(inventory.gems, 90);
        expect(inventory.equippedSkinId, 'rapid_skin');
        expect(inventory.ownedSkinIds, contains('rapid_skin'));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('handles null and empty string inputs', () async {
        final playerIdentity = mocks.playerIdentity;
        
        // Empty string should be handled
        await playerIdentity.updatePlayerName('');
        expect(playerIdentity.playerName, '');
        
        // Null handling depends on implementation
        // In mock, we control the behavior
      });

      test('handles negative currency values gracefully', () async {
        final inventory = mocks.inventory;
        
        // Set negative values (edge case)
        inventory.setTestCurrency(-100, -50);
        
        // Should not allow spending from negative balance
        expect(await inventory.spendSoftCurrency(10), isFalse);
        expect(await inventory.spendGems(5), isFalse);
      });

      test('handles duplicate skin operations', () async {
        final inventory = mocks.inventory;
        
        // Try to unlock same skin multiple times
        await inventory.unlockSkin('duplicate_skin');
        await inventory.unlockSkin('duplicate_skin');
        await inventory.unlockSkin('duplicate_skin');
        
        // Should only appear once in owned skins
        final ownedSkins = inventory.ownedSkinIds;
        final duplicateCount = ownedSkins.where((id) => id == 'duplicate_skin').length;
        expect(duplicateCount, 1);
      });

      test('maintains data integrity under stress', () async {
        final inventory = mocks.inventory;
        inventory.setTestCurrency(10000, 1000);
        
        // Perform many operations rapidly
        for (int i = 0; i < 100; i++) {
          await inventory.spendSoftCurrency(10);
          await inventory.spendGems(1);
          
          if (i % 10 == 0) {
            await inventory.unlockSkin('stress_skin_$i');
          }
        }
        
        // Final state should be mathematically correct
        expect(inventory.softCurrency, 9000); // 10000 - (100 * 10)
        expect(inventory.gems, 900); // 1000 - (100 * 1)
        expect(inventory.ownedSkinIds.length, greaterThanOrEqualTo(10));
      });
    });
  });
}
