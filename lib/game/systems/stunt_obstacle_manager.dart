/// 🎪 STUNT TOURNAMENT - Obstacle Manager
/// 
/// Manages spawning and lifecycle of StuntObstacle components.
/// Designed for time-based survival levels where player must dodge
/// single obstacles moving vertically.
/// 
/// ✅ Implements ObstacleSpawner interface for unified obstacle system
/// ✅ Flame Best Practices:
/// - Extends Component for integration with game loop
/// - Configurable spawn frequency and obstacle parameters
/// - Pool-based management for performance
/// - Clean separation of concerns
library;

import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../components/stunt_obstacle.dart';
import 'obstacle_spawner.dart';

/// Configuration for the stunt obstacle manager
class StuntObstacleManagerConfig {
  /// Base spawn interval in seconds
  final double spawnInterval;
  
  /// Randomness factor for spawn timing (0-1)
  /// 0 = fixed interval, 1 = interval ± 100%
  final double spawnVariance;
  
  /// Base obstacle configuration
  final StuntObstacleConfig obstacleConfig;
  
  /// Minimum vertical position for spawning (0-1 of playable height)
  final double minSpawnYPercent;
  
  /// Maximum vertical position for spawning (0-1 of playable height)
  final double maxSpawnYPercent;
  
  /// Whether to stagger phase offsets for variety
  final bool staggerPhases;

  /// If true, only one obstacle is allowed onscreen at a time.
  /// Prevents overlapping obstacles and keeps the flow “one pillar” style.
  final bool oneAtATime;
  
  const StuntObstacleManagerConfig({
    this.spawnInterval = 3.0,
    this.spawnVariance = 0.1,
    this.obstacleConfig = const StuntObstacleConfig(),
    this.minSpawnYPercent = 0.2,
    this.maxSpawnYPercent = 0.8,
    this.staggerPhases = true,
    this.oneAtATime = true,
  });
  
  /// Create from JSON tournament level config
  factory StuntObstacleManagerConfig.fromJson(Map<String, dynamic> json) {
    return StuntObstacleManagerConfig(
      spawnInterval: (json['spawn_interval'] as num?)?.toDouble() ?? 3.0,
      spawnVariance: (json['spawn_variance'] as num?)?.toDouble() ?? 0.1,
      obstacleConfig: json['obstacle'] != null
          ? StuntObstacleConfig.fromJson(json['obstacle'] as Map<String, dynamic>)
          : const StuntObstacleConfig(),
      minSpawnYPercent: (json['min_spawn_y_percent'] as num?)?.toDouble() ?? 0.2,
      maxSpawnYPercent: (json['max_spawn_y_percent'] as num?)?.toDouble() ?? 0.8,
      staggerPhases: json['stagger_phases'] as bool? ?? true,
      oneAtATime: json['one_at_a_time'] as bool? ?? true,
    );
  }
  
  @override
  String toString() => 'StuntObstacleManagerConfig(interval:$spawnInterval±$spawnVariance, obstacle:$obstacleConfig)';
}

/// Manages stunt obstacle spawning and lifecycle
/// 
/// Implements ObstacleSpawner for unified obstacle system integration.
class StuntObstacleManager extends ObstacleSpawner {
  /// Configuration (mutable to allow runtime changes)
  StuntObstacleManagerConfig _config;
  StuntObstacleManagerConfig get config => _config;
  
  /// Random number generator
  final math.Random _random;
  
  /// Time until next spawn
  double _timeUntilSpawn = 0.0;
  
  /// Number of obstacles spawned (for phase staggering)
  int _spawnCount = 0;
  
  /// Whether spawning is active
  bool _isSpawning = false;
  
  /// Whether spawning is paused (obstacles still move)
  bool _isPausedFlag = false;
  
  /// Active obstacles (for cleanup/tracking)
  final List<StuntObstacle> _activeObstacles = [];
  
  /// Override asset path (set via setAssetPath)
  String? _overrideAssetPath;
  
  StuntObstacleManager({
    required StuntObstacleManagerConfig config,
    math.Random? random,
  }) : _config = config,
       _random = random ?? math.Random();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    safePrint('🎪 StuntObstacleManager loaded with config: $config');
  }
  
  // ============================================================================
  // ObstacleSpawner Interface Implementation
  // ============================================================================
  
  @override
  void startSpawning() {
    _isSpawning = true;
    _isPausedFlag = false;
    _timeUntilSpawn = _getNextSpawnInterval() * 0.5; // First spawn sooner
    safePrint('🎪 Started obstacle spawning');
  }
  
  @override
  void stopSpawning() {
    _isSpawning = false;
    safePrint('🎪 Stopped obstacle spawning');
  }
  
  @override
  void pause() {
    _isPausedFlag = true;
    safePrint('🎪 Obstacle spawning PAUSED');
  }
  
  @override
  void resume() {
    _isPausedFlag = false;
    safePrint('🎪 Obstacle spawning RESUMED');
  }
  
  @override
  void clearObstacles() {
    for (final obstacle in _activeObstacles) {
      obstacle.removeFromParent();
    }
    _activeObstacles.clear();
    _spawnCount = 0;
    safePrint('🎪 Cleared all obstacles');
  }
  
  @override
  void reset() {
    stopSpawning();
    clearObstacles();
    _timeUntilSpawn = 0.0;
    _isPausedFlag = false;
  }
  
  @override
  bool get isPaused => _isPausedFlag;
  
  @override
  int get activeObstacleCount => _activeObstacles.length;
  
  @override
  int get totalSpawned => _spawnCount;
  
  @override
  void Function()? onObstaclePassed;
  
  @override
  void Function()? onObstacleCollision;
  
  @override
  void setAssetPath(String? path) {
    _overrideAssetPath = path;
    safePrint('🎪 Asset path set to: $path');
  }
  
  @override
  void setDifficulty({
    double? spawnInterval,
    double? scrollSpeed,
    Map<String, dynamic>? additionalParams,
  }) {
    _config = StuntObstacleManagerConfig(
      spawnInterval: spawnInterval ?? _config.spawnInterval,
      spawnVariance: _config.spawnVariance,
      obstacleConfig: _config.obstacleConfig.copyWith(
        scrollSpeed: scrollSpeed,
        assetPath: additionalParams?['asset_path'] as String?,
        sizePercent: (additionalParams?['size_percent'] as num?)?.toDouble(),
        verticalAmplitudePercent: (additionalParams?['vertical_amplitude_percent'] as num?)?.toDouble(),
        verticalFrequency: (additionalParams?['vertical_frequency'] as num?)?.toDouble(),
      ),
      minSpawnYPercent: _config.minSpawnYPercent,
      maxSpawnYPercent: _config.maxSpawnYPercent,
      staggerPhases: _config.staggerPhases,
    );
    safePrint('🎪 Difficulty updated: interval=$spawnInterval, speed=$scrollSpeed');
  }
  
  // ============================================================================
  // Update Loop
  // ============================================================================
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Always update existing obstacles (even when paused)
    // This is handled by Flame's component tree, obstacles update themselves
    
    // Clean up removed obstacles from tracking list
    _activeObstacles.removeWhere((o) => o.isRemoved);
    
    // Skip spawning if not active or paused
    if (!_isSpawning || _isPausedFlag) return;
    
    // Update spawn timer
    _timeUntilSpawn -= dt;
    
    if (_timeUntilSpawn <= 0) {
      _spawnObstacle();
      _timeUntilSpawn = _getNextSpawnInterval();
    }
  }
  
  /// Get next spawn interval with variance
  double _getNextSpawnInterval() {
    final variance = config.spawnInterval * config.spawnVariance;
    return config.spawnInterval + (_random.nextDouble() * 2 - 1) * variance;
  }
  
  /// Spawn a new obstacle
  void _spawnObstacle() {
    // Gate spawning if only one obstacle should exist at a time
    if (config.oneAtATime) {
      final hasActive = _activeObstacles.any((o) => !o.isRemoved);
      if (hasActive) {
        safePrint('🎪 Spawn skipped (oneAtATime active, obstacle already present)');
        return;
      }
    }

    // Calculate spawn position
    final screenWidth = game.size.x;
    final playableHeight = game.size.y - 50; // Above ground
    
    // Random Y within spawn range
    final minY = playableHeight * _config.minSpawnYPercent;
    final maxY = playableHeight * _config.maxSpawnYPercent;
    final startY = minY + _random.nextDouble() * (maxY - minY);
    
    // Calculate phase offset for staggered movement
    final phaseOffset = _config.staggerPhases 
        ? (_spawnCount * 0.25) % 1.0 
        : 0.0;
    
    // Create obstacle config with phase offset and override asset
    final obstacleConfig = _config.obstacleConfig.copyWith(
      phaseOffset: phaseOffset,
      assetPath: _overrideAssetPath,
    );
    
    // Compute startX far enough off-screen to avoid visible spawning
    final obstacleWidth = screenWidth * obstacleConfig.sizePercent;
    final startX = screenWidth + (obstacleWidth / 2) + 50; // left edge ~50px off-screen
    
    // Create obstacle with collision callback wrapper
    final obstacle = StuntObstacle(
      config: obstacleConfig,
      startY: startY,
      startPosition: Vector2(startX, startY),
      onPlayerCollision: _handleObstacleCollision,
      onPassed: _handleObstaclePassed,
    );
    
    // Add to game world and track (obstacles must be in world for camera to see them)
    final world = parent;
    if (world != null) {
      world.add(obstacle);
    } else {
      // Fallback: add directly to game (won't be visible through camera!)
      game.add(obstacle);
      safePrint('🎪 ⚠️ WARNING: No parent found, obstacle may not be visible');
    }
    _activeObstacles.add(obstacle);
    _spawnCount++;
    safePrint('🎪 Spawned obstacle #$_spawnCount at (${startX.toInt()}, ${startY.toInt()})');
  }
  
  /// Handle obstacle collision event
  void _handleObstacleCollision(StuntObstacle obstacle) {
    onObstacleCollision?.call();
  }
  
  /// Handle obstacle passed event
  void _handleObstaclePassed(StuntObstacle obstacle) {
    onObstaclePassed?.call();
  }
  
  // ============================================================================
  // Additional Getters
  // ============================================================================
  
  /// Get obstacles that are currently visible on screen
  List<StuntObstacle> get visibleObstacles {
    return _activeObstacles.where((o) {
      return o.position.x > -o.size.x && o.position.x < game.size.x + o.size.x;
    }).toList();
  }
  
  /// Get all active obstacles
  List<StuntObstacle> get activeObstacles => List.unmodifiable(_activeObstacles);
}

