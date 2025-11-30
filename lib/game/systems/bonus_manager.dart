import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../../models/bonus_config.dart';
import '../components/collectible_bonus.dart';
import '../components/bonuses/shield_bonus.dart';
import '../components/bonuses/coin_bonus.dart';
import '../components/bonuses/gem_bonus.dart';

/// 🎁 BonusManager - Manages spawning and tracking of in-game bonuses
/// 
/// Features:
/// - Configurable spawn locations (gap, between obstacles, safe zones)
/// - Configurable bonus types and probabilities
/// - Tracks bonus collection for level completion
/// - Performance-optimized (max active bonuses limit)
/// - Time-based level detection (forces inside-gap spawning)
class BonusManager {
  /// Current bonus configuration
  BonusConfig _config = BonusConfig.disabled;
  
  /// Random number generator
  final math.Random _random = math.Random();
  
  /// List of active bonuses in the game
  final List<CollectibleBonus> _activeBonuses = [];
  
  /// Maximum active bonuses at once (performance limit)
  static const int _maxActiveBonuses = 3;
  
  /// Track spawn state
  int _obstaclesPassed = 0;
  int _obstaclesSinceLastBonus = 0;
  int _bonusesSpawnedThisLevel = 0;
  int _bonusesCollectedThisLevel = 0;
  
  /// 🎯 Track collected rewards for analytics
  int _totalShieldsCollected = 0;
  int _totalCoinsCollected = 0;
  int _totalGemsCollected = 0;
  
  /// Game dimensions (set during initialization)
  double _screenWidth = 400;
  double _screenHeight = 800;
  
  /// Current obstacle speed (for bonus movement)
  double _currentSpeed = 200;
  
  /// Reference to the game world for adding bonuses
  Component? _gameWorld;
  
  /// 🎯 Force inside-gap spawning (for time-based levels)
  bool _forceInsideGapOnly = false;
  
  // 🛑 PERFORMANCE FIX: Pause flag to stop spawning during victory animation
  bool _isPaused = false;
  
  /// Callback when a bonus is collected
  void Function(BonusType type, Map<String, dynamic> rewardData)? onBonusCollected;
  
  /// Pause bonus spawning (e.g., during victory animation)
  void pause() {
    _isPaused = true;
    safePrint('🛑 BonusManager: Spawning PAUSED');
  }
  
  /// Resume bonus spawning
  void resume() {
    _isPaused = false;
    safePrint('▶️ BonusManager: Spawning RESUMED');
  }
  
  /// Check if spawning is paused
  bool get isPaused => _isPaused;
  
  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  /// Initialize the bonus manager with configuration
  /// [forceInsideGapOnly] - For time-based levels, force all bonuses to spawn inside gaps
  void initialize({
    required BonusConfig config,
    required double screenWidth,
    required double screenHeight,
    required Component gameWorld,
    bool forceInsideGapOnly = false,
  }) {
    _config = config;
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    _gameWorld = gameWorld;
    _forceInsideGapOnly = forceInsideGapOnly;
    
    // Reset tracking state
    _obstaclesPassed = 0;
    _obstaclesSinceLastBonus = 0;
    _bonusesSpawnedThisLevel = 0;
    _bonusesCollectedThisLevel = 0;
    _totalShieldsCollected = 0;
    _totalCoinsCollected = 0;
    _totalGemsCollected = 0;
    _activeBonuses.clear();
    
    safePrint('🎁 BonusManager initialized: ${config.enabled ? "ENABLED" : "DISABLED"}');
    if (config.enabled) {
      safePrint('🎁 Config: chance=${config.spawnChance}, min=${config.minPerLevel}, max=${config.maxPerLevel}');
      if (_forceInsideGapOnly) {
        safePrint('🎁 ⚠️ Time-based level: FORCING inside-gap-only spawning');
      }
    }
  }
  
  /// Update current obstacle speed (for bonus movement)
  void setCurrentSpeed(double speed) {
    _currentSpeed = speed;
  }
  
  // ============================================================================
  // SPAWN LOGIC
  // ============================================================================
  
  /// Called when an obstacle is passed/spawned
  /// [obstacleGapCenter] - Y position of the obstacle gap center
  /// [obstacleX] - X position of the obstacle
  /// [gapSize] - Size of the obstacle gap
  void onObstacleSpawned({
    required double obstacleGapCenter,
    required double obstacleX,
    required double gapSize,
  }) {
    // 🛑 PERFORMANCE FIX: Skip spawning if paused
    if (_isPaused) return;
    if (!_config.enabled) return;
    
    _obstaclesPassed++;
    _obstaclesSinceLastBonus++;
    
    // Check if we can spawn a bonus
    if (!_canSpawnBonus()) {
      return;
    }
    
    // Roll for spawn
    final roll = _random.nextDouble();
    if (roll > _config.spawnChance) {
      safePrint('🎁 Spawn roll failed: $roll > ${_config.spawnChance}');
      return;
    }
    
    // Determine spawn location
    // 🎯 For time-based levels, ALWAYS spawn inside the gap (only way to collect)
    final spawnLocation = _forceInsideGapOnly 
        ? BonusSpawnLocation.insideGap 
        : _config.spawnLocations.selectLocation(_random.nextDouble());
    final spawnPosition = _calculateSpawnPosition(
      spawnLocation: spawnLocation,
      obstacleGapCenter: obstacleGapCenter,
      obstacleX: obstacleX,
      gapSize: gapSize,
    );
    
    // Determine bonus type
    final bonusType = _selectBonusType();
    if (bonusType == null) {
      safePrint('🎁 No bonus type selected (check config)');
      return;
    }
    
    // Create the bonus
    final bonus = _createBonus(bonusType, spawnPosition);
    if (bonus == null) {
      safePrint('🎁 Failed to create bonus of type: $bonusType');
      return;
    }
    
    // Add to game world
    _gameWorld?.add(bonus);
    _activeBonuses.add(bonus);
    _bonusesSpawnedThisLevel++;
    _obstaclesSinceLastBonus = 0;
    
    safePrint('🎁 Spawned ${bonusType.name} at ${spawnLocation.name} (${spawnPosition.x.toInt()}, ${spawnPosition.y.toInt()})');
  }
  
  /// Check if a bonus can be spawned
  bool _canSpawnBonus() {
    // Check if bonuses are enabled
    if (!_config.enabled || !_config.hasAnyBonusTypes) {
      return false;
    }
    
    // Check max active bonuses limit
    if (_activeBonuses.length >= _maxActiveBonuses) {
      safePrint('🎁 Max active bonuses reached (${_activeBonuses.length}/$_maxActiveBonuses)');
      return false;
    }
    
    // Check max per level
    if (_bonusesSpawnedThisLevel >= _config.maxPerLevel) {
      safePrint('🎁 Max bonuses per level reached ($_bonusesSpawnedThisLevel/${_config.maxPerLevel})');
      return false;
    }
    
    // Check minimum obstacles before first bonus
    if (_bonusesSpawnedThisLevel == 0 && _obstaclesPassed < _config.minObstaclesBeforeFirstBonus) {
      return false;
    }
    
    // Check minimum obstacles between bonuses
    if (_obstaclesSinceLastBonus < _config.minObstaclesBetweenBonuses) {
      return false;
    }
    
    return true;
  }
  
  /// Calculate spawn position based on location type
  Vector2 _calculateSpawnPosition({
    required BonusSpawnLocation spawnLocation,
    required double obstacleGapCenter,
    required double obstacleX,
    required double gapSize,
  }) {
    // X position: spawn ahead of obstacle (in the gap area or between)
    double x;
    double y;
    
    switch (spawnLocation) {
      case BonusSpawnLocation.insideGap:
        // Spawn in the center of the obstacle gap
        x = obstacleX + 50; // Slightly after obstacle edge
        y = obstacleGapCenter;
        
      case BonusSpawnLocation.betweenObstacles:
        // Spawn between current and next obstacle
        x = obstacleX + _screenWidth * 0.3; // 30% screen width ahead
        // Random Y in middle 60% of screen (safe from top/bottom)
        final safeTop = _screenHeight * 0.2;
        final safeBottom = _screenHeight * 0.8;
        y = safeTop + _random.nextDouble() * (safeBottom - safeTop);
        
      case BonusSpawnLocation.upperZone:
        // Spawn in upper safe zone (top 30%)
        x = obstacleX + _screenWidth * 0.2;
        y = _screenHeight * (0.1 + _random.nextDouble() * 0.2);
        
      case BonusSpawnLocation.lowerZone:
        // Spawn in lower safe zone (bottom 30%, above ground)
        x = obstacleX + _screenWidth * 0.2;
        y = _screenHeight * (0.65 + _random.nextDouble() * 0.2);
        
      case BonusSpawnLocation.randomSafe:
        // Use one of the above randomly
        final locations = [
          BonusSpawnLocation.insideGap,
          BonusSpawnLocation.betweenObstacles,
          BonusSpawnLocation.upperZone,
          BonusSpawnLocation.lowerZone,
        ];
        return _calculateSpawnPosition(
          spawnLocation: locations[_random.nextInt(locations.length)],
          obstacleGapCenter: obstacleGapCenter,
          obstacleX: obstacleX,
          gapSize: gapSize,
        );
    }
    
    return Vector2(x, y);
  }
  
  /// Select bonus type based on configured chances
  BonusType? _selectBonusType() {
    final roll = _random.nextDouble();
    double cumulative = 0;
    
    // Check shield
    if (_config.shield != null) {
      cumulative += _config.shield!.chance;
      if (roll < cumulative) return BonusType.shield;
    }
    
    // Check coins
    if (_config.coins != null) {
      cumulative += _config.coins!.chance;
      if (roll < cumulative) return BonusType.coins;
    }
    
    // Check gems
    if (_config.gems != null) {
      cumulative += _config.gems!.chance;
      if (roll < cumulative) return BonusType.gems;
    }
    
    // Fallback to coins if nothing selected but coins config exists
    if (_config.coins != null) return BonusType.coins;
    
    return null;
  }
  
  /// Create a bonus component based on type
  CollectibleBonus? _createBonus(BonusType type, Vector2 position) {
    switch (type) {
      case BonusType.shield:
        // Select shield tier based on weights
        final tier = _selectShieldTier();
        return ShieldBonus(
          position: position,
          speed: _currentSpeed,
          tier: tier,
        );
        
      case BonusType.coins:
        final config = _config.coins!;
        final amount = config.minAmount! + _random.nextInt(config.maxAmount! - config.minAmount! + 1);
        return CoinBonus(
          position: position,
          speed: _currentSpeed,
          amount: amount,
        );
        
      case BonusType.gems:
        final config = _config.gems!;
        final amount = config.minAmount! + _random.nextInt(config.maxAmount! - config.minAmount! + 1);
        return GemBonus(
          position: position,
          speed: _currentSpeed,
          amount: amount,
        );
    }
  }
  
  /// Select shield tier based on configured weights
  ShieldTier _selectShieldTier() {
    final weights = _config.shield?.shieldTierWeights;
    if (weights == null || weights.isEmpty) {
      return ShieldTier.blue; // Default to blue (most common)
    }
    
    final totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
    final roll = _random.nextDouble() * totalWeight;
    double cumulative = 0;
    
    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    
    return weights.keys.first;
  }
  
  // ============================================================================
  // COLLECTION HANDLING
  // ============================================================================
  
  /// Called when a bonus is collected by the player
  void handleBonusCollected(CollectibleBonus bonus, Map<String, dynamic> rewardData) {
    _bonusesCollectedThisLevel++;
    _activeBonuses.remove(bonus);
    
    // 🎯 Track rewards for analytics
    switch (bonus.bonusType) {
      case BonusType.shield:
        _totalShieldsCollected++;
        break;
      case BonusType.coins:
        _totalCoinsCollected += (rewardData['amount'] as int?) ?? 0;
        break;
      case BonusType.gems:
        _totalGemsCollected += (rewardData['amount'] as int?) ?? 0;
        break;
    }
    
    onBonusCollected?.call(bonus.bonusType, rewardData);
    
    safePrint('🎁 Bonus collected: ${bonus.bonusType.name}, total: $_bonusesCollectedThisLevel');
  }
  
  // ============================================================================
  // CLEANUP & STATE
  // ============================================================================
  
  /// Update active bonuses (remove dead ones)
  void update(double dt) {
    _activeBonuses.removeWhere((bonus) => !bonus.isMounted);
  }
  
  /// Clear all active bonuses (on level end/reset)
  void clear() {
    for (final bonus in _activeBonuses) {
      if (bonus.isMounted) {
        bonus.removeFromParent();
      }
    }
    _activeBonuses.clear();
  }
  
  /// Reset for new level
  void reset() {
    clear();
    _obstaclesPassed = 0;
    _obstaclesSinceLastBonus = 0;
    _bonusesSpawnedThisLevel = 0;
    _bonusesCollectedThisLevel = 0;
    _isPaused = false; // 🛑 Reset pause state
  }
  
  /// Get statistics for analytics
  Map<String, dynamic> getStats() => {
    'bonusesSpawned': _bonusesSpawnedThisLevel,
    'bonusesCollected': _bonusesCollectedThisLevel,
    'activeBonuses': _activeBonuses.length,
    // 🎯 Detailed reward tracking
    'shieldsCollected': _totalShieldsCollected,
    'coinsCollected': _totalCoinsCollected,
    'gemsCollected': _totalGemsCollected,
  };
  
  // ============================================================================
  // GETTERS
  // ============================================================================
  
  bool get isEnabled => _config.enabled;
  int get bonusesSpawnedThisLevel => _bonusesSpawnedThisLevel;
  int get bonusesCollectedThisLevel => _bonusesCollectedThisLevel;
  List<CollectibleBonus> get activeBonuses => List.unmodifiable(_activeBonuses);
  
  /// 🎯 Detailed reward tracking for analytics
  int get totalShieldsCollected => _totalShieldsCollected;
  int get totalCoinsCollected => _totalCoinsCollected;
  int get totalGemsCollected => _totalGemsCollected;
  bool get forceInsideGapOnly => _forceInsideGapOnly;
}

