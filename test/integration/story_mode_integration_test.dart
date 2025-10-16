/// 🧪 STORY MODE INTEGRATION TEST
/// 
/// Comprehensive test for Phase 1 story mode implementation.
/// Tests the complete flow: start → play → complete/fail.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/level_system_manager.dart';
import 'package:flappy_jet_pro/game/systems/objective_tracker.dart';
import 'package:flappy_jet_pro/game/systems/level_reward_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Story Mode Integration Tests - Phase 1', () {
    late LevelSystemManager levelSystemManager;
    late ObjectiveTracker objectiveTracker;
    late LevelRewardManager rewardManager;
    late InventoryManager inventoryManager;

    setUp(() async {
      // Initialize managers
      levelSystemManager = LevelSystemManager();
      objectiveTracker = ObjectiveTracker();
      rewardManager = LevelRewardManager();
      inventoryManager = InventoryManager();

      // Initialize systems
      await levelSystemManager.initialize();
      await inventoryManager.initialize();
    });

    tearDown(() {
      // Clean up
      objectiveTracker.reset();
    });

    test('1. Level System Manager loads correctly', () {
      expect(levelSystemManager.isInitialized, true);
      expect(levelSystemManager.allLevels.isNotEmpty, true);
      expect(levelSystemManager.allZones.isNotEmpty, true);
      expect(levelSystemManager.currentLevel, 1);
      expect(levelSystemManager.highestLevelUnlocked, 1);
    });

    test('2. First level is unlocked, others are locked', () {
      expect(levelSystemManager.isLevelUnlocked(1), true);
      expect(levelSystemManager.isLevelUnlocked(2), false);
      expect(levelSystemManager.isLevelUnlocked(10), false);
    });

    test('3. Level data is loaded correctly', () {
      final level1 = levelSystemManager.getLevelById(1);
      expect(level1, isNotNull);
      expect(level1!.id, 1);
      expect(level1.zone, 1);
      expect(level1.name, isNotEmpty);
      expect(level1.objective, isNotNull);
      expect(level1.difficulty, isNotNull);
      expect(level1.reward, isNotNull);
    });

    test('4. Zone data is loaded correctly', () {
      final zone1 = levelSystemManager.getZoneById(1);
      expect(zone1, isNotNull);
      expect(zone1!.id, 1);
      expect(zone1.name, isNotEmpty);
      expect(zone1.description, isNotEmpty);
    });

    test('5. Complete level flow - Pass Obstacles objective', () async {
      final level1 = levelSystemManager.getLevelById(1);
      expect(level1, isNotNull);

      // Start tracking objective
      objectiveTracker.startTracking(level1!.objective);
      expect(objectiveTracker.isCompleted, false);
      expect(objectiveTracker.currentProgress, 0);

      // Simulate passing obstacles
      final targetObstacles = level1.objective.target;
      for (int i = 0; i < targetObstacles; i++) {
        objectiveTracker.incrementProgress();
        
        if (i < targetObstacles - 1) {
          expect(objectiveTracker.isCompleted, false);
        }
      }

      // Check completion
      expect(objectiveTracker.isCompleted, true);
      expect(objectiveTracker.currentProgress, targetObstacles);
    });

    test('6. Complete level flow - Reward granting', () async {
      final level1 = levelSystemManager.getLevelById(1);
      expect(level1, isNotNull);

      // Get initial inventory
      final initialCoins = inventoryManager.softCurrency;
      final initialGems = inventoryManager.gems;

      // Calculate and grant rewards
      final reward = rewardManager.calculateRewards(level1!);
      await rewardManager.grantRewards(
        levelId: level1.id,
        reward: reward,
      );

      // Verify rewards were granted
      expect(inventoryManager.softCurrency, initialCoins + reward.coins);
      if (reward.gems > 0) {
        expect(inventoryManager.gems, initialGems + reward.gems);
      }
    });

    test('7. Level completion unlocks next level', () async {
      expect(levelSystemManager.currentLevel, 1);
      expect(levelSystemManager.isLevelUnlocked(2), false);

      // Complete level 1
      final level1 = levelSystemManager.getLevelById(1);
      final reward = rewardManager.calculateRewards(level1!);
      await rewardManager.grantRewards(
        levelId: 1,
        reward: reward,
      );

      // Check that level 2 is now unlocked
      expect(levelSystemManager.currentLevel, 2);
      expect(levelSystemManager.highestLevelUnlocked, 2);
      expect(levelSystemManager.isLevelUnlocked(2), true);
      expect(levelSystemManager.isLevelCompleted(1), true);
    });

    test('8. Zone progress tracking', () {
      final zone1Progress = levelSystemManager.getZoneProgress(1);
      expect(zone1Progress, greaterThanOrEqualTo(0));
      expect(zone1Progress, lessThanOrEqualTo(100));
    });

    test('9. Objective tracker - Survive Time objective', () {
      final surviveObjective = LevelObjective(
        type: ObjectiveType.surviveTime,
        target: 30,
        description: 'Survive for 30 seconds',
      );

      objectiveTracker.startTracking(surviveObjective);
      expect(objectiveTracker.isCompleted, false);

      // Simulate time passing
      for (int i = 0; i < 30; i++) {
        objectiveTracker.updateTime(1.0); // 1 second per update
      }

      expect(objectiveTracker.isCompleted, true);
      expect(objectiveTracker.currentProgress, greaterThanOrEqualTo(30));
    });

    test('10. Bot battle objective tracking', () {
      final botObjective = LevelObjective(
        type: ObjectiveType.beatBot,
        target: 5,
        description: 'Beat the bot',
      );

      objectiveTracker.startTracking(botObjective);

      // Simulate player scoring
      objectiveTracker.updateBotBattleScore(playerScore: 3, botScore: 2);
      expect(objectiveTracker.isCompleted, false);

      // Player reaches target but bot is ahead
      objectiveTracker.updateBotBattleScore(playerScore: 5, botScore: 6);
      expect(objectiveTracker.isCompleted, false);

      // Player reaches target and beats bot
      objectiveTracker.updateBotBattleScore(playerScore: 6, botScore: 5);
      expect(objectiveTracker.isCompleted, true);
      expect(objectiveTracker.isPlayerWinning, true);
    });

    test('11. Reward calculation for bot victories', () {
      final level7 = levelSystemManager.getLevelById(7);
      expect(level7, isNotNull);
      expect(level7!.botBattle, isNotNull);

      // Normal reward
      final normalReward = rewardManager.calculateRewards(level7, botVictory: false);
      expect(normalReward.coins, level7.reward.coins);

      // Bot victory doubles coins
      final victoryReward = rewardManager.calculateRewards(level7, botVictory: true);
      expect(victoryReward.coins, level7.reward.coins * 2);
    });

    test('12. Zone 1 has 10 levels', () {
      final zone1Levels = levelSystemManager.getLevelsByZone(1);
      expect(zone1Levels.length, 10);
      
      // Verify all levels have unique IDs
      final ids = zone1Levels.map((l) => l.id).toSet();
      expect(ids.length, 10);
    });

    test('13. Level 10 has bonus gem reward', () {
      final level10 = levelSystemManager.getLevelById(10);
      expect(level10, isNotNull);
      expect(level10!.reward.gems, greaterThan(0));
    });

    test('14. Overall progress calculation', () {
      final progress = levelSystemManager.overallProgress;
      expect(progress, greaterThanOrEqualTo(0));
      expect(progress, lessThanOrEqualTo(100));
    });

    test('15. Complete multiple levels in sequence', () async {
      // Complete levels 1-3
      for (int i = 1; i <= 3; i++) {
        expect(levelSystemManager.isLevelUnlocked(i), true);
        
        final level = levelSystemManager.getLevelById(i);
        final reward = rewardManager.calculateRewards(level!);
        await rewardManager.grantRewards(
          levelId: i,
          reward: reward,
        );
        
        expect(levelSystemManager.isLevelCompleted(i), true);
      }

      // Verify state
      expect(levelSystemManager.totalLevelsCompleted, 3);
      expect(levelSystemManager.currentLevel, 4);
      expect(levelSystemManager.highestLevelUnlocked, 4);
    });

    test('16. Failed level does not unlock next level', () {
      // Simulate attempting level 1 but not completing objective
      final level1 = levelSystemManager.getLevelById(1);
      objectiveTracker.startTracking(level1!.objective);
      
      // Only pass 2 obstacles (not enough)
      objectiveTracker.incrementProgress();
      objectiveTracker.incrementProgress();
      
      // Check objective is not completed
      expect(objectiveTracker.isCompleted, false);
      expect(objectiveTracker.checkFinalCompletion(), false);
      
      // Level 2 should still be locked
      expect(levelSystemManager.isLevelUnlocked(2), false);
    });

    test('17. Replaying completed level', () async {
      // Complete level 1
      final level1 = levelSystemManager.getLevelById(1);
      final reward = rewardManager.calculateRewards(level1!);
      await rewardManager.grantRewards(
        levelId: 1,
        reward: reward,
      );

      expect(levelSystemManager.isLevelCompleted(1), true);
      expect(levelSystemManager.isLevelUnlocked(1), true);

      // Can still access level 1 for replay
      final level1Again = levelSystemManager.getLevelById(1);
      expect(level1Again, isNotNull);
    });

    test('18. Statistics tracking', () {
      expect(levelSystemManager.totalCoinsEarned, greaterThanOrEqualTo(0));
      expect(levelSystemManager.totalGemsEarned, greaterThanOrEqualTo(0));
      expect(levelSystemManager.botBattlesWon, greaterThanOrEqualTo(0));
      expect(levelSystemManager.botBattlesLost, greaterThanOrEqualTo(0));
    });

    test('19. Objective progress descriptions', () {
      final level1 = levelSystemManager.getLevelById(1);
      objectiveTracker.startTracking(level1!.objective);
      
      // Before any progress
      final beforeDesc = objectiveTracker.getProgressDescription();
      expect(beforeDesc, isNotEmpty);
      
      // After some progress
      objectiveTracker.incrementProgress();
      final afterDesc = objectiveTracker.getProgressDescription();
      expect(afterDesc, isNotEmpty);
      expect(afterDesc, isNot(beforeDesc));
    });

    test('20. Complete Phase 1 integration flow', () async {
      // Simulate a complete level play session
      
      // 1. Select level
      final level = levelSystemManager.getLevelById(1);
      expect(level, isNotNull);
      expect(levelSystemManager.isLevelUnlocked(1), true);
      
      // 2. Start tracking objective
      objectiveTracker.startTracking(level!.objective);
      expect(objectiveTracker.isCompleted, false);
      
      // 3. Play and complete objective
      for (int i = 0; i < level.objective.target; i++) {
        objectiveTracker.incrementProgress();
      }
      expect(objectiveTracker.isCompleted, true);
      
      // 4. Grant rewards
      final initialCoins = inventoryManager.softCurrency;
      final reward = rewardManager.calculateRewards(level);
      await rewardManager.grantRewards(
        levelId: level.id,
        reward: reward,
      );
      
      // 5. Verify completion state
      expect(levelSystemManager.isLevelCompleted(1), true);
      expect(levelSystemManager.currentLevel, 2);
      expect(inventoryManager.softCurrency, initialCoins + reward.coins);
      
      // 6. Verify next level is unlocked
      expect(levelSystemManager.isLevelUnlocked(2), true);
    });
  });
}

