/// 🎁 IN-GAME BONUSES - Configuration Schema
/// 
/// Defines configurable bonus spawning for story mode levels.
/// Supports multiple spawn location strategies and bonus types.
library;

/// Spawn location strategy for bonuses
enum BonusSpawnLocation {
  /// Spawn inside the obstacle gap (safest, always collectible)
  insideGap,
  
  /// Spawn between obstacles (in the open space before next obstacle)
  betweenObstacles,
  
  /// Spawn in upper safe zone (top 30% of screen, away from obstacles)
  upperZone,
  
  /// Spawn in lower safe zone (bottom 30% of screen, away from ground)
  lowerZone,
  
  /// Random safe location (any of the above, weighted by config)
  randomSafe,
}

/// Shield tier configuration (different durations/colors)
enum ShieldTier {
  /// Blue shield - 3 seconds duration (most common)
  blue(3.0, 'shield_bonus_blue.png'),
  
  /// Red shield - 4 seconds duration (medium rarity)
  red(4.0, 'shield_bonus_red.png'),
  
  /// Green shield - 5 seconds duration (rare)
  green(5.0, 'shield_bonus_green.png');
  
  final double duration;
  final String assetName;
  
  const ShieldTier(this.duration, this.assetName);
}

/// Configuration for a single bonus type
class BonusTypeConfig {
  /// Chance of this bonus type when a bonus spawns (0.0 - 1.0)
  /// All type chances should sum to 1.0
  final double chance;
  
  /// For shields: which tiers can spawn and their relative weights
  final Map<ShieldTier, double>? shieldTierWeights;
  
  /// For coins: minimum amount per pickup
  final int? minAmount;
  
  /// For coins: maximum amount per pickup
  final int? maxAmount;
  
  const BonusTypeConfig({
    required this.chance,
    this.shieldTierWeights,
    this.minAmount,
    this.maxAmount,
  });
  
  factory BonusTypeConfig.fromJson(Map<String, dynamic> json) {
    Map<ShieldTier, double>? tierWeights;
    if (json['shieldTierWeights'] != null) {
      tierWeights = {};
      final weights = json['shieldTierWeights'] as Map<String, dynamic>;
      if (weights['blue'] != null) {
        tierWeights[ShieldTier.blue] = (weights['blue'] as num).toDouble();
      }
      if (weights['red'] != null) {
        tierWeights[ShieldTier.red] = (weights['red'] as num).toDouble();
      }
      if (weights['green'] != null) {
        tierWeights[ShieldTier.green] = (weights['green'] as num).toDouble();
      }
    }
    
    return BonusTypeConfig(
      chance: (json['chance'] as num).toDouble(),
      shieldTierWeights: tierWeights,
      minAmount: json['minAmount'] as int?,
      maxAmount: json['maxAmount'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'chance': chance,
    };
    
    if (shieldTierWeights != null) {
      map['shieldTierWeights'] = {
        if (shieldTierWeights![ShieldTier.blue] != null)
          'blue': shieldTierWeights![ShieldTier.blue],
        if (shieldTierWeights![ShieldTier.red] != null)
          'red': shieldTierWeights![ShieldTier.red],
        if (shieldTierWeights![ShieldTier.green] != null)
          'green': shieldTierWeights![ShieldTier.green],
      };
    }
    
    if (minAmount != null) map['minAmount'] = minAmount;
    if (maxAmount != null) map['maxAmount'] = maxAmount;
    
    return map;
  }
}

/// Spawn location weight configuration
class SpawnLocationConfig {
  /// Weight for spawning inside obstacle gaps
  final double insideGapWeight;
  
  /// Weight for spawning between obstacles
  final double betweenObstaclesWeight;
  
  /// Weight for spawning in upper safe zone
  final double upperZoneWeight;
  
  /// Weight for spawning in lower safe zone
  final double lowerZoneWeight;
  
  const SpawnLocationConfig({
    this.insideGapWeight = 0.5,
    this.betweenObstaclesWeight = 0.3,
    this.upperZoneWeight = 0.1,
    this.lowerZoneWeight = 0.1,
  });
  
  factory SpawnLocationConfig.fromJson(Map<String, dynamic> json) {
    return SpawnLocationConfig(
      insideGapWeight: (json['insideGapWeight'] as num?)?.toDouble() ?? 0.5,
      betweenObstaclesWeight: (json['betweenObstaclesWeight'] as num?)?.toDouble() ?? 0.3,
      upperZoneWeight: (json['upperZoneWeight'] as num?)?.toDouble() ?? 0.1,
      lowerZoneWeight: (json['lowerZoneWeight'] as num?)?.toDouble() ?? 0.1,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'insideGapWeight': insideGapWeight,
    'betweenObstaclesWeight': betweenObstaclesWeight,
    'upperZoneWeight': upperZoneWeight,
    'lowerZoneWeight': lowerZoneWeight,
  };
  
  /// Get total weight for normalization
  double get totalWeight => 
    insideGapWeight + betweenObstaclesWeight + upperZoneWeight + lowerZoneWeight;
  
  /// Select a spawn location based on weights
  BonusSpawnLocation selectLocation(double random) {
    final normalized = random * totalWeight;
    double cumulative = 0;
    
    cumulative += insideGapWeight;
    if (normalized < cumulative) return BonusSpawnLocation.insideGap;
    
    cumulative += betweenObstaclesWeight;
    if (normalized < cumulative) return BonusSpawnLocation.betweenObstacles;
    
    cumulative += upperZoneWeight;
    if (normalized < cumulative) return BonusSpawnLocation.upperZone;
    
    return BonusSpawnLocation.lowerZone;
  }
}

/// Main bonus configuration for a level
class BonusConfig {
  /// Whether bonuses are enabled for this level
  final bool enabled;
  
  /// Minimum bonuses to spawn during the level (guaranteed)
  final int minPerLevel;
  
  /// Maximum bonuses that can spawn during the level
  final int maxPerLevel;
  
  /// Base chance of spawning a bonus when an obstacle spawns (0.0 - 1.0)
  final double spawnChance;
  
  /// Minimum obstacles passed before first bonus can spawn
  final int minObstaclesBeforeFirstBonus;
  
  /// Minimum obstacles between bonus spawns (prevents clustering)
  final int minObstaclesBetweenBonuses;
  
  /// Spawn location configuration
  final SpawnLocationConfig spawnLocations;
  
  /// Shield bonus configuration
  final BonusTypeConfig? shield;
  
  /// Coin bonus configuration
  final BonusTypeConfig? coins;
  
  /// Gem bonus configuration
  final BonusTypeConfig? gems;
  
  const BonusConfig({
    this.enabled = false,
    this.minPerLevel = 0,
    this.maxPerLevel = 2,
    this.spawnChance = 0.25,
    this.minObstaclesBeforeFirstBonus = 2,
    this.minObstaclesBetweenBonuses = 3,
    this.spawnLocations = const SpawnLocationConfig(),
    this.shield,
    this.coins,
    this.gems,
  });
  
  /// Default configuration (disabled)
  static const BonusConfig disabled = BonusConfig(enabled: false);
  
  /// Default configuration for story mode (balanced)
  static const BonusConfig storyModeDefault = BonusConfig(
    enabled: true,
    minPerLevel: 0,
    maxPerLevel: 2,
    spawnChance: 0.20,
    minObstaclesBeforeFirstBonus: 3,
    minObstaclesBetweenBonuses: 4,
    spawnLocations: SpawnLocationConfig(
      insideGapWeight: 0.6,
      betweenObstaclesWeight: 0.25,
      upperZoneWeight: 0.075,
      lowerZoneWeight: 0.075,
    ),
    shield: BonusTypeConfig(
      chance: 0.15,
      shieldTierWeights: {
        ShieldTier.blue: 0.6,
        ShieldTier.red: 0.3,
        ShieldTier.green: 0.1,
      },
    ),
    coins: BonusTypeConfig(
      chance: 0.60,
      minAmount: 10,
      maxAmount: 25,
    ),
    gems: BonusTypeConfig(
      chance: 0.25,
      minAmount: 1,
      maxAmount: 3,
    ),
  );
  
  factory BonusConfig.fromJson(Map<String, dynamic> json) {
    return BonusConfig(
      enabled: json['enabled'] as bool? ?? false,
      minPerLevel: json['minPerLevel'] as int? ?? 0,
      maxPerLevel: json['maxPerLevel'] as int? ?? 2,
      spawnChance: (json['spawnChance'] as num?)?.toDouble() ?? 0.25,
      minObstaclesBeforeFirstBonus: json['minObstaclesBeforeFirstBonus'] as int? ?? 2,
      minObstaclesBetweenBonuses: json['minObstaclesBetweenBonuses'] as int? ?? 3,
      spawnLocations: json['spawnLocations'] != null
          ? SpawnLocationConfig.fromJson(json['spawnLocations'] as Map<String, dynamic>)
          : const SpawnLocationConfig(),
      shield: json['shield'] != null
          ? BonusTypeConfig.fromJson(json['shield'] as Map<String, dynamic>)
          : null,
      coins: json['coins'] != null
          ? BonusTypeConfig.fromJson(json['coins'] as Map<String, dynamic>)
          : null,
      gems: json['gems'] != null
          ? BonusTypeConfig.fromJson(json['gems'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'minPerLevel': minPerLevel,
    'maxPerLevel': maxPerLevel,
    'spawnChance': spawnChance,
    'minObstaclesBeforeFirstBonus': minObstaclesBeforeFirstBonus,
    'minObstaclesBetweenBonuses': minObstaclesBetweenBonuses,
    'spawnLocations': spawnLocations.toJson(),
    if (shield != null) 'shield': shield!.toJson(),
    if (coins != null) 'coins': coins!.toJson(),
    if (gems != null) 'gems': gems!.toJson(),
  };
  
  /// Check if any bonus types are configured
  bool get hasAnyBonusTypes => shield != null || coins != null || gems != null;
  
  @override
  String toString() => 'BonusConfig(enabled: $enabled, chance: $spawnChance, '
      'min: $minPerLevel, max: $maxPerLevel)';
}

/// Bonus type enum for spawn selection
enum BonusType {
  shield,
  coins,
  gems,
}

