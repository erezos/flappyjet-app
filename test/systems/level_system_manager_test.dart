/// 🧪 UNIT TESTS - Level System Manager (Story Mode Navigation)
/// 
/// Tests for zone navigation, level replay detection, zone completion,
/// and all related story mode progression logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/level_system_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelSystemManager - Zone Navigation', () {
    late LevelSystemManager manager;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should initialize with Zone 1 unlocked', () {
      final unlockedZones = manager.getUnlockedZones();
      expect(unlockedZones.contains(1), true);
      expect(manager.currentZone, 1);
    });

    test('should start at level 1 of Zone 1', () {
      expect(manager.currentLevel, 1);
      expect(manager.currentZone, 1);
    });

    test('should get correct zone data', () {
      final zone1 = manager.getZoneById(1);
      expect(zone1, isNotNull);
      expect(zone1?.id, 1);
      expect(zone1?.name, 'Tropical Islands'); // Actual zone name from zones.json
    });

    test('should get levels by zone', () {
      final zone1Levels = manager.getLevelsByZone(1);
      expect(zone1Levels, isNotEmpty);
      expect(zone1Levels.length, 10); // Zone 1 has 10 levels
      expect(zone1Levels.first.zone, 1);
      expect(zone1Levels.last.zone, 1);
    });

    test('should switch to unlocked zone', () async {
      // Zone 1 is always unlocked
      await manager.setCurrentZone(1);
      expect(manager.currentZone, 1);
    });

    test('should not switch to locked zone', () async {
      final initialZone = manager.currentZone;
      
      // Try to switch to Zone 2 (locked initially)
      await manager.setCurrentZone(2);
      
      // Should stay in initial zone
      expect(manager.currentZone, initialZone);
    });

    test('should calculate zone progress correctly', () {
      final progress = manager.getZoneProgress(1);
      expect(progress, 0.0); // No levels completed initially
    });

    test('should unlock Zone 2 after completing Zone 1', () async {
      // Complete all levels in Zone 1
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      // Zone 2 should now be unlocked
      final unlockedZones = manager.getUnlockedZones();
      expect(unlockedZones.contains(2), true);
    });

    test('should auto-advance to next zone after completing current zone', () async {
      // Complete all levels in Zone 1
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      // Should auto-advance to Zone 2
      expect(manager.currentZone, 2);
      expect(manager.currentLevel, 11); // First level of Zone 2
    });

    test('should set current level to first incomplete when switching zones', () async {
      // Complete Zone 1
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      // Now in Zone 2, complete first 3 levels
      await manager.completeLevel(levelId: 11, coinsEarned: 20, gemsEarned: 0);
      await manager.completeLevel(levelId: 12, coinsEarned: 20, gemsEarned: 0);
      await manager.completeLevel(levelId: 13, coinsEarned: 20, gemsEarned: 0);

      // Switch back to Zone 1 (all completed)
      await manager.setCurrentZone(1);
      expect(manager.currentLevel, 1); // First level (or last if all completed)

      // Switch to Zone 2
      await manager.setCurrentZone(2);
      expect(manager.currentLevel, 14); // First incomplete level in Zone 2
    });
  });

  group('LevelSystemManager - Level Replay', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should detect uncompleted level as not replay', () {
      expect(manager.isLevelReplay(1), false);
    });

    test('should detect completed level as replay', () async {
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      expect(manager.isLevelReplay(1), true);
    });

    test('should track completed levels', () async {
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );
      await manager.completeLevel(
        levelId: 2,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      expect(manager.isLevelCompleted(1), true);
      expect(manager.isLevelCompleted(2), true);
      expect(manager.isLevelCompleted(3), false);
    });

    test('should calculate zone progress after completing levels', () async {
      // Complete 5 out of 10 levels in Zone 1
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(
          levelId: i,
          coinsEarned: 20,
          gemsEarned: 0,
        );
      }

      final progress = manager.getZoneProgress(1);
      expect(progress, 50.0); // 5/10 = 50%
    });
  });

  group('LevelSystemManager - Zone Completion', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should detect zone not completed initially', () {
      expect(manager.isZoneCompleted(1), false);
    });

    test('should detect zone completed after all levels done', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      expect(manager.isZoneCompleted(1), true);
    });

    test('should detect when zone was just completed', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      
      // Complete all but last level
      for (int i = 0; i < zone1Levels.length - 1; i++) {
        await manager.completeLevel(
          levelId: zone1Levels[i].id,
          coinsEarned: zone1Levels[i].reward.coins,
          gemsEarned: zone1Levels[i].reward.gems,
        );
      }

      // Not just completed yet
      final lastLevel = zone1Levels.last;
      expect(manager.wasZoneJustCompleted(lastLevel.id), false);

      // Complete last level
      await manager.completeLevel(
        levelId: lastLevel.id,
        coinsEarned: lastLevel.reward.coins,
        gemsEarned: lastLevel.reward.gems,
      );

      // Should detect zone was just completed
      expect(manager.wasZoneJustCompleted(lastLevel.id), true);
    });

    test('should not detect zone just completed for non-last level', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      
      // Complete all levels
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      // Check with first level (not last)
      expect(manager.wasZoneJustCompleted(zone1Levels.first.id), false);
    });

    test('should calculate zone stats correctly', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      
      // Complete all levels in Zone 1
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      final stats = manager.getZoneStats(1);
      
      // Zone 1 total: 10 levels * 20 coins = 200 coins, 10 gems at level 10
      expect(stats['coins'], greaterThan(0));
      expect(stats['gems'], greaterThanOrEqualTo(0));
      
      // Check bot battles (Zone 1 has 1 bot battle at level 7)
      expect(stats['botWins'], 1);
    });

    test('should track zone completion in set', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      expect(manager.completedZones.contains(1), true);
    });
  });

  group('LevelSystemManager - Level Unlocking', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should start with only level 1 unlocked', () {
      expect(manager.isLevelUnlocked(1), true);
      expect(manager.isLevelUnlocked(2), false);
      expect(manager.highestLevelUnlocked, 1);
    });

    test('should unlock next level after completing current', () async {
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      expect(manager.isLevelUnlocked(2), true);
      expect(manager.highestLevelUnlocked, 2);
      expect(manager.currentLevel, 2);
    });

    test('should unlock levels sequentially', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(
          levelId: i,
          coinsEarned: 20,
          gemsEarned: 0,
        );
        expect(manager.isLevelUnlocked(i + 1), true);
        expect(manager.highestLevelUnlocked, i + 1);
      }
    });
  });

  group('LevelSystemManager - Bot Battles', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should track bot battle wins', () async {
      await manager.completeLevel(
        levelId: 7, // Zone 1 bot battle
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: true,
      );

      expect(manager.botBattlesWon, 1);
      expect(manager.botBattlesLost, 0);
    });

    test('should track bot battle losses', () async {
      await manager.completeLevel(
        levelId: 7,
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: false,
      );

      expect(manager.botBattlesWon, 0);
      expect(manager.botBattlesLost, 1);
    });

    test('should track multiple bot battles', () async {
      // Zone 1 bot battle - win
      await manager.completeLevel(
        levelId: 7,
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: true,
      );

      // Complete levels to unlock Zone 2
      for (int i = 8; i <= 10; i++) {
        await manager.completeLevel(
          levelId: i,
          coinsEarned: 20,
          gemsEarned: 0,
        );
      }

      // Zone 2 bot battle - loss
      await manager.completeLevel(
        levelId: 14,
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: false,
      );

      expect(manager.botBattlesWon, 1);
      expect(manager.botBattlesLost, 1);
    });
  });

  group('LevelSystemManager - Persistence', () {
    test('should persist and restore progress', () async {
      // Create first instance and make progress
      SharedPreferences.setMockInitialValues({});
      final manager1 = LevelSystemManager();
      await manager1.initialize();

      await manager1.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );
      await manager1.completeLevel(
        levelId: 2,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      // Get the saved data
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getKeys();
      expect(savedData, isNotEmpty);

      // Create new instance (simulating app restart)
      final manager2 = LevelSystemManager();
      await manager2.initialize();

      // Progress should be restored
      expect(manager2.isLevelCompleted(1), true);
      expect(manager2.isLevelCompleted(2), true);
      expect(manager2.currentLevel, 3);
      expect(manager2.highestLevelUnlocked, 3);
    });

    test('should persist zone completion', () async {
      SharedPreferences.setMockInitialValues({});
      final manager1 = LevelSystemManager();
      await manager1.initialize();

      // Complete all Zone 1 levels
      final zone1Levels = manager1.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager1.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }

      // Create new instance
      final manager2 = LevelSystemManager();
      await manager2.initialize();

      // Zone completion should be restored
      expect(manager2.isZoneCompleted(1), true);
      expect(manager2.currentZone, 2); // Auto-advanced
    });
  });

  group('LevelSystemManager - Edge Cases', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should handle invalid zone ID gracefully', () {
      final invalidZone = manager.getZoneById(999);
      expect(invalidZone, isNull);
    });

    test('should handle invalid level ID gracefully', () {
      final invalidLevel = manager.getLevelById(999);
      expect(invalidLevel, isNull);
    });

    test('should return empty list for invalid zone', () {
      final levels = manager.getLevelsByZone(999);
      expect(levels, isEmpty);
    });

    test('should handle completing already completed level', () async {
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      final initialCompletedCount = manager.totalLevelsCompleted;

      // Complete again
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      // Should not double-count
      expect(manager.totalLevelsCompleted, initialCompletedCount);
    });

    test('should return 0 progress for empty zone', () {
      final progress = manager.getZoneProgress(999);
      expect(progress, 0.0);
    });
  });

  group('LevelSystemManager - Statistics', () {
    late LevelSystemManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = LevelSystemManager();
      await manager.initialize();
    });

    test('should track total coins earned', () async {
      await manager.completeLevel(
        levelId: 1,
        coinsEarned: 20,
        gemsEarned: 0,
      );
      await manager.completeLevel(
        levelId: 2,
        coinsEarned: 20,
        gemsEarned: 0,
      );

      expect(manager.totalCoinsEarned, 40);
    });

    test('should track total gems earned', () async {
      await manager.completeLevel(
        levelId: 10,
        coinsEarned: 20,
        gemsEarned: 10, // Level 10 gives gems
      );

      expect(manager.totalGemsEarned, 10);
    });

    test('should track total levels completed', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(
          levelId: i,
          coinsEarned: 20,
          gemsEarned: 0,
        );
      }

      expect(manager.totalLevelsCompleted, 5);
    });

    test('should calculate overall progress', () async {
      // Complete 5 out of 50 total levels (assuming 5 zones * 10 levels)
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(
          levelId: i,
          coinsEarned: 20,
          gemsEarned: 0,
        );
      }

      final progress = manager.overallProgress;
      expect(progress, closeTo(10.0, 0.1)); // 5/50 = 10%
    });
  });
}

