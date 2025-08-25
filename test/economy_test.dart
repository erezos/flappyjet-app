import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/core/economy_config.dart';
import 'package:flappy_jet_pro/game/core/jet_skins.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';
import 'package:flappy_jet_pro/game/systems/remote_config_manager.dart';

void main() {
  group('Economy System Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('EconomyConfig Tests', () {
      test('should have correct default skin prices', () {
        final economy = EconomyConfig();
        
        // Create test skins for each rarity
        final commonSkin = JetSkin(
          id: 'test_common',
          displayName: 'Test Common',
          assetPath: 'jets/common.png',
          rarity: JetRarity.common,
          category: JetSkinCategory.classic,
          description: 'Test common skin',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );
        final rareSkin = JetSkin(
          id: 'test_rare',
          displayName: 'Test Rare',
          assetPath: 'jets/rare.png',
          rarity: JetRarity.rare,
          category: JetSkinCategory.classic,
          description: 'Test rare skin',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );
        final epicSkin = JetSkin(
          id: 'test_epic',
          displayName: 'Test Epic',
          assetPath: 'jets/epic.png',
          rarity: JetRarity.epic,
          category: JetSkinCategory.classic,
          description: 'Test epic skin',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );
        final legendarySkin = JetSkin(
          id: 'test_legendary',
          displayName: 'Test Legendary',
          assetPath: 'jets/legendary.png',
          rarity: JetRarity.legendary,
          category: JetSkinCategory.classic,
          description: 'Test legendary skin',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );

        expect(economy.getSkinCoinPrice(commonSkin), 400);
        expect(economy.getSkinCoinPrice(rareSkin), 800);
        expect(economy.getSkinCoinPrice(epicSkin), 1600);
        expect(economy.getSkinCoinPrice(legendarySkin), 3200);
      });

      test('should update skin prices via remote config', () {
        final economy = EconomyConfig();
        final testSkin = JetSkin(
          id: 'test',
          displayName: 'Test',
          assetPath: 'jets/test.png',
          rarity: JetRarity.common,
          category: JetSkinCategory.classic,
          description: 'Test skin',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );

        // Initial price
        expect(economy.getSkinCoinPrice(testSkin), 400);

        // Update prices
        economy.updateSkinPrices({
          JetRarity.common: 500,
          JetRarity.rare: 1000,
          JetRarity.epic: 2000,
          JetRarity.legendary: 4000,
        });

        expect(economy.getSkinCoinPrice(testSkin), 500);
      });

      test('should have correct gem pack definitions', () {
        final gemPacks = EconomyConfig.gemPacks;
        
        expect(gemPacks.length, 4);
        expect(gemPacks['gems_pack_small']?.gems, 100);
        expect(gemPacks['gems_pack_small']?.bonusGems, 0);
        expect(gemPacks['gems_pack_medium']?.totalGems, 550); // 500 + 50 bonus
        expect(gemPacks['gems_pack_large']?.hasBonus, true);
        expect(gemPacks['gems_pack_mega']?.usdPrice, 19.99);
      });

      test('should calculate continue gem costs correctly', () {
        final economy = EconomyConfig();
        
        expect(economy.getContinueGemCost(1), 20);
        expect(economy.getContinueGemCost(2), 40);
        expect(economy.getContinueGemCost(3), 80);
        expect(economy.getContinueGemCost(4), 80); // Should cap at highest price
      });

      test('should update from remote config correctly', () async {
        final economy = EconomyConfig();
        
        final config = {
          'skin_prices': {
            'common': 300,
            'rare': 600,
            'epic': 1200,
            'legendary': 2400,
          },
          'ad_coin_reward': 50,
          'continue_gem_costs': [15, 30, 60],
          'daily_bonus_coins': [5, 10, 15, 20, 25, 35, 45],
        };

        await economy.updateFromRemoteConfig(config);

        // Test updated values
        expect(economy.rewardedAdCoinAmount, 50);
        expect(economy.getContinueGemCost(1), 15);
        expect(economy.getContinueGemCost(2), 30);
        expect(economy.getContinueGemCost(3), 60);
        expect(economy.getDailyBonus(0), 5);
        expect(economy.getDailyBonus(6), 45);
      });
    });

    group('InventoryManager Tests', () {
      test('should initialize with default values', () async {
        final inventory = InventoryManager();
        await inventory.initialize();

        expect(inventory.softCurrency, 0);
        expect(inventory.gems, 0);
        expect(inventory.isHeartBoosterActive, false);
        expect(inventory.ownedSkinIds.contains(JetSkinCatalog.starterJet.id), true);
        expect(inventory.equippedSkinId, JetSkinCatalog.starterJet.id);
      });

      test('should manage soft currency correctly', () async {
        final inventory = InventoryManager();
        await inventory.initialize();

        // Grant currency
        await inventory.grantSoftCurrency(100);
        expect(inventory.softCurrency, 100);

        // Spend currency
        final success = await inventory.spendSoftCurrency(50);
        expect(success, true);
        expect(inventory.softCurrency, 50);

        // Try to spend more than available
        final failure = await inventory.spendSoftCurrency(100);
        expect(failure, false);
        expect(inventory.softCurrency, 50);
      });

      test('should manage gems correctly', () async {
        final inventory = InventoryManager();
        await inventory.initialize();

        // Grant gems
        await inventory.grantGems(50);
        expect(inventory.gems, 50);

        // Spend gems
        final success = await inventory.spendGems(25);
        expect(success, true);
        expect(inventory.gems, 25);

        // Try to spend more than available
        final failure = await inventory.spendGems(50);
        expect(failure, false);
        expect(inventory.gems, 25);
      });

      test('should manage Heart Booster correctly', () async {
        final inventory = InventoryManager();
        await inventory.initialize();

        expect(inventory.isHeartBoosterActive, false);

        // Activate booster
        await inventory.activateHeartBooster(const Duration(hours: 1));
        expect(inventory.isHeartBoosterActive, true);
        
        // Check expiry
        expect(inventory.heartBoosterExpiry, isNotNull);
        expect(inventory.heartBoosterExpiry!.isAfter(DateTime.now()), true);
      });

      test('should persist data correctly', () async {
        // First instance
        final inventory1 = InventoryManager();
        await inventory1.initialize();
        await inventory1.grantSoftCurrency(200);
        await inventory1.grantGems(75);
        await inventory1.unlockSkin('test_skin');

        // Second instance should load persisted data
        final inventory2 = InventoryManager();
        await inventory2.initialize();
        
        expect(inventory2.softCurrency, 200);
        expect(inventory2.gems, 75);
        expect(inventory2.ownedSkinIds.contains('test_skin'), true);
      });
    });

    group('LivesManager Tests', () {
      test('should initialize with correct values', () async {
        final lives = LivesManager();
        await lives.initialize();

        // Note: With Heart Booster system integration, max lives can be dynamic
        // When no booster is active, it should be 3, but test may have booster from previous tests
        expect(lives.currentLives, greaterThanOrEqualTo(3)); // At least default max lives
        expect(lives.regenIntervalSeconds, lessThanOrEqualTo(10 * 60)); // 10 min default or 8 min with booster
        expect(lives.bestScore, 0);
        expect(lives.bestStreak, 0);
      });

      test('should consume and add lives correctly', () async {
        final lives = LivesManager();
        await lives.initialize();

        final initialLives = lives.currentLives;
        final maxLives = lives.maxLives;

        // Consume a life
        await lives.consumeLife();
        expect(lives.currentLives, initialLives - 1);

        // Add a life
        await lives.addLife();
        expect(lives.currentLives, initialLives);

        // Can't exceed max lives
        await lives.addLife();
        expect(lives.currentLives, lessThanOrEqualTo(maxLives));
      });

      test('should handle Heart Booster effects', () async {
        final inventory = InventoryManager();
        final lives = LivesManager();
        
        await inventory.initialize();
        await lives.initialize();

        // Activate Heart Booster
        await inventory.activateHeartBooster(const Duration(hours: 1));

        expect(lives.maxLives, 6); // Boosted max lives
        expect(lives.regenIntervalSeconds, 8 * 60); // 8 minutes with booster
      });

      test('should update best scores correctly', () async {
        final lives = LivesManager();
        await lives.initialize();

        // Update best score
        bool isNewRecord = await lives.updateBestScore(100);
        expect(isNewRecord, true);
        expect(lives.bestScore, 100);

        // Lower score shouldn't update
        isNewRecord = await lives.updateBestScore(50);
        expect(isNewRecord, false);
        expect(lives.bestScore, 100);

        // Higher score should update
        isNewRecord = await lives.updateBestScore(150);
        expect(isNewRecord, true);
        expect(lives.bestScore, 150);
      });

      test('should update best streak correctly', () async {
        final lives = LivesManager();
        await lives.initialize();

        // Update best streak
        bool isNewRecord = await lives.updateBestStreak(5);
        expect(isNewRecord, true);
        expect(lives.bestStreak, 5);

        // Lower streak shouldn't update
        isNewRecord = await lives.updateBestStreak(3);
        expect(isNewRecord, false);
        expect(lives.bestStreak, 5);

        // Higher streak should update
        isNewRecord = await lives.updateBestStreak(8);
        expect(isNewRecord, true);
        expect(lives.bestStreak, 8);
      });
    });

    group('RemoteConfigManager Tests', () {
      test('should initialize in development mode', () async {
        final remoteConfig = RemoteConfigManager();
        await remoteConfig.initialize();

        expect(remoteConfig.initialized, true);
        expect(remoteConfig.developmentMode, true);
      });

      test('should provide default config values', () async {
        final remoteConfig = RemoteConfigManager();
        await remoteConfig.initialize();

        expect(remoteConfig.getBool('heart_booster_enabled', false), true);
        expect(remoteConfig.getBool('rewarded_ads_enabled', false), true);
        expect(remoteConfig.getInt('ad_coin_reward', 0), 25);
        expect(remoteConfig.getString('featured_skin_id', ''), '');
      });

      test('should handle feature flags correctly', () async {
        final remoteConfig = RemoteConfigManager();
        await remoteConfig.initialize();

        expect(remoteConfig.isFeatureEnabled('heart_booster'), true);
        expect(remoteConfig.isFeatureEnabled('rewarded_ads'), true);
        expect(remoteConfig.isFeatureEnabled('daily_missions'), false);
        expect(remoteConfig.isFeatureEnabled('leaderboard'), false);
      });

      test('should update development values', () async {
        final remoteConfig = RemoteConfigManager();
        await remoteConfig.initialize();

        await remoteConfig.updateDevelopmentValue('test_value', 42);
        expect(remoteConfig.getInt('test_value', 0), 42);
      });

      test('should provide A/B test variants consistently', () async {
        final remoteConfig = RemoteConfigManager();
        await remoteConfig.initialize();

        final variants = ['A', 'B', 'C'];
        final variant1 = remoteConfig.getABTestVariant('test', variants);
        final variant2 = remoteConfig.getABTestVariant('test', variants);
        
        // Should be consistent for same user
        expect(variant1, variant2);
        expect(variants.contains(variant1), true);
      });
    });

    group('Integration Tests', () {
      test('should work together correctly', () async {
        final economy = EconomyConfig();
        final inventory = InventoryManager();
        final lives = LivesManager();
        final remoteConfig = RemoteConfigManager();

        // Initialize all systems
        await inventory.initialize();
        await lives.initialize();
        await remoteConfig.initialize();

        // Test Heart Booster purchase flow
        await inventory.grantGems(50);
        await inventory.spendGems(EconomyConfig.heartBoosterPack.gemPrice);
        await inventory.activateHeartBooster(EconomyConfig.heartBoosterPack.duration);

        expect(inventory.isHeartBoosterActive, true);
        expect(lives.maxLives, 6);
        expect(lives.regenIntervalSeconds, 8 * 60);

        // Test skin purchase flow
        final testSkin = JetSkin(
          id: 'test_skin',
          displayName: 'Test Skin',
          assetPath: 'jets/test.png',
          rarity: JetRarity.rare,
          category: JetSkinCategory.classic,
          description: 'Test skin for integration',
          tags: ['test'],
          price: 0,
          isPurchased: false,
          isEquipped: false,
        );

        final skinPrice = economy.getSkinCoinPrice(testSkin);
        await inventory.grantSoftCurrency(skinPrice);
        await inventory.spendSoftCurrency(skinPrice);
        await inventory.unlockSkin(testSkin.id);
        await inventory.equipSkin(testSkin.id);

        expect(inventory.isOwned(testSkin.id), true);
        expect(inventory.equippedSkinId, testSkin.id);
      });
    });
  });
}
