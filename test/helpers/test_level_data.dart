/// Test Level Data - Pre-configured level data for testing
/// 
/// Provides common level configurations used across multiple tests
library;

import 'package:flappy_jet_pro/models/level_data_schema.dart';

/// Common test level configurations
class TestLevelData {
  /// Simple level with pass obstacles objective
  static LevelData get simpleObstacleLevel => LevelData(
    id: 1,
    name: 'Test Obstacle Level',
    zone: 1,
    objective: LevelObjective(
      type: ObjectiveType.passObstacles,
      target: 10,
      description: 'Pass 10 obstacles',
    ),
    difficulty: DifficultyConfig(
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
    difficulty: DifficultyConfig(
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
    difficulty: DifficultyConfig(
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
  
  /// Difficult level for stress testing
  static LevelData get difficultLevel => LevelData(
    id: 50,
    name: 'Test Extreme Challenge',
    zone: 5,
    objective: LevelObjective(
      type: ObjectiveType.passObstacles,
      target: 30,
      description: 'Pass 30 obstacles with extreme difficulty',
    ),
    difficulty: DifficultyConfig(
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

