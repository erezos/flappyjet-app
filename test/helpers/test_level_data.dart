/// Test Level Data - Pre-configured level data for testing
/// 
/// Provides common level configurations used across multiple tests
library;

import '../../lib/models/level_data_schema.dart';

/// Common test level configurations
class TestLevelData {
  /// Simple level with reach score objective
  static LevelData get simpleScoreLevel => LevelData(
    id: 1,
    name: 'Test Score Level',
    zone: 1,
    objective: LevelObjective(
      type: ObjectiveType.reachScore,
      target: 10,
      description: 'Reach score of 10',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.0,
      obstacleGap: 200,
      obstacleFrequency: 2.0,
    ),
    reward: LevelReward(
      coins: 50,
      gems: 0,
    ),
    theme: LevelTheme(
      background: 'peaceful_sky.png',
      obstacles: 'wooden_pipes.png',
      music: 'sky_rookie.mp3',
    ),
  );
  
  /// Level with survive time objective
  static LevelData get surviveTimeLevel => LevelData(
    id: 2,
    name: 'Test Survival Level',
    zone: 1,
    objective: LevelObjective(
      type: ObjectiveType.surviveTime,
      target: 30,
      description: 'Survive for 30 seconds',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.2,
      obstacleGap: 180,
      obstacleFrequency: 2.2,
    ),
    reward: LevelReward(
      coins: 60,
      gems: 0,
    ),
    theme: LevelTheme(
      background: 'peaceful_sky.png',
      obstacles: 'wooden_pipes.png',
      music: 'sky_rookie.mp3',
    ),
  );
  
  /// Level with collect coins objective
  static LevelData get collectCoinsLevel => LevelData(
    id: 3,
    name: 'Test Coin Collection Level',
    zone: 1,
    objective: LevelObjective(
      type: ObjectiveType.collectCoins,
      target: 15,
      description: 'Collect 15 coins',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.0,
      obstacleGap: 220,
      obstacleFrequency: 1.8,
    ),
    reward: LevelReward(
      coins: 70,
      gems: 5,
    ),
    theme: LevelTheme(
      background: 'peaceful_sky.png',
      obstacles: 'wooden_pipes.png',
      music: 'sky_rookie.mp3',
    ),
  );
  
  /// Level with bot battle objective
  static LevelData get botBattleLevel => LevelData(
    id: 10,
    name: 'Test Bot Battle',
    zone: 1,
    objective: LevelObjective(
      type: ObjectiveType.beatBot,
      target: 12,
      description: 'Beat the bot opponent',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.0,
      obstacleGap: 200,
      obstacleFrequency: 2.0,
    ),
    reward: LevelReward(
      coins: 100,
      gems: 10,
    ),
    theme: LevelTheme(
      background: 'peaceful_sky.png',
      obstacles: 'wooden_pipes.png',
      music: 'sky_rookie.mp3',
    ),
    botBattle: BotBattle(
      botName: 'Test Bot',
      botJetSkin: 'flame_jet',
      skillLevel: 0.7,
      reactionTime: 0.3,
      mistakeRate: 0.15,
    ),
  );
  
  /// Level with no crashes objective (perfect run)
  static LevelData get noCrashLevel => LevelData(
    id: 5,
    name: 'Test Perfect Run',
    zone: 2,
    objective: LevelObjective(
      type: ObjectiveType.noCrash,
      target: 20,
      description: 'Complete without crashing (20 obstacles)',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.1,
      obstacleGap: 190,
      obstacleFrequency: 2.1,
    ),
    reward: LevelReward(
      coins: 80,
      gems: 10,
    ),
    theme: LevelTheme(
      background: 'afternoon_sky.png',
      obstacles: 'stone_pillars.png',
      music: 'space_cadet.mp3',
    ),
  );
  
  /// Difficult level for stress testing
  static LevelData get difficultLevel => LevelData(
    id: 50,
    name: 'Test Extreme Challenge',
    zone: 5,
    objective: LevelObjective(
      type: ObjectiveType.reachScore,
      target: 30,
      description: 'Reach score of 30 with extreme difficulty',
    ),
    difficulty: LevelDifficulty(
      speedMultiplier: 1.8,
      obstacleGap: 140,
      obstacleFrequency: 2.8,
    ),
    reward: LevelReward(
      coins: 200,
      gems: 50,
    ),
    theme: LevelTheme(
      background: 'cosmic_void.png',
      obstacles: 'void_pillars.png',
      music: 'void_master.mp3',
    ),
  );
}

