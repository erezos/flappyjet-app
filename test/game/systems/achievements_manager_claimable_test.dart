import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/achievements_manager.dart';

/// 🏅 CLAIMABLE ACHIEVEMENTS GETTERS TESTS
/// 
/// These tests verify the new claimable achievements getters work correctly:
/// - claimableAchievementsCount
/// - claimableAchievementsCoinReward
/// - claimableAchievementsGemReward
/// - hasClaimableAchievements
/// - claimableAchievements (list)
/// 
/// WHY: These getters power the floating missions banner and notification badges.
/// They must be accurate and efficient for real-time UI updates.
/// 
/// NOTE: AchievementsManager is a singleton that persists state between tests.
/// Tests are designed to be resilient to pre-existing unlocked achievements.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementsManager Claimable Getters', () {
    late AchievementsManager manager;

    setUp(() async {
      // Reset SharedPreferences for clean test state
      SharedPreferences.setMockInitialValues({});
      
      // Get singleton instance and initialize
      manager = AchievementsManager();
      
      // Note: AchievementsManager is a singleton and may have state from other tests
      // Tests should be written to handle pre-existing state
      await manager.initialize();
    });

    group('claimableAchievementsCount', () {
      test('returns non-negative integer', () {
        // Should always return a non-negative count
        expect(manager.claimableAchievementsCount, greaterThanOrEqualTo(0));
      });

      test('returns correct count when achievements are unlocked', () async {
        // Unlock some achievements by updating progress
        await manager.checkScoreAchievements(1); // first_flight
        await manager.checkScoreAchievements(10); // rookie_pilot
        
        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Count should reflect unlocked but unclaimed achievements
        final unlockedNotClaimed = manager.achievements.values
            .where((a) => a.unlocked && !a.claimed)
            .length;
        
        expect(manager.claimableAchievementsCount, equals(unlockedNotClaimed));
      });

      test('is consistent with claimableAchievements list length', () async {
        // Count should always match list length
        expect(
          manager.claimableAchievementsCount,
          equals(manager.claimableAchievements.length),
        );
        
        // Unlock more achievements
        await manager.checkScoreAchievements(10);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should still be consistent
        expect(
          manager.claimableAchievementsCount,
          equals(manager.claimableAchievements.length),
        );
      });
    });

    group('claimableAchievementsCoinReward', () {
      test('returns non-negative value', () {
        // Should always be non-negative
        expect(manager.claimableAchievementsCoinReward, greaterThanOrEqualTo(0));
      });

      test('returns correct sum of claimable coin rewards', () async {
        // Unlock achievements
        await manager.checkScoreAchievements(10);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Calculate expected reward manually
        final expectedReward = manager.achievements.values
            .where((a) => a.unlocked && !a.claimed)
            .fold(0, (sum, a) => sum + a.coinReward);
        
        expect(manager.claimableAchievementsCoinReward, equals(expectedReward));
      });
    });

    group('claimableAchievementsGemReward', () {
      test('returns 0 when no achievements are claimable', () {
        expect(manager.claimableAchievementsGemReward, equals(0));
      });

      test('returns correct sum of claimable gem rewards', () async {
        // Unlock higher tier achievements that give gems
        await manager.checkScoreAchievements(25); // sky_navigator gives gems
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Calculate expected gem reward manually
        final expectedGems = manager.achievements.values
            .where((a) => a.unlocked && !a.claimed)
            .fold(0, (sum, a) => sum + a.gemReward);
        
        expect(manager.claimableAchievementsGemReward, equals(expectedGems));
      });
    });

    group('hasClaimableAchievements', () {
      test('returns boolean value', () {
        // Should return a boolean
        expect(manager.hasClaimableAchievements, isA<bool>());
      });

      test('is consistent with claimableAchievementsCount', () async {
        // Unlock an achievement
        await manager.checkScoreAchievements(1); // first_flight
        await Future.delayed(const Duration(milliseconds: 100));
        
        // hasClaimableAchievements should match count > 0
        expect(
          manager.hasClaimableAchievements,
          equals(manager.claimableAchievementsCount > 0),
        );
      });
    });

    group('claimableAchievements list', () {
      test('returns list type', () {
        expect(manager.claimableAchievements, isA<List<Achievement>>());
      });

      test('returns list of unlocked but unclaimed achievements', () async {
        // Unlock achievements
        await manager.checkScoreAchievements(10);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final claimable = manager.claimableAchievements;
        
        // Verify all returned achievements are unlocked and not claimed
        for (final achievement in claimable) {
          expect(achievement.unlocked, isTrue);
          expect(achievement.claimed, isFalse);
        }
      });

      test('is sorted by rarity (highest first)', () async {
        // Unlock multiple achievements of different rarities
        await manager.checkScoreAchievements(25); // Silver + Bronze
        await Future.delayed(const Duration(milliseconds: 100));
        
        final claimable = manager.claimableAchievements;
        
        if (claimable.length > 1) {
          // Verify sorted by rarity descending
          for (int i = 0; i < claimable.length - 1; i++) {
            expect(
              claimable[i].rarity.index,
              greaterThanOrEqualTo(claimable[i + 1].rarity.index),
            );
          }
        }
      });
    });
  });

  group('AchievementsManager Claimable - Integration', () {
    test('all claimable getters are consistent with each other', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AchievementsManager();
      await manager.initialize();

      // Unlock some achievements
      await manager.checkScoreAchievements(25);
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify consistency
      final count = manager.claimableAchievementsCount;
      final coinReward = manager.claimableAchievementsCoinReward;
      final hasRewards = manager.hasClaimableAchievements;
      final list = manager.claimableAchievements;

      // List length should match count
      expect(list.length, equals(count));

      // If count > 0, hasRewards should be true
      if (count > 0) {
        expect(hasRewards, isTrue);
        expect(coinReward, greaterThan(0));
      } else {
        expect(hasRewards, isFalse);
        expect(coinReward, equals(0));
      }
    });

    test('getters update in real-time when notifyListeners is called', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AchievementsManager();
      await manager.initialize();

      int notifyCount = 0;
      int lastCount = manager.claimableAchievementsCount;

      manager.addListener(() {
        notifyCount++;
        // Check that getter reflects new state
        final newCount = manager.claimableAchievementsCount;
        // Count should be >= lastCount (achievements can be unlocked, not relocked)
        expect(newCount, greaterThanOrEqualTo(lastCount));
        lastCount = newCount;
      });

      // Unlock achievements progressively
      await manager.checkScoreAchievements(1);
      await manager.checkScoreAchievements(10);
      await manager.checkScoreAchievements(25);

      // Verify listeners were called
      expect(notifyCount, greaterThan(0));
    });
  });

  group('AchievementsManager Claimable - Edge Cases', () {
    test('getters do not throw when called', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AchievementsManager();
      await manager.initialize();
      
      // These should not throw, regardless of state
      expect(() => manager.claimableAchievementsCount, returnsNormally);
      expect(() => manager.claimableAchievementsCoinReward, returnsNormally);
      expect(() => manager.claimableAchievementsGemReward, returnsNormally);
      expect(() => manager.hasClaimableAchievements, returnsNormally);
      expect(() => manager.claimableAchievements, returnsNormally);
    });

    test('claimable list only contains unlocked unclaimed achievements', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AchievementsManager();
      await manager.initialize();

      // Ensure there's at least one claimable
      await manager.checkScoreAchievements(10);
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Every item in claimableAchievements should be unlocked AND not claimed
      for (final achievement in manager.claimableAchievements) {
        expect(achievement.unlocked, isTrue,
            reason: 'Achievement ${achievement.id} should be unlocked');
        expect(achievement.claimed, isFalse,
            reason: 'Achievement ${achievement.id} should not be claimed');
      }
    });

    test('count matches list length', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AchievementsManager();
      await manager.initialize();

      // Verify count equals list length
      expect(
        manager.claimableAchievementsCount,
        equals(manager.claimableAchievements.length),
      );
    });
  });
}

