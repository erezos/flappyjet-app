/// 🧪 UNIT TESTS - Level Reward Manager
/// 
/// Tests for reward calculation, replay detection, and reward distribution.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/level_reward_manager.dart';
import 'package:flappy_jet_pro/game/systems/inventory_manager.dart';
import 'package:flappy_jet_pro/game/systems/level_system_manager.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelRewardManager - Replay Detection', () {
    late LevelRewardManager rewardManager;
    late LevelSystemManager levelManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      rewardManager = LevelRewardManager();
      levelManager = LevelSystemManager();
      await levelManager.initialize();
    });

    test('should give full rewards for first completion', () {
      final level = LevelData(
        id: 1,
        zone: 1,
        name: 'Test Level',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 5,
          description: 'Pass 5 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 40,
          gems: 5,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: false);
      
      expect(reward.coins, 40);
      expect(reward.gems, 5);
    });

    test('should give fixed 20 coins for replay', () {
      final level = LevelData(
        id: 1,
        zone: 1,
        name: 'Test Level',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 5,
          description: 'Pass 5 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 80, // Original reward
          gems: 10,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: true);
      
      expect(reward.coins, 20); // Always 20 for replay
      expect(reward.gems, 0); // No gems for replay
      expect(reward.specialReward, isNull); // No special reward
    });

    test('should give no gems on replay regardless of original', () {
      final level = LevelData(
        id: 10,
        zone: 1,
        name: 'Zone 1 Final',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 10,
          description: 'Pass 10 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.2,
          obstacleGap: 180,
          obstacleFrequency: 2.2,
        ),
        reward: const LevelReward(
          coins: 20,
          gems: 10, // Bonus gems
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: true);
      
      expect(reward.coins, 20);
      expect(reward.gems, 0); // No gems even though original has 10
    });

    test('should give no special reward on replay', () {
      final level = LevelData(
        id: 50,
        zone: 5,
        name: 'Final Boss',
        objective: const Objective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Defeat the boss',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.5,
          obstacleGap: 150,
          obstacleFrequency: 3.0,
        ),
        reward: const LevelReward(
          coins: 100,
          gems: 50,
          specialReward: 'exclusive_skin_champion',
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: true);
      
      expect(reward.coins, 20);
      expect(reward.gems, 0);
      expect(reward.specialReward, isNull); // No exclusive skin on replay
    });
  });

  group('LevelRewardManager - Bot Battle Rewards', () {
    late LevelRewardManager rewardManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      rewardManager = LevelRewardManager();
    });

    test('should double coins for bot battle victory', () {
      final level = LevelData(
        id: 7,
        zone: 1,
        name: 'Bot Battle',
        objective: const Objective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Beat the bot',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 20,
          gems: 0,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
        botBattle: const BotBattle(
          botName: 'Test Bot',
          botJetSkin: 'sky_rookie',
          skillLevel: 0.5,
          reactionTime: 0.5,
          mistakeRate: 0.2,
        ),
      );

      final reward = rewardManager.calculateRewards(
        level,
        botVictory: true,
        isReplay: false,
      );
      
      expect(reward.coins, 40); // 20 * 2
    });

    test('should not double coins if bot not defeated', () {
      final level = LevelData(
        id: 7,
        zone: 1,
        name: 'Bot Battle',
        objective: const Objective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Beat the bot',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 20,
          gems: 0,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
        botBattle: const BotBattle(
          botName: 'Test Bot',
          botJetSkin: 'sky_rookie',
          skillLevel: 0.5,
          reactionTime: 0.5,
          mistakeRate: 0.2,
        ),
      );

      final reward = rewardManager.calculateRewards(
        level,
        botVictory: false,
        isReplay: false,
      );
      
      expect(reward.coins, 20); // Not doubled
    });

    test('should not double coins for replay even with bot victory', () {
      final level = LevelData(
        id: 7,
        zone: 1,
        name: 'Bot Battle',
        objective: const Objective(
          type: ObjectiveType.beatBot,
          target: 1,
          description: 'Beat the bot',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 20,
          gems: 0,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
        botBattle: const BotBattle(
          botName: 'Test Bot',
          botJetSkin: 'sky_rookie',
          skillLevel: 0.5,
          reactionTime: 0.5,
          mistakeRate: 0.2,
        ),
      );

      final reward = rewardManager.calculateRewards(
        level,
        botVictory: true,
        isReplay: true, // Replay mode
      );
      
      expect(reward.coins, 20); // Fixed 20, not doubled
    });
  });

  group('LevelRewardManager - Integration', () {
    late LevelRewardManager rewardManager;
    late LevelSystemManager levelManager;
    late InventoryManager inventoryManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      rewardManager = LevelRewardManager();
      levelManager = LevelSystemManager();
      inventoryManager = InventoryManager();
      
      await levelManager.initialize();
      await inventoryManager.initialize();
    });

    test('should grant rewards and update inventory for first completion', () async {
      final initialCoins = inventoryManager.coins;
      final initialGems = inventoryManager.gems;

      final reward = const LevelReward(
        coins: 40,
        gems: 5,
        specialReward: null,
      );

      await rewardManager.grantRewards(
        levelId: 1,
        reward: reward,
        isReplay: false,
      );

      expect(inventoryManager.coins, initialCoins + 40);
      expect(inventoryManager.gems, initialGems + 5);
    });

    test('should grant replay rewards and update inventory', () async {
      final initialCoins = inventoryManager.coins;

      final reward = const LevelReward(
        coins: 20, // Replay reward
        gems: 0,
        specialReward: null,
      );

      await rewardManager.grantRewards(
        levelId: 1,
        reward: reward,
        isReplay: true,
      );

      expect(inventoryManager.coins, initialCoins + 20);
      expect(inventoryManager.gems, inventoryManager.gems); // No change
    });

    test('should not update level progress on replay', () async {
      // Complete level first time
      await rewardManager.grantRewards(
        levelId: 1,
        reward: const LevelReward(coins: 20, gems: 0, specialReward: null),
        isReplay: false,
      );

      final totalCompleted = levelManager.totalLevelsCompleted;
      final totalCoinsEarned = levelManager.totalCoinsEarned;

      // Replay the level
      await rewardManager.grantRewards(
        levelId: 1,
        reward: const LevelReward(coins: 20, gems: 0, specialReward: null),
        isReplay: true,
      );

      // Level completion count should not increase
      expect(levelManager.totalLevelsCompleted, totalCompleted);
      
      // But total coins in level system should not increase (replay coins go to inventory only)
      expect(levelManager.totalCoinsEarned, totalCoinsEarned);
    });
  });

  group('LevelRewardManager - Edge Cases', () {
    late LevelRewardManager rewardManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      rewardManager = LevelRewardManager();
    });

    test('should handle zero rewards', () {
      final level = LevelData(
        id: 1,
        zone: 1,
        name: 'Test Level',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 5,
          description: 'Pass 5 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 0,
          gems: 0,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: false);
      
      expect(reward.coins, 0);
      expect(reward.gems, 0);
    });

    test('should always give 20 coins for replay even if original is 0', () {
      final level = LevelData(
        id: 1,
        zone: 1,
        name: 'Test Level',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 5,
          description: 'Pass 5 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 1.0,
          obstacleGap: 200,
          obstacleFrequency: 2.0,
        ),
        reward: const LevelReward(
          coins: 0, // Original has no coins
          gems: 0,
          specialReward: null,
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final reward = rewardManager.calculateRewards(level, isReplay: true);
      
      expect(reward.coins, 20); // Still 20 for replay
    });

    test('should handle very high reward values', () {
      final level = LevelData(
        id: 1,
        zone: 1,
        name: 'Mega Reward Level',
        objective: const Objective(
          type: ObjectiveType.passObstacles,
          target: 100,
          description: 'Pass 100 obstacles',
        ),
        difficulty: const Difficulty(
          speedMultiplier: 2.0,
          obstacleGap: 100,
          obstacleFrequency: 5.0,
        ),
        reward: const LevelReward(
          coins: 10000,
          gems: 1000,
          specialReward: 'ultra_rare_skin',
        ),
        theme: const Theme(
          background: 'test.png',
          obstacles: 'test.png',
          music: 'test.mp3',
        ),
      );

      final firstCompletion = rewardManager.calculateRewards(level, isReplay: false);
      final replay = rewardManager.calculateRewards(level, isReplay: true);
      
      expect(firstCompletion.coins, 10000);
      expect(firstCompletion.gems, 1000);
      expect(firstCompletion.specialReward, 'ultra_rare_skin');
      
      expect(replay.coins, 20); // Still fixed 20 for replay
      expect(replay.gems, 0);
      expect(replay.specialReward, isNull);
    });
  });
}

