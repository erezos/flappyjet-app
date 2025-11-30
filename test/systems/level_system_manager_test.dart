/// 🧪 UNIT TESTS - Level System Manager (Story Mode Navigation)
/// 
/// Tests for zone navigation, level replay detection, zone completion,
/// and all related story mode progression logic.
/// 
/// ⚠️ NOTE: LevelSystemManager is a SINGLETON. Tests must use resetProgress()
/// to clean state between tests. The singleton can only be initialized once.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/game/systems/level_system_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Single instance used by all tests (it's a singleton anyway)
  late LevelSystemManager manager;
  
  // Initialize the singleton ONCE before all tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    manager = LevelSystemManager();
    await manager.initialize();
  });
  
  // Reset progress after each test to ensure clean state
  tearDown(() async {
    await manager.resetProgress();
  });

  group('LevelSystemManager - Zone Navigation', () {
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
      expect(zone1?.name, 'Tropical Islands');
    });

    test('should get levels by zone', () {
      final zone1Levels = manager.getLevelsByZone(1);
      expect(zone1Levels, isNotEmpty);
      expect(zone1Levels.length, 10);
      expect(zone1Levels.first.zone, 1);
      expect(zone1Levels.last.zone, 1);
    });

    test('should switch to unlocked zone', () async {
      await manager.setCurrentZone(1);
      expect(manager.currentZone, 1);
    });

    test('should not switch to locked zone', () async {
      final initialZone = manager.currentZone;
      await manager.setCurrentZone(2);
      expect(manager.currentZone, initialZone);
    });

    test('should calculate zone progress correctly', () {
      final progress = manager.getZoneProgress(1);
      expect(progress, 0.0);
    });

    test('should unlock Zone 2 after completing Zone 1', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }
      final unlockedZones = manager.getUnlockedZones();
      expect(unlockedZones.contains(2), true);
    });

    test('should auto-advance to next zone after completing current zone', () async {
      final zone1Levels = manager.getLevelsByZone(1);
      for (final level in zone1Levels) {
        await manager.completeLevel(
          levelId: level.id,
          coinsEarned: level.reward.coins,
          gemsEarned: level.reward.gems,
        );
      }
      expect(manager.currentZone, 2);
      expect(manager.currentLevel, 11);
    });
  });

  group('LevelSystemManager - Level Replay', () {
    test('should detect uncompleted level as not replay', () {
      expect(manager.isLevelReplay(1), false);
    });

    test('should detect completed level as replay', () async {
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      expect(manager.isLevelReplay(1), true);
    });

    test('should track completed levels', () async {
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      await manager.completeLevel(levelId: 2, coinsEarned: 20, gemsEarned: 0);
      expect(manager.isLevelCompleted(1), true);
      expect(manager.isLevelCompleted(2), true);
      expect(manager.isLevelCompleted(3), false);
    });

    test('should calculate zone progress after completing levels', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
      }
      final progress = manager.getZoneProgress(1);
      expect(progress, 50.0);
    });
  });

  group('LevelSystemManager - Zone Completion', () {
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
      for (int i = 0; i < zone1Levels.length - 1; i++) {
        await manager.completeLevel(
          levelId: zone1Levels[i].id,
          coinsEarned: zone1Levels[i].reward.coins,
          gemsEarned: zone1Levels[i].reward.gems,
        );
      }
      final lastLevel = zone1Levels.last;
      expect(manager.wasZoneJustCompleted(lastLevel.id), false);
      await manager.completeLevel(
        levelId: lastLevel.id,
        coinsEarned: lastLevel.reward.coins,
        gemsEarned: lastLevel.reward.gems,
      );
      expect(manager.wasZoneJustCompleted(lastLevel.id), true);
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
    test('should start with only level 1 unlocked', () {
      expect(manager.isLevelUnlocked(1), true);
      expect(manager.isLevelUnlocked(2), false);
      expect(manager.highestLevelUnlocked, 1);
    });

    test('should unlock next level after completing current', () async {
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      expect(manager.isLevelUnlocked(2), true);
      expect(manager.highestLevelUnlocked, 2);
      expect(manager.currentLevel, 2);
    });

    test('should unlock levels sequentially', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
        expect(manager.isLevelUnlocked(i + 1), true);
        expect(manager.highestLevelUnlocked, i + 1);
      }
    });
  });

  group('LevelSystemManager - Bot Battles', () {
    test('should track bot battle wins', () async {
      // Complete levels 1-6 first to unlock level 7
      for (int i = 1; i <= 6; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
      }
      await manager.completeLevel(
        levelId: 7,
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: true,
      );
      expect(manager.botBattlesWon, 1);
      expect(manager.botBattlesLost, 0);
    });

    test('should track bot battle losses', () async {
      // Complete levels 1-6 first to unlock level 7
      for (int i = 1; i <= 6; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
      }
      await manager.completeLevel(
        levelId: 7,
        coinsEarned: 20,
        gemsEarned: 0,
        botDefeated: false,
      );
      expect(manager.botBattlesWon, 0);
      expect(manager.botBattlesLost, 1);
    });
  });

  group('LevelSystemManager - Edge Cases', () {
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
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      final initialCompletedCount = manager.totalLevelsCompleted;
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      expect(manager.totalLevelsCompleted, initialCompletedCount);
    });

    test('should return 0 progress for empty zone', () {
      final progress = manager.getZoneProgress(999);
      expect(progress, 0.0);
    });
  });

  group('LevelSystemManager - Statistics', () {
    test('should track total coins earned', () async {
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 0);
      await manager.completeLevel(levelId: 2, coinsEarned: 20, gemsEarned: 0);
      expect(manager.totalCoinsEarned, 40);
    });

    test('should track total gems earned', () async {
      await manager.completeLevel(levelId: 1, coinsEarned: 20, gemsEarned: 10);
      expect(manager.totalGemsEarned, 10);
    });

    test('should track total levels completed', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
      }
      expect(manager.totalLevelsCompleted, 5);
    });

    test('should calculate overall progress', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.completeLevel(levelId: i, coinsEarned: 20, gemsEarned: 0);
      }
      final progress = manager.overallProgress;
      // 5 levels completed out of total levels (50 levels = 5 zones * 10)
      expect(progress, closeTo(10.0, 0.5));
    });
  });
  
  // Persistence tests are skipped because singleton can't be re-initialized
  group('LevelSystemManager - Persistence', () {
    test('persistence is handled by LevelProgressRepository', () {
      // Note: Persistence tests are skipped because the singleton pattern
      // prevents re-initialization. The actual persistence is tested
      // through integration tests with LevelProgressRepository.
      expect(manager.isInitialized, true);
    });
  }, skip: 'Singleton cannot be re-initialized for persistence tests');
}
