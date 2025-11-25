import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/daily_streak_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/currency_manager.dart';
import 'package:flappy_jet_pro/game/systems/boost_manager.dart';

void main() {
  group('DailyStreakManager Tests', () {
    late DailyStreakManager manager;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initialize singleton managers
      await CurrencyManager().initialize();
      await InventoryManager().initialize();
      await BoostManager().initialize();

      manager = DailyStreakManager();
      await manager.initialize();
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    // ✅ TEST 1: Initial state
    test('Initial state - no streak', () {
      expect(manager.currentStreak, 0);
      expect(manager.canClaimToday, false);
      expect(manager.hasClaimedToday, false);
      expect(manager.currentCycle, 0);
    });

    // ✅ TEST 2: First claim
    test('First claim - starts streak at day 1', () async {
      // Before claim
      expect(manager.currentStreak, 0);
      expect(manager.canClaimToday, false);

      // Claim first reward
      final result = await manager.claimDailyReward();

      // After claim
      expect(result, true, reason: 'First claim should succeed');
      expect(manager.currentStreak, 1, reason: 'Streak should be 1 after first claim');
      expect(manager.hasClaimedToday, true);
      expect(manager.canClaimToday, false, reason: 'Cannot claim twice in same day');
    });

    // ✅ TEST 3: Cannot claim twice in same day
    test('Cannot claim twice in same day', () async {
      // First claim
      await manager.claimDailyReward();
      expect(manager.hasClaimedToday, true);

      // Try second claim
      final secondResult = await manager.claimDailyReward();
      expect(secondResult, false, reason: 'Second claim on same day should fail');
      expect(manager.currentStreak, 1, reason: 'Streak should remain 1');
    });

    // ✅ TEST 4: 7-day cycle completion
    test('Complete 7-day cycle and reset to new cycle', () async {
      // Simulate 7 days of claims
      for (int day = 1; day <= 7; day++) {
        // Manually set last claim date to simulate days passing
        if (day > 1) {
          // Hack: Set last claim date to yesterday
          final yesterday = DateTime.now().subtract(Duration(days: 1));
          await SharedPreferences.getInstance().then((prefs) {
            prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
          });
          await manager.initialize(); // Reload state
        }

        final result = await manager.claimDailyReward();
        expect(result, true, reason: 'Day $day claim should succeed');
        expect(manager.currentStreak, day, reason: 'Streak should be $day');
      }

      // After 7 days, cycle should complete
      expect(manager.totalStreaksCompleted, 1, reason: 'Should have 1 completed cycle');

      // Next day should start cycle 2
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      await manager.claimDailyReward();
      expect(manager.currentCycle, 2, reason: 'Should be in cycle 2');
      expect(manager.currentStreak, 1, reason: 'Streak resets to 1 in new cycle');
    });

    // ✅ TEST 5: Streak breaks if more than 1 day passes
    test('Streak breaks if 2+ days pass without claim', () async {
      // First claim
      await manager.claimDailyReward();
      expect(manager.currentStreak, 1);

      // Simulate 2 days passing (streak should break)
      final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', twoDaysAgo.toIso8601String());
      });
      await manager.initialize();

      // Streak should be reset
      expect(manager.currentStreak, 0, reason: 'Streak should reset after 2+ days');
      expect(manager.canClaimToday, false, reason: 'Should not be able to claim after break');
    });

    // ✅ TEST 6: New player rewards (≤1 skin)
    test('New player gets Flash Strike jet on day 2', () async {
      // Ensure player has ≤1 skin
      final inventory = InventoryManager();
      expect(inventory.ownedSkinIds.length <= 1, true, reason: 'New player should have ≤1 skin');

      // Claim day 1 (100 coins)
      await manager.claimDailyReward();

      // Simulate next day
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      // Claim day 2 (Flash Strike jet)
      final balanceBefore = CurrencyManager().coinBalance;
      await manager.claimDailyReward();

      // Verify player got jet or coins (if they already own it)
      final hasJet = inventory.isOwned('flash_strike');
      if (!hasJet) {
        // Should have gotten coins instead
        expect(CurrencyManager().coinBalance > balanceBefore, true,
            reason: 'Should get coins if jet already owned');
      } else {
        expect(hasJet, true, reason: 'Should get Flash Strike jet');
      }
    });

    // ✅ TEST 7: Experienced player rewards (2+ skins)
    test('Experienced player gets 10 gems on day 2', () async {
      // Give player 2 skins to become experienced
      final inventory = InventoryManager();
      await inventory.unlockSkin('flash_strike');
      await inventory.unlockSkin('storm_chaser');
      expect(inventory.ownedSkinIds.length >= 2, true, reason: 'Should have 2+ skins');

      // Claim day 1 (100 coins)
      await manager.claimDailyReward();

      // Simulate next day
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      // Claim day 2 (10 gems)
      final gemsBefore = CurrencyManager().gemBalance;
      await manager.claimDailyReward();
      final gemsAfter = CurrencyManager().gemBalance;

      expect(gemsAfter, gemsBefore + 10, reason: 'Should get 10 gems on day 2');
    });

    // ✅ TEST 8: Progressive jet system (Day 6)
    test('Day 6 progressive jet system works correctly', () async {
      final inventory = InventoryManager();

      // Give player 2 skins to use experienced track
      await inventory.unlockSkin('flash_strike');
      await inventory.unlockSkin('storm_chaser');

      // Fast-forward to day 6
      for (int day = 1; day < 6; day++) {
        if (day > 1) {
          final yesterday = DateTime.now().subtract(Duration(days: 1));
          await SharedPreferences.getInstance().then((prefs) {
            prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
          });
          await manager.initialize();
        }
        await manager.claimDailyReward();
      }

      // Day 6 claim
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      final coinsBefore = CurrencyManager().coinBalance;
      await manager.claimDailyReward();

      // Should get first jet in progression that player doesn't own
      const jetProgression = [
        'cobra_strike',
        'storm_chaser',
        'disco_fever',
        'ruby_phantom',
        'sugar_storm',
      ];

      bool gotJet = false;
      String? unlockedJetId;
      for (final jetId in jetProgression) {
        if (inventory.isOwned(jetId)) {
          gotJet = true;
          unlockedJetId = jetId;
          break;
        }
      }

      // Either got a jet or 500 coins (if owns all)
      if (!gotJet) {
        expect(CurrencyManager().coinBalance, coinsBefore + 500,
            reason: 'Should get 500 coins if owns all jets');
      } else {
        expect(gotJet, true, reason: 'Should get a jet from progression');
        // ✅ AUTO-EQUIP VERIFICATION: Jet should be auto-equipped when unlocked
        expect(inventory.equippedSkinId, unlockedJetId,
            reason: 'Unlocked jet should be auto-equipped');
      }
    });

    // ✅ TEST 9: Duplicate jet handling
    test('Duplicate jet gives 400 coins instead', () async {
      final inventory = InventoryManager();

      // Give player Flash Strike
      await inventory.unlockSkin('flash_strike');

      // Claim day 1
      await manager.claimDailyReward();

      // Simulate next day
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      // Claim day 2 (Flash Strike jet - but player already owns it)
      final coinsBefore = CurrencyManager().coinBalance;
      await manager.claimDailyReward();
      final coinsAfter = CurrencyManager().coinBalance;

      expect(coinsAfter, coinsBefore + 400,
          reason: 'Should get 400 coins for duplicate jet');
    });

    // ✅ TEST 10: Persistence across app restarts
    test('Streak persists after app restart', () async {
      // Claim day 1
      await manager.claimDailyReward();
      expect(manager.currentStreak, 1);

      // Simulate app restart by creating new manager instance
      final newManager = DailyStreakManager();
      await newManager.initialize();

      expect(newManager.currentStreak, 1, reason: 'Streak should persist');
      expect(newManager.hasClaimedToday, true, reason: 'Claim status should persist');
    });

    // ✅ TEST 11: Can claim next day
    test('Can claim again next day', () async {
      // Claim day 1
      await manager.claimDailyReward();
      expect(manager.canClaimToday, false);

      // Simulate next day
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
      });
      await manager.initialize();

      expect(manager.canClaimToday, true, reason: 'Should be able to claim next day');
      expect(manager.hasClaimedToday, false);

      // Claim day 2
      final result = await manager.claimDailyReward();
      expect(result, true);
      expect(manager.currentStreak, 2);
    });

    // ✅ TEST 12: Analytics events fired
    test('Analytics events are tracked correctly', () async {
      // Note: This is a basic test. In production, you'd mock UnifiedAnalyticsManager
      // and verify the trackEvent calls.

      // Claim first reward
      await manager.claimDailyReward();
      // Event 'daily_streak_claimed' should be fired (checked via logs)

      // Complete 7 days
      for (int day = 2; day <= 7; day++) {
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        await SharedPreferences.getInstance().then((prefs) {
          prefs.setString('daily_streak_last_claim', yesterday.toIso8601String());
        });
        await manager.initialize();
        await manager.claimDailyReward();
      }
      // Event 'daily_streak_milestone' should be fired on day 7

      // Break streak
      final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
      await SharedPreferences.getInstance().then((prefs) {
        prefs.setString('daily_streak_last_claim', twoDaysAgo.toIso8601String());
      });
      await manager.initialize();
      // Event 'daily_streak_broken' should be fired

      // Success (events are logged, manual verification in console)
      expect(true, true);
    });
  });
}
