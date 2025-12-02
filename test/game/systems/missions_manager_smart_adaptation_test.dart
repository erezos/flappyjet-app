import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_jet_pro/game/systems/missions_manager.dart';
import 'package:flappy_jet_pro/game/systems/lives_manager.dart';

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

  /// Helper to reset all managers before each test
  Future<void> resetManagers() async {
    // Reset MissionsManager singleton
    MissionsManager().resetForTesting();
    
    // Reset LivesManager singleton and re-initialize with new prefs
    await LivesManager().forceResetToNewPlayer();
    await LivesManager().initialize();
  }

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
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 10,
        'lm_best_streak': 3,
        'stats_total_games': 20,
        'stats_total_continues': 5,
        'stats_total_score': 160,
        'stats_games_today': 0,
        'stats_games_yesterday': 5,
        'stats_avg_daily_games': 4,
        'stats_highest_level': 0,
        'stats_total_levels': 0,
        'stats_total_bonuses': 10,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;
      final missionTypes = missions.map((m) => m.type).toList();
      final uniqueTypes = missionTypes.toSet();

      expect(
        uniqueTypes.length, 
        equals(missionTypes.length),
        reason: 'Each mission should have a unique type. Found: $missionTypes',
      );
    });

    test('Generated missions should have unique types for story mode players', () async {
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 25,
        'lm_best_streak': 8,
        'stats_total_games': 50,
        'stats_total_continues': 10,
        'stats_total_score': 750,
        'stats_games_today': 0,
        'stats_games_yesterday': 6,
        'stats_avg_daily_games': 5,
        'stats_highest_level': 10,
        'stats_total_levels': 10,
        'stats_total_bonuses': 30,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;
      final missionTypes = missions.map((m) => m.type).toList();
      final uniqueTypes = missionTypes.toSet();

      expect(
        uniqueTypes.length, 
        equals(missionTypes.length),
        reason: 'Each mission should have a unique type. Found: $missionTypes',
      );
    });

    test('collectBonuses should not appear twice', () async {
      for (int i = 0; i < 10; i++) {
        SharedPreferences.setMockInitialValues({
          'lm_best_score': 10,
          'lm_best_streak': 3,
          'stats_total_games': 20,
          'stats_total_continues': 5,
          'stats_total_score': 160,
          'stats_games_today': 0,
          'stats_games_yesterday': 5,
          'stats_avg_daily_games': 4,
          'stats_highest_level': 0,
          'stats_total_levels': 0,
          'stats_total_bonuses': 10,
        });

        await resetManagers();
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

  group('Required Mission Types', () {
    test('MUST have exactly 1 playGames mission with minimum 3 games', () async {
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 5,      // LivesManager key
        'lm_best_streak': 2,     // LivesManager key
        'stats_total_games': 10,
        'stats_total_continues': 2,
        'stats_total_score': 40,
        'stats_games_today': 0,
        'stats_games_yesterday': 0,
        'stats_avg_daily_games': 0,
        'stats_highest_level': 0,    // Correct key
        'stats_total_levels': 0,     // Correct key
        'stats_total_bonuses': 5,    // Correct key
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;
      final playMissions = missions.where((m) => m.type == MissionType.playGames).toList();

      // MUST have exactly 1 playGames mission
      expect(playMissions.length, equals(1), reason: 'Must have exactly 1 playGames mission');
      
      // Minimum 3 games
      expect(playMissions.first.target, greaterThanOrEqualTo(3), 
        reason: 'playGames mission must require minimum 3 games');
    });

    test('playGames target adapts to high activity players', () async {
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 50,
        'lm_best_streak': 10,
        'stats_total_games': 200,
        'stats_total_continues': 20,
        'stats_total_score': 7000,
        'stats_games_today': 0,
        'stats_games_yesterday': 10, // High activity!
        'stats_avg_daily_games': 8,
        'stats_highest_level': 20,
        'stats_total_levels': 20,
        'stats_total_bonuses': 100,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;
      final playMission = missions.firstWhere((m) => m.type == MissionType.playGames);

      // High activity player should get higher target (10 * 1.1 = 11)
      expect(playMission.target, greaterThanOrEqualTo(8), 
        reason: 'High activity player should get higher play target');
    });

    test('playGames target range is 3-15', () async {
      // Test beginner (min = 3)
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 5,
        'lm_best_streak': 1,
        'stats_total_games': 2,
        'stats_total_continues': 0,
        'stats_total_score': 6,
        'stats_games_today': 0,
        'stats_games_yesterday': 0,
        'stats_avg_daily_games': 0,
        'stats_highest_level': 0,
        'stats_total_levels': 0,
        'stats_total_bonuses': 0,
      });

      await resetManagers();
      var manager = MissionsManager();
      await manager.initialize();
      var playMission = manager.dailyMissions.firstWhere((m) => m.type == MissionType.playGames);
      
      expect(playMission.target, greaterThanOrEqualTo(3), reason: 'Minimum should be 3');
      expect(playMission.target, lessThanOrEqualTo(15), reason: 'Maximum should be 15');
    });

    test('MUST have exactly 1 completeLevel mission', () async {
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 25,
        'lm_best_streak': 5,
        'stats_total_games': 50,
        'stats_total_continues': 10,
        'stats_total_score': 750,
        'stats_games_today': 0,
        'stats_games_yesterday': 5,
        'stats_avg_daily_games': 4,
        'stats_highest_level': 5,
        'stats_total_levels': 5,
        'stats_total_bonuses': 20,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final missions = manager.dailyMissions;
      final levelMissions = missions.where((m) => m.type == MissionType.completeLevel).toList();

      // MUST have exactly 1 completeLevel mission
      expect(levelMissions.length, equals(1), reason: 'Must have exactly 1 completeLevel mission');
    });

    test('completeLevel target is currentLevel + 3 for story mode players', () async {
      // Player completed level 5, so current level is 6
      // Target should be 6 + 3 = 9
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 25,
        'lm_best_streak': 5,
        'stats_total_games': 50,
        'stats_total_continues': 10,
        'stats_total_score': 750,
        'stats_games_today': 0,
        'stats_games_yesterday': 5,
        'stats_avg_daily_games': 4,
        'stats_highest_level': 5,  // Completed level 5
        'stats_total_levels': 5,
        'stats_total_bonuses': 20,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final levelMission = manager.dailyMissions.firstWhere((m) => m.type == MissionType.completeLevel);

      // Current level is 6 (completed 5 + 1), target should be 6 + 3 = 9
      expect(levelMission.target, equals(9), 
        reason: 'Player at level 6 should get target 9 (current + 3)');
    });

    test('completeLevel target is 4 for new players (level 1 + 3)', () async {
      // New player (completed 0), current level is 1
      // Target = 1 + 3 = 4
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 5,
        'lm_best_streak': 1,
        'stats_total_games': 2,
        'stats_total_continues': 0,
        'stats_total_score': 6,
        'stats_games_today': 0,
        'stats_games_yesterday': 0,
        'stats_avg_daily_games': 0,
        'stats_highest_level': 0,  // New player!
        'stats_total_levels': 0,
        'stats_total_bonuses': 0,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final levelMission = manager.dailyMissions.firstWhere((m) => m.type == MissionType.completeLevel);

      // New player: current = 1, target = 1 + 3 = 4
      expect(levelMission.target, equals(4), 
        reason: 'New player should get target 4 (level 1 + 3)');
      expect(levelMission.target, greaterThanOrEqualTo(3), 
        reason: 'Level mission target should be minimum 3');
    });

    test('completeLevel target is capped at 30', () async {
      // Player at high level (completed 28)
      // Current = 29, target would be 32, but capped at 30
      SharedPreferences.setMockInitialValues({
        'lm_best_score': 100,
        'lm_best_streak': 20,
        'stats_total_games': 500,
        'stats_total_continues': 50,
        'stats_total_score': 30000,
        'stats_games_today': 0,
        'stats_games_yesterday': 10,
        'stats_avg_daily_games': 8,
        'stats_highest_level': 28,  // High level player
        'stats_total_levels': 28,
        'stats_total_bonuses': 200,
      });

      await resetManagers();
      final manager = MissionsManager();
      await manager.initialize();

      final levelMission = manager.dailyMissions.firstWhere((m) => m.type == MissionType.completeLevel);

      // Current = 29, target = 29 + 3 = 32, clamped to 30
      expect(levelMission.target, equals(30), 
        reason: 'Level mission target should be capped at 30');
    });

    test('Level mission formula examples', () async {
      // Test multiple examples of the formula: target = (highestCompleted + 1) + 3
      final testCases = [
        {'completed': 0, 'expected': 4},   // Level 1 + 3 = 4
        {'completed': 2, 'expected': 6},   // Level 3 + 3 = 6
        {'completed': 5, 'expected': 9},   // Level 6 + 3 = 9
        {'completed': 10, 'expected': 14}, // Level 11 + 3 = 14
        {'completed': 20, 'expected': 24}, // Level 21 + 3 = 24
        {'completed': 27, 'expected': 30}, // Level 28 + 3 = 31, capped to 30
        {'completed': 30, 'expected': 30}, // Level 31 + 3 = 34, capped to 30
      ];

      for (final testCase in testCases) {
        SharedPreferences.setMockInitialValues({
          'lm_best_score': 50,
          'lm_best_streak': 10,
          'stats_total_games': 100,
          'stats_total_continues': 10,
          'stats_total_score': 3000,
          'stats_games_today': 0,
          'stats_games_yesterday': 5,
          'stats_avg_daily_games': 4,
          'stats_highest_level': testCase['completed'] as int,
          'stats_total_levels': testCase['completed'] as int,
          'stats_total_bonuses': 50,
        });

        await resetManagers();
        final manager = MissionsManager();
        await manager.initialize();

        final levelMission = manager.dailyMissions.firstWhere((m) => m.type == MissionType.completeLevel);

        expect(levelMission.target, equals(testCase['expected']), 
          reason: 'Completed ${testCase['completed']} -> target should be ${testCase['expected']}');
      }
    });
  });
}


