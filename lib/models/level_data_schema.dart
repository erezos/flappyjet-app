/// 🎮 STORY MODE - LEVEL DATA SCHEMA
/// 
/// This file defines the data structure for all story mode levels.
/// Levels are loaded from JSON and parsed into these models.
library;


/// Main level data model
class LevelData {
  final int id;
  final int zone;
  final String name;
  final LevelObjective objective;
  final DifficultyConfig difficulty;
  final LevelReward reward;
  final LevelTheme theme;
  final BotBattle? botBattle; // Null if not a bot level

  const LevelData({
    required this.id,
    required this.zone,
    required this.name,
    required this.objective,
    required this.difficulty,
    required this.reward,
    required this.theme,
    this.botBattle,
  });

  /// Parse from JSON
  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      id: json['id'] as int,
      zone: json['zone'] as int,
      name: json['name'] as String,
      objective: LevelObjective.fromJson(json['objective'] as Map<String, dynamic>),
      difficulty: DifficultyConfig.fromJson(json['difficulty'] as Map<String, dynamic>),
      reward: LevelReward.fromJson(json['reward'] as Map<String, dynamic>),
      theme: LevelTheme.fromJson(json['theme'] as Map<String, dynamic>),
      botBattle: json['botBattle'] != null 
          ? BotBattle.fromJson(json['botBattle'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone': zone,
      'name': name,
      'objective': objective.toJson(),
      'difficulty': difficulty.toJson(),
      'reward': reward.toJson(),
      'theme': theme.toJson(),
      'botBattle': botBattle?.toJson(),
    };
  }

  @override
  String toString() => 'Level $id: $name (Zone $zone)';
}

/// Level objective types and targets
class LevelObjective {
  final ObjectiveType type;
  final int target;
  final String description;

  const LevelObjective({
    required this.type,
    required this.target,
    required this.description,
  });

  factory LevelObjective.fromJson(Map<String, dynamic> json) {
    return LevelObjective(
      type: ObjectiveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ObjectiveType.passObstacles,
      ),
      target: json['target'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'target': target,
      'description': description,
    };
  }

  @override
  String toString() => description;
}

/// Objective types
enum ObjectiveType {
  passObstacles,  // Pass X obstacles
  surviveTime,    // Survive X seconds
  beatBot,        // Beat the bot in a race
}

/// Difficulty configuration for gameplay
class DifficultyConfig {
  final double speedMultiplier;    // 1.0 = normal, 1.5 = 50% faster
  final double obstacleGap;        // Pixels between top/bottom obstacles
  final double obstacleFrequency;  // Seconds between obstacles
  final double? maxGapShift;       // Max vertical shift between consecutive gaps (pixels). Null = unlimited

  const DifficultyConfig({
    required this.speedMultiplier,
    required this.obstacleGap,
    required this.obstacleFrequency,
    this.maxGapShift,
  });

  factory DifficultyConfig.fromJson(Map<String, dynamic> json) {
    return DifficultyConfig(
      speedMultiplier: (json['speedMultiplier'] as num).toDouble(),
      obstacleGap: (json['obstacleGap'] as num).toDouble(),
      obstacleFrequency: (json['obstacleFrequency'] as num).toDouble(),
      maxGapShift: json['maxGapShift'] != null 
          ? (json['maxGapShift'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speedMultiplier': speedMultiplier,
      'obstacleGap': obstacleGap,
      'obstacleFrequency': obstacleFrequency,
      if (maxGapShift != null) 'maxGapShift': maxGapShift,
    };
  }
}

/// Rewards for completing a level
class LevelReward {
  final int coins;
  final int gems;
  final String? specialReward; // e.g., "exclusive_skin_frozen_ace"

  const LevelReward({
    required this.coins,
    required this.gems,
    this.specialReward,
  });

  factory LevelReward.fromJson(Map<String, dynamic> json) {
    return LevelReward(
      coins: json['coins'] as int,
      gems: json['gems'] as int,
      specialReward: json['specialReward'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'gems': gems,
      if (specialReward != null) 'specialReward': specialReward,
    };
  }

  bool get hasSpecialReward => specialReward != null;
}

/// Theme/visual configuration for a level
class LevelTheme {
  final String background;
  final String obstacles;
  final String music;
  final String? particleEffect; // Optional particle effects

  const LevelTheme({
    required this.background,
    required this.obstacles,
    required this.music,
    this.particleEffect,
  });

  factory LevelTheme.fromJson(Map<String, dynamic> json) {
    return LevelTheme(
      background: json['background'] as String,
      obstacles: json['obstacles'] as String,
      music: json['music'] as String,
      particleEffect: json['particleEffect'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background': background,
      'obstacles': obstacles,
      'music': music,
      if (particleEffect != null) 'particleEffect': particleEffect,
    };
  }
}

/// Bot battle configuration (for 1v1 levels)
class BotBattle {
  final String botName;
  final String botJetSkin;
  final double skillLevel;      // 0.6 - 1.5 (60% - 150% of perfect play)
  final double reactionTime;    // 0.1 - 0.5 seconds
  final double mistakeRate;     // 0.02 - 0.20 (2% - 20% chance of mistakes)
  final BotOverride? firstAttemptOverride; // Optional: Make boss harder on first attempt

  const BotBattle({
    required this.botName,
    required this.botJetSkin,
    required this.skillLevel,
    required this.reactionTime,
    required this.mistakeRate,
    this.firstAttemptOverride,
  });

  factory BotBattle.fromJson(Map<String, dynamic> json) {
    return BotBattle(
      botName: json['botName'] as String,
      botJetSkin: json['botJetSkin'] as String,
      skillLevel: (json['skillLevel'] as num).toDouble(),
      reactionTime: (json['reactionTime'] as num).toDouble(),
      mistakeRate: (json['mistakeRate'] as num).toDouble(),
      firstAttemptOverride: json['firstAttemptOverride'] != null
          ? BotOverride.fromJson(json['firstAttemptOverride'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'botName': botName,
      'botJetSkin': botJetSkin,
      'skillLevel': skillLevel,
      'reactionTime': reactionTime,
      'mistakeRate': mistakeRate,
      if (firstAttemptOverride != null) 'firstAttemptOverride': firstAttemptOverride!.toJson(),
    };
  }

  @override
  String toString() => 'Bot: $botName (Skill: ${(skillLevel * 100).toInt()}%)';
}

/// Bot override configuration for first-time encounters
/// Used to make zone finale bosses unbeatable on first attempt
class BotOverride {
  final double skillLevel;
  final double reactionTime;
  final double mistakeRate;

  const BotOverride({
    required this.skillLevel,
    required this.reactionTime,
    required this.mistakeRate,
  });

  factory BotOverride.fromJson(Map<String, dynamic> json) {
    return BotOverride(
      skillLevel: (json['skillLevel'] as num).toDouble(),
      reactionTime: (json['reactionTime'] as num).toDouble(),
      mistakeRate: (json['mistakeRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillLevel': skillLevel,
      'reactionTime': reactionTime,
      'mistakeRate': mistakeRate,
    };
  }
}

/// Zone metadata (for world map display)
class ZoneData {
  final int id;
  final String name;
  final String description;
  final int startLevel;
  final int endLevel;
  final String iconPath;

  const ZoneData({
    required this.id,
    required this.name,
    required this.description,
    required this.startLevel,
    required this.endLevel,
    required this.iconPath,
  });

  factory ZoneData.fromJson(Map<String, dynamic> json) {
    return ZoneData(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      startLevel: json['startLevel'] as int,
      endLevel: json['endLevel'] as int,
      iconPath: json['iconPath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startLevel': startLevel,
      'endLevel': endLevel,
      'iconPath': iconPath,
    };
  }

  int get totalLevels => endLevel - startLevel + 1;
}
