/// 🧪 UNIFIED LEVEL DATA TESTS
/// 
/// Comprehensive tests for the UnifiedLevelData model.
/// Verifies factory methods, conversions, and getters.

import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_jet_pro/models/unified_level_data.dart';
import 'package:flappy_jet_pro/models/level_data_schema.dart';
import 'package:flappy_jet_pro/models/tournament_config.dart';

void main() {
  group('UnifiedLevelData', () {
    group('fromStoryLevel', () {
      test('creates unified data from story level', () {
        final storyLevel = LevelData(
          id: 5,
          zone: 1,
          name: 'Test Level',
          objective: const LevelObjective(
            type: ObjectiveType.passObstacles,
            target: 10,
            description: 'Pass 10 obstacles',
          ),
          difficulty: const DifficultyConfig(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
          ),
          reward: const LevelReward(coins: 100, gems: 5),
          theme: const LevelTheme(
            background: 'phase1_dawn_complete.png',
            obstacles: 'obstacles/phase1_wooden_pipes.png',
            music: 'game_music.mp3',
          ),
        );
        
        final unified = UnifiedLevelData.fromStoryLevel(storyLevel);
        
        expect(unified.id, equals('story_5'));
        expect(unified.name, equals('Test Level'));
        expect(unified.gameMode, equals(GameMode.story));
        expect(unified.stageNumber, equals(1));
        expect(unified.objective.type, equals(ObjectiveType.passObstacles));
        expect(unified.objective.target, equals(10));
        expect(unified.obstacleSpawnerType, equals(ObstacleSpawnerType.pillarPair));
        expect(unified.reward.coins, equals(100));
        expect(unified.reward.gems, equals(5));
        expect(unified.originalLevelId, equals(5));
      });
      
      test('preserves bot battle configuration', () {
        final storyLevel = LevelData(
          id: 5,
          zone: 1,
          name: 'Boss Level',
          objective: const LevelObjective(
            type: ObjectiveType.beatBot,
            target: 30,
            description: 'Beat the boss!',
          ),
          difficulty: const DifficultyConfig(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
          ),
          reward: const LevelReward(coins: 200, gems: 10),
          theme: const LevelTheme(
            background: 'phase1_dawn_complete.png',
            obstacles: 'obstacles/phase1_wooden_pipes.png',
            music: 'boss_battle.mp3',
          ),
          botBattle: const BotBattle(
            botName: 'Sky Rookie',
            botJetSkin: 'sky_rookie',
            skillLevel: 0.7,
            reactionTime: 0.2,
            mistakeRate: 0.1,
            minObstaclePass: 5,
          ),
        );
        
        final unified = UnifiedLevelData.fromStoryLevel(storyLevel);
        
        expect(unified.hasBotBattle, isTrue);
        expect(unified.botBattle!.botName, equals('Sky Rookie'));
        expect(unified.botBattle!.botJetSkin, equals('sky_rookie'));
        expect(unified.botBattle!.skillLevel, equals(0.7));
        expect(unified.botBattle!.minObstaclePass, equals(5));
      });
    });
    
    group('fromTournamentLevel', () {
      late TournamentConfig tournament;
      
      setUp(() {
        tournament = TournamentConfig(
          id: 'stunt_tournament',
          name: 'Stunt Tournament',
          description: 'Test tournament',
          tier: TournamentTier.silver,
          status: TournamentStatus.active,
          progressionType: TournamentProgressionType.linear,
          entry: const TournamentEntryConfig(
            type: EntryFeeType.coins,
            amount: 1000,
          ),
          tries: const TournamentTriesConfig(count: 3),
          continues: const TournamentContinuesConfig(
            maxPerTry: 5,
            gemCost: 3,
            adAvailable: true,
          ),
          levels: const [],
          completionReward: const TournamentReward(coins: 5000, gems: 50),
          display: const TournamentDisplay(
            bannerImage: 'banner.png',
            icon: 'trophy',
            colorPrimary: '#FF0000',
          ),
        );
      });
      
      test('creates unified data from stunt tournament level', () {
        final level = TournamentLevel.fromJson({
          'round': 1,
          'name': 'Desert Drift',
          'background': 'phase2_sunny_complete.png',
          'difficulty': {
            'speedMultiplier': 1.0,
            'obstacleGap': 350,
            'obstacleFrequency': 2.5,
            'maxGapShift': 50,
            'requiredDistance': 30,
          },
          'reward': {'coins': 150, 'gems': 2},
          'stunt_config': {
            'mode': 'time_survival',
            'asset_path': 'obstacles/desert_obstacles.png',
            'obstacle_size_percent': 0.15,
            'spawn_interval': 2.5,
            'scroll_speed': 150,
            'vertical_amplitude_percent': 0.3,
            'vertical_frequency': 0.4,
          },
        });
        
        final unified = UnifiedLevelData.fromTournamentLevel(level, tournament);
        
        expect(unified.id, equals('tournament_stunt_tournament_1'));
        expect(unified.name, equals('Desert Drift'));
        expect(unified.gameMode, equals(GameMode.tournamentLinear));
        expect(unified.stageNumber, equals(1));
        expect(unified.isStuntMode, isTrue);
        expect(unified.obstacleSpawnerType, equals(ObstacleSpawnerType.singleVertical));
        expect(unified.objective.type, equals(ObjectiveType.surviveTime));
        expect(unified.objective.target, equals(30));
        expect(unified.stuntConfig, isNotNull);
        expect(unified.stuntConfig!.spawnInterval, equals(2.5));
        expect(unified.tournamentId, equals('stunt_tournament'));
      });
      
      test('creates unified data from pass obstacles tournament level', () {
        final level = TournamentLevel.fromJson({
          'round': 1,
          'name': 'Classic Challenge',
          'background': 'phase1_dawn_complete.png',
          'difficulty': {
            'speedMultiplier': 1.0,
            'obstacleGap': 350,
            'obstacleFrequency': 2.5,
            'maxGapShift': 50,
            'requiredDistance': 20,
          },
          'obstacles': {
            'pattern_mix': [
              {'type': 'static', 'weight': 100},
            ],
          },
          'reward': {'coins': 100, 'gems': 1},
        });
        
        final unified = UnifiedLevelData.fromTournamentLevel(level, tournament);
        
        expect(unified.isStuntMode, isFalse);
        expect(unified.obstacleSpawnerType, equals(ObstacleSpawnerType.pillarPair));
        expect(unified.objective.type, equals(ObjectiveType.passObstacles));
        expect(unified.objective.target, equals(20));
        expect(unified.stuntConfig, isNull);
      });
    });
    
    group('fromPlayoffRound', () {
      late TournamentConfig tournament;
      
      setUp(() {
        tournament = TournamentConfig(
          id: 'bosses_showdown',
          name: 'Bosses Showdown',
          description: 'Test playoff',
          tier: TournamentTier.gold,
          status: TournamentStatus.active,
          progressionType: TournamentProgressionType.playoff,
          entry: const TournamentEntryConfig(
            type: EntryFeeType.gems,
            amount: 50,
          ),
          tries: const TournamentTriesConfig(count: 3),
          continues: const TournamentContinuesConfig(
            maxPerTry: 5,
            gemCost: 5,
            adAvailable: true,
          ),
          levels: [
            TournamentLevel.fromJson({
              'round': 1,
              'name': 'Quarter Finals',
              'background': 'phase1_dawn_complete.png',
              'difficulty': {
                'speedMultiplier': 1.0,
                'obstacleGap': 350,
                'obstacleFrequency': 2.5,
                'maxGapShift': 50,
                'requiredDistance': 50,
              },
              'reward': {'coins': 200, 'gems': 5},
            }),
          ],
          completionReward: const TournamentReward(coins: 10000, gems: 100),
          display: const TournamentDisplay(
            bannerImage: 'banner.png',
            icon: 'trophy',
            colorPrimary: '#FFD700',
          ),
        );
      });
      
      test('creates unified data from playoff round', () {
        final round = PlayoffRound(
          roundNumber: 1,
          stageName: 'Quarter Finals',
          opponentJet: 'storm_ace',
          displayName: 'Storm Ace',
          bossBattle: const PlayoffBossBattle(
            background: 'phase1_dawn_complete.png',
            obstacleTheme: 'phase1_wooden_pipes.png',
            skillLevel: 0.6,
            reactionTime: 0.25,
            mistakeRate: 0.15,
            requiredDistance: 50,
          ),
        );
        
        final unified = UnifiedLevelData.fromPlayoffRound(round, tournament);
        
        expect(unified.id, equals('playoff_bosses_showdown_1'));
        expect(unified.name, equals('Quarter Finals'));
        expect(unified.gameMode, equals(GameMode.tournamentPlayoff));
        expect(unified.isPlayoff, isTrue);
        expect(unified.hasBotBattle, isTrue);
        expect(unified.botBattle!.botName, equals('Storm Ace'));
        expect(unified.botBattle!.botJetSkin, equals('storm_ace'));
        expect(unified.objective.type, equals(ObjectiveType.beatBot));
      });
    });
    
    group('getters', () {
      test('isStoryMode returns correctly', () {
        final storyLevel = _createTestUnifiedLevel(GameMode.story);
        final tournamentLevel = _createTestUnifiedLevel(GameMode.tournamentLinear);
        
        expect(storyLevel.isStoryMode, isTrue);
        expect(tournamentLevel.isStoryMode, isFalse);
      });
      
      test('isTournament returns correctly', () {
        final storyLevel = _createTestUnifiedLevel(GameMode.story);
        final linearTournament = _createTestUnifiedLevel(GameMode.tournamentLinear);
        final playoffTournament = _createTestUnifiedLevel(GameMode.tournamentPlayoff);
        
        expect(storyLevel.isTournament, isFalse);
        expect(linearTournament.isTournament, isTrue);
        expect(playoffTournament.isTournament, isTrue);
      });
      
      test('timeTarget returns correctly for surviveTime', () {
        final timeLevel = UnifiedLevelData(
          id: 'test',
          name: 'Test',
          gameMode: GameMode.tournamentLinear,
          stageNumber: 1,
          objective: const LevelObjective(
            type: ObjectiveType.surviveTime,
            target: 30,
            description: 'Survive 30 seconds',
          ),
          theme: const LevelTheme(
            background: 'bg.png',
            obstacles: 'obs.png',
            music: 'music.mp3',
          ),
          difficulty: const DifficultyConfig(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
          ),
          reward: const LevelReward(coins: 100, gems: 1),
        );
        
        expect(timeLevel.timeTarget, equals(30));
        expect(timeLevel.obstacleTarget, isNull);
      });
      
      test('obstacleTarget returns correctly for passObstacles', () {
        final obstacleLevel = UnifiedLevelData(
          id: 'test',
          name: 'Test',
          gameMode: GameMode.story,
          stageNumber: 1,
          objective: const LevelObjective(
            type: ObjectiveType.passObstacles,
            target: 15,
            description: 'Pass 15 obstacles',
          ),
          theme: const LevelTheme(
            background: 'bg.png',
            obstacles: 'obs.png',
            music: 'music.mp3',
          ),
          difficulty: const DifficultyConfig(
            speedMultiplier: 1.0,
            obstacleGap: 350,
            obstacleFrequency: 2.5,
          ),
          reward: const LevelReward(coins: 100, gems: 1),
        );
        
        expect(obstacleLevel.obstacleTarget, equals(15));
        expect(obstacleLevel.timeTarget, isNull);
      });
    });
    
    group('toLevelData', () {
      test('converts back to LevelData correctly', () {
        final storyLevel = LevelData(
          id: 10,
          zone: 2,
          name: 'Test Level',
          objective: const LevelObjective(
            type: ObjectiveType.passObstacles,
            target: 10,
            description: 'Pass 10 obstacles',
          ),
          difficulty: const DifficultyConfig(
            speedMultiplier: 1.2,
            obstacleGap: 340,
            obstacleFrequency: 2.0,
          ),
          reward: const LevelReward(coins: 150, gems: 3),
          theme: const LevelTheme(
            background: 'phase2_sunny_complete.png',
            obstacles: 'obstacles/desert_obstacles.png',
            music: 'desert_theme.mp3',
          ),
        );
        
        final unified = UnifiedLevelData.fromStoryLevel(storyLevel);
        final converted = unified.toLevelData();
        
        expect(converted.id, equals(10));
        expect(converted.zone, equals(2));
        expect(converted.name, equals('Test Level'));
        expect(converted.objective.type, equals(ObjectiveType.passObstacles));
        expect(converted.difficulty.speedMultiplier, equals(1.2));
        expect(converted.reward.coins, equals(150));
      });
    });
  });
  
  group('UnifiedBotConfig', () {
    test('creates from story bot battle', () {
      const botBattle = BotBattle(
        botName: 'Test Bot',
        botJetSkin: 'test_skin',
        skillLevel: 0.8,
        reactionTime: 0.15,
        mistakeRate: 0.05,
        minObstaclePass: 10,
      );
      
      final config = UnifiedBotConfig.fromStoryBotBattle(botBattle);
      
      expect(config.botName, equals('Test Bot'));
      expect(config.botJetSkin, equals('test_skin'));
      expect(config.skillLevel, equals(0.8));
      expect(config.reactionTime, equals(0.15));
      expect(config.mistakeRate, equals(0.05));
      expect(config.minObstaclePass, equals(10));
    });
    
    test('converts back to BotBattle', () {
      const config = UnifiedBotConfig(
        botName: 'Test Bot',
        botJetSkin: 'test_skin',
        skillLevel: 0.7,
        reactionTime: 0.2,
        mistakeRate: 0.1,
        minObstaclePass: 5,
      );
      
      final botBattle = config.toBotBattle();
      
      expect(botBattle.botName, equals('Test Bot'));
      expect(botBattle.botJetSkin, equals('test_skin'));
      expect(botBattle.skillLevel, equals(0.7));
    });
  });
  
  group('StuntObstacleConfiguration', () {
    test('parses from JSON correctly', () {
      final config = StuntObstacleConfiguration.fromJson({
        'mode': 'time_survival',
        'asset_path': 'obstacles/test.png',
        'obstacle_size_percent': 0.2,
        'spawn_interval': 3.0,
        'scroll_speed': 200,
        'vertical_amplitude_percent': 0.4,
        'vertical_frequency': 0.5,
      });
      
      expect(config.mode, equals('time_survival'));
      expect(config.assetPath, equals('obstacles/test.png'));
      expect(config.obstacleSizePercent, equals(0.2));
      expect(config.spawnInterval, equals(3.0));
      expect(config.scrollSpeed, equals(200));
      expect(config.verticalAmplitudePercent, equals(0.4));
      expect(config.verticalFrequency, equals(0.5));
    });
    
    test('uses defaults for missing values', () {
      final config = StuntObstacleConfiguration.fromJson({});
      
      expect(config.mode, equals('time_survival'));
      expect(config.assetPath, equals('obstacles/desert_obstacles.png'));
      expect(config.obstacleSizePercent, equals(0.15));
      expect(config.spawnInterval, equals(2.5));
      expect(config.scrollSpeed, equals(150.0));
    });
    
    test('converts to JSON correctly', () {
      const config = StuntObstacleConfiguration(
        mode: 'test_mode',
        assetPath: 'obstacles/test.png',
        obstacleSizePercent: 0.25,
        spawnInterval: 2.0,
        scrollSpeed: 180,
        verticalAmplitudePercent: 0.35,
        verticalFrequency: 0.45,
      );
      
      final json = config.toJson();
      
      expect(json['mode'], equals('test_mode'));
      expect(json['asset_path'], equals('obstacles/test.png'));
      expect(json['obstacle_size_percent'], equals(0.25));
    });
  });
  
  group('GameMode enum', () {
    test('has correct values', () {
      expect(GameMode.values.length, equals(3));
      expect(GameMode.values, contains(GameMode.story));
      expect(GameMode.values, contains(GameMode.tournamentLinear));
      expect(GameMode.values, contains(GameMode.tournamentPlayoff));
    });
  });
  
  group('ObstacleSpawnerType enum', () {
    test('has correct values', () {
      expect(ObstacleSpawnerType.values.length, equals(2));
      expect(ObstacleSpawnerType.values, contains(ObstacleSpawnerType.pillarPair));
      expect(ObstacleSpawnerType.values, contains(ObstacleSpawnerType.singleVertical));
    });
  });
}

/// Helper to create test unified level
UnifiedLevelData _createTestUnifiedLevel(GameMode mode) {
  return UnifiedLevelData(
    id: 'test_${mode.name}',
    name: 'Test Level',
    gameMode: mode,
    stageNumber: 1,
    objective: const LevelObjective(
      type: ObjectiveType.passObstacles,
      target: 10,
      description: 'Test',
    ),
    theme: const LevelTheme(
      background: 'bg.png',
      obstacles: 'obs.png',
      music: 'music.mp3',
    ),
    difficulty: const DifficultyConfig(
      speedMultiplier: 1.0,
      obstacleGap: 350,
      obstacleFrequency: 2.5,
    ),
    reward: const LevelReward(coins: 100, gems: 1),
  );
}

