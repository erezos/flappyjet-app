import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';

/// 🎯 SMART MISSION ADAPTATION TESTS
/// 
/// These tests verify the new smart mission adaptation features:
/// - Smart play target based on player's daily activity
/// - Level-based missions for story mode players
/// - Bonus collection missions
/// - New mission types: completeLevel, completeZone, collectBonuses
/// 
/// WHY: Smart adaptation increases engagement by giving players
/// achievable but challenging missions based on their actual behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerStats Smart Play Target', () {
    test('smartPlayTarget returns skill-based target for new players', () {
      // New player with no history
      final stats = PlayerStats(
        bestScore: 5,
        bestStreak: 2,
        totalGamesPlayed: 3,
        totalContinuesUsed: 0,
        averageScore: 4,
        gamesPlayedToday: 0,
        gamesPlayedYesterday: 0,
        averageDailyGames: 0,
        highestLevelCompleted: 0,
        totalLevelsCompleted: 0,
        totalBonusesCollected: 0,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: false,
      );
      
      // Should fall back to skill-based (beginner = 3)
      expect(stats.smartPlayTarget, equals(3));
    });

    test('smartPlayTarget adapts to high activity players', () {
      // Active player who played 8 games yesterday
      final stats = PlayerStats(
        bestScore: 25,
        bestStreak: 5,
        totalGamesPlayed: 100,
        totalContinuesUsed: 10,
        averageScore: 15,
        gamesPlayedToday: 0,
        gamesPlayedYesterday: 8, // High activity yesterday
        averageDailyGames: 5,
        highestLevelCompleted: 10,
        totalLevelsCompleted: 10,
        totalBonusesCollected: 50,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: true,
      );
      
      // Should use yesterday's activity * 1.1 = 8.8 rounded = 9
      expect(stats.smartPlayTarget, equals(9));
    });

    test('smartPlayTarget uses average for consistent players', () {
      // Consistent player with good average but low yesterday
      final stats = PlayerStats(
        bestScore: 30,
        bestStreak: 4,
        totalGamesPlayed: 50,
        totalContinuesUsed: 5,
        averageScore: 20,
        gamesPlayedToday: 0,
        gamesPlayedYesterday: 2, // Low yesterday
        averageDailyGames: 6, // Good average
        highestLevelCompleted: 15,
        totalLevelsCompleted: 15,
        totalBonusesCollected: 75,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: true,
      );
      
      // Should use average * 1.2 = 7.2 rounded = 7
      expect(stats.smartPlayTarget, equals(7));
    });

    test('smartPlayTarget clamps to maximum value', () {
      // Very active player
      final stats = PlayerStats(
        bestScore: 100,
        bestStreak: 10,
        totalGamesPlayed: 500,
        totalContinuesUsed: 50,
        averageScore: 60,
        gamesPlayedToday: 0,
        gamesPlayedYesterday: 20, // Very high activity
        averageDailyGames: 15,
        highestLevelCompleted: 30,
        totalLevelsCompleted: 30,
        totalBonusesCollected: 300,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: true,
      );
      
      // Should be clamped to 15 (max)
      expect(stats.smartPlayTarget, lessThanOrEqualTo(15));
    });

    test('smartPlayTarget clamps to minimum value', () {
      // Any player should have at least minimum target
      final stats = PlayerStats(
        bestScore: 0,
        bestStreak: 0,
        totalGamesPlayed: 0,
        totalContinuesUsed: 0,
        averageScore: 0,
        gamesPlayedToday: 0,
        gamesPlayedYesterday: 0,
        averageDailyGames: 0,
        highestLevelCompleted: 0,
        totalLevelsCompleted: 0,
        totalBonusesCollected: 0,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: false,
      );
      
      // Should be at least 3 (beginner minimum)
      expect(stats.smartPlayTarget, greaterThanOrEqualTo(3));
    });
  });

  group('PlayerStats Skill Level', () {
    test('skillLevel returns beginner for low scores', () {
      final stats = PlayerStats(
        bestScore: 5,
        bestStreak: 1,
        totalGamesPlayed: 5,
        totalContinuesUsed: 0,
        averageScore: 3,
        gamesPlayedToday: 0,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: false,
      );
      
      expect(stats.skillLevel, equals(PlayerSkillLevel.beginner));
    });

    test('skillLevel returns expert for high scores', () {
      final stats = PlayerStats(
        bestScore: 150,
        bestStreak: 10,
        totalGamesPlayed: 500,
        totalContinuesUsed: 50,
        averageScore: 80,
        gamesPlayedToday: 5,
        lastPlayedDate: DateTime.now(),
        hasChangedNickname: true,
      );
      
      expect(stats.skillLevel, equals(PlayerSkillLevel.expert));
    });

    test('skillLevel transitions correctly through levels', () {
      // Test each boundary
      expect(
        PlayerStats(bestScore: 9, bestStreak: 0, totalGamesPlayed: 0, 
          totalContinuesUsed: 0, averageScore: 0, gamesPlayedToday: 0,
          lastPlayedDate: DateTime.now(), hasChangedNickname: false).skillLevel,
        equals(PlayerSkillLevel.beginner),
      );
      
      expect(
        PlayerStats(bestScore: 10, bestStreak: 0, totalGamesPlayed: 0,
          totalContinuesUsed: 0, averageScore: 0, gamesPlayedToday: 0,
          lastPlayedDate: DateTime.now(), hasChangedNickname: false).skillLevel,
        equals(PlayerSkillLevel.novice),
      );
      
      expect(
        PlayerStats(bestScore: 25, bestStreak: 0, totalGamesPlayed: 0,
          totalContinuesUsed: 0, averageScore: 0, gamesPlayedToday: 0,
          lastPlayedDate: DateTime.now(), hasChangedNickname: false).skillLevel,
        equals(PlayerSkillLevel.intermediate),
      );
      
      expect(
        PlayerStats(bestScore: 50, bestStreak: 0, totalGamesPlayed: 0,
          totalContinuesUsed: 0, averageScore: 0, gamesPlayedToday: 0,
          lastPlayedDate: DateTime.now(), hasChangedNickname: false).skillLevel,
        equals(PlayerSkillLevel.advanced),
      );
      
      expect(
        PlayerStats(bestScore: 100, bestStreak: 0, totalGamesPlayed: 0,
          totalContinuesUsed: 0, averageScore: 0, gamesPlayedToday: 0,
          lastPlayedDate: DateTime.now(), hasChangedNickname: false).skillLevel,
        equals(PlayerSkillLevel.expert),
      );
    });
  });

  group('MissionType enum', () {
    test('contains all expected mission types', () {
      expect(MissionType.values, contains(MissionType.playGames));
      expect(MissionType.values, contains(MissionType.maintainStreak));
      expect(MissionType.values, contains(MissionType.useContinue));
      expect(MissionType.values, contains(MissionType.collectCoins));
      expect(MissionType.values, contains(MissionType.surviveTime));
      expect(MissionType.values, contains(MissionType.shareScore));
      expect(MissionType.values, contains(MissionType.completeLevel));
      expect(MissionType.values, contains(MissionType.completeZone));
      expect(MissionType.values, contains(MissionType.collectBonuses));
    });

    test('does not contain removed reachScore type', () {
      // reachScore was removed since endless mode is deprecated
      final hasReachScore = MissionType.values.any((t) => t.name == 'reachScore');
      expect(hasReachScore, isFalse);
    });
  });

  group('MissionsManager New Mission Types', () {
    late MissionsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = MissionsManager();
      manager.resetForTesting();
      await manager.initialize();
    });

    test('can update progress for completeLevel mission type', () async {
      // Should not throw
      await manager.updateMissionProgress(MissionType.completeLevel, 1);
      expect(true, isTrue); // If we get here, no exception was thrown
    });

    test('can update progress for completeZone mission type', () async {
      // Should not throw
      await manager.updateMissionProgress(MissionType.completeZone, 1);
      expect(true, isTrue);
    });

    test('can update progress for collectBonuses mission type', () async {
      // Should not throw
      await manager.updateMissionProgress(MissionType.collectBonuses, 1);
      expect(true, isTrue);
    });

    test('generates missions on initialization', () {
      // After initialization, should have missions
      expect(manager.dailyMissions, isNotEmpty);
      expect(manager.dailyMissions.length, greaterThanOrEqualTo(3));
    });

    test('generated missions have valid types', () {
      for (final mission in manager.dailyMissions) {
        expect(MissionType.values, contains(mission.type));
        // Verify reachScore is not generated
        expect(mission.type.name, isNot(equals('reachScore')));
      }
    });

    test('generated missions have positive targets and rewards', () {
      for (final mission in manager.dailyMissions) {
        expect(mission.target, greaterThan(0));
        expect(mission.reward, greaterThan(0));
      }
    });
  });

  group('Mission JSON Serialization', () {
    test('Mission can be serialized and deserialized', () {
      final mission = Mission(
        id: 'test_mission_1',
        type: MissionType.completeLevel,
        difficulty: MissionDifficulty.medium,
        title: 'Level Up',
        description: 'Complete Level 5 in Story Mode',
        target: 5,
        reward: 175,
        progress: 3,
        completed: false,
        claimed: false,
        createdAt: DateTime.now(),
      );

      final json = mission.toJson();
      final restored = Mission.fromJson(json);

      expect(restored.id, equals(mission.id));
      expect(restored.type, equals(mission.type));
      expect(restored.difficulty, equals(mission.difficulty));
      expect(restored.title, equals(mission.title));
      expect(restored.description, equals(mission.description));
      expect(restored.target, equals(mission.target));
      expect(restored.reward, equals(mission.reward));
      expect(restored.progress, equals(mission.progress));
      expect(restored.completed, equals(mission.completed));
      expect(restored.claimed, equals(mission.claimed));
    });

    test('All mission types can be serialized', () {
      for (final type in MissionType.values) {
        final mission = Mission(
          id: 'test_${type.name}',
          type: type,
          difficulty: MissionDifficulty.easy,
          title: 'Test',
          description: 'Test description',
          target: 1,
          reward: 100,
          createdAt: DateTime.now(),
        );

        final json = mission.toJson();
        final restored = Mission.fromJson(json);

        expect(restored.type, equals(type));
      }
    });
  });

  group('Duplicate Mission Prevention', () {
    test('Generated missions should have unique types', () async {
      // Setup: Player with NO story mode progress (highestLevelCompleted = 0)
      // This was the bug case: Mission 2 = collectBonuses, Mission 4 could also = collectBonuses
      SharedPreferences.setMockInitialValues({
        'stats_best_score': 10,
        'stats_best_streak': 3,
        'stats_total_games': 20,
        'stats_total_continues': 5,
        'stats_avg_score': 8,
        'stats_games_today': 0,
        'stats_games_yesterday': 5,
        'stats_avg_daily_games': 4,
        'stats_highest_level_completed': 0, // KEY: No story progress!
        'stats_total_levels_completed': 0,
        'stats_total_bonuses_collected': 10,
      });

      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;

      // Extract mission types
      final missionTypes = missions.map((m) => m.type).toList();
      final uniqueTypes = missionTypes.toSet();

      // Verify all missions have unique types (no duplicates)
      expect(
        uniqueTypes.length, 
        equals(missionTypes.length),
        reason: 'Each mission should have a unique type. Found: $missionTypes',
      );
    });

    test('Generated missions should have unique types for story mode players', () async {
      // Setup: Player with story mode progress
      SharedPreferences.setMockInitialValues({
        'stats_best_score': 25,
        'stats_best_streak': 8,
        'stats_total_games': 50,
        'stats_total_continues': 10,
        'stats_avg_score': 15,
        'stats_games_today': 0,
        'stats_games_yesterday': 6,
        'stats_avg_daily_games': 5,
        'stats_highest_level_completed': 10, // Has story progress
        'stats_total_levels_completed': 10,
        'stats_total_bonuses_collected': 30,
      });

      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;

      // Extract mission types
      final missionTypes = missions.map((m) => m.type).toList();
      final uniqueTypes = missionTypes.toSet();

      // Verify all missions have unique types (no duplicates)
      expect(
        uniqueTypes.length, 
        equals(missionTypes.length),
        reason: 'Each mission should have a unique type. Found: $missionTypes',
      );
    });

    test('collectBonuses should not appear twice', () async {
      // Run multiple times to catch randomness edge cases
      for (int i = 0; i < 10; i++) {
        SharedPreferences.setMockInitialValues({
          'stats_best_score': 10,
          'stats_best_streak': 3,
          'stats_total_games': 20,
          'stats_total_continues': 5,
          'stats_avg_score': 8,
          'stats_games_today': 0,
          'stats_games_yesterday': 5,
          'stats_avg_daily_games': 4,
          'stats_highest_level_completed': 0, // No story progress - bug trigger
          'stats_total_levels_completed': 0,
          'stats_total_bonuses_collected': 10,
        });

        final manager = MissionsManager();
        await manager.initialize();

        final missions = manager.dailyMissions;
        final bonusMissions = missions.where((m) => m.type == MissionType.collectBonuses).toList();

        expect(
          bonusMissions.length, 
          lessThanOrEqualTo(1),
          reason: 'Should have at most 1 collectBonuses mission (iteration $i). Found: ${bonusMissions.length}',
        );
      }
    });
  });
}


