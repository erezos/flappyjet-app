/// 🎮 OBSTACLE SPAWNER - Unified Interface
/// 
/// Defines a common interface for all obstacle spawning systems.
/// This allows FlappyGame to work with different obstacle types:
/// - Traditional two-pillar obstacles (DynamicObstacle via ObstacleManager)
/// - Single moving obstacles (StuntObstacle via StuntObstacleManager)
/// - Future obstacle types (diagonal barriers, rotating obstacles, etc.)
/// 
/// ✅ Design Patterns:
/// - Strategy Pattern: Different spawners implement the same interface
/// - Factory Pattern: Create spawners based on configuration
/// - Composition over inheritance: Spawners are components, not subclasses
/// 
/// ✅ Flame Best Practices:
/// - All spawners work as Flame Components
/// - Zero allocations per frame
/// - Testable in isolation
library;

import 'package:flame/components.dart';

/// Types of obstacles that can be spawned
enum ObstacleType {
  /// Two pillars with a gap (classic Flappy Bird style)
  pillarPair,
  
  /// Single obstacle that moves vertically
  singleVertical,
  
  /// Single obstacle that approaches horizontally (faster than base scroll)
  singleApproaching,
  
  /// Single obstacle that moves diagonally
  singleDiagonal,
  
  /// Mixed: Spawns a variety of obstacle types
  mixed,
}

/// Configuration for the obstacle spawning system
class ObstacleSpawnerConfig {
  /// Primary obstacle type to spawn
  final ObstacleType primaryType;
  
  /// For mixed mode: weights for each obstacle type (0-100)
  final Map<ObstacleType, int>? typeWeights;
  
  /// Base spawn interval in seconds
  final double spawnInterval;
  
  /// Variance in spawn timing (0-1)
  final double spawnVariance;
  
  /// Horizontal scroll speed (pixels/second)
  final double scrollSpeed;
  
  /// Asset path for obstacles
  final String? assetPath;
  
  /// Additional type-specific parameters
  final Map<String, dynamic> params;
  
  const ObstacleSpawnerConfig({
    this.primaryType = ObstacleType.pillarPair,
    this.typeWeights,
    this.spawnInterval = 2.5,
    this.spawnVariance = 0.2,
    this.scrollSpeed = 150.0,
    this.assetPath,
    this.params = const {},
  });
  
  /// Create config for traditional pillar-pair obstacles
  factory ObstacleSpawnerConfig.pillarPair({
    double spawnInterval = 2.5,
    double scrollSpeed = 150.0,
    double gapSize = 350.0,
    double maxGapShift = 50.0,
    String? assetPath,
  }) {
    return ObstacleSpawnerConfig(
      primaryType: ObstacleType.pillarPair,
      spawnInterval: spawnInterval,
      scrollSpeed: scrollSpeed,
      assetPath: assetPath,
      params: {
        'gap_size': gapSize,
        'max_gap_shift': maxGapShift,
      },
    );
  }
  
  /// Create config for single vertical-moving obstacles
  factory ObstacleSpawnerConfig.singleVertical({
    double spawnInterval = 2.5,
    double scrollSpeed = 150.0,
    double sizePercent = 0.15,
    double verticalAmplitude = 0.35,
    double verticalFrequency = 0.4,
    String? assetPath,
  }) {
    return ObstacleSpawnerConfig(
      primaryType: ObstacleType.singleVertical,
      spawnInterval: spawnInterval,
      scrollSpeed: scrollSpeed,
      assetPath: assetPath,
      params: {
        'size_percent': sizePercent,
        'vertical_amplitude_percent': verticalAmplitude,
        'vertical_frequency': verticalFrequency,
      },
    );
  }
  
  /// Create config for mixed obstacle types
  factory ObstacleSpawnerConfig.mixed({
    required Map<ObstacleType, int> typeWeights,
    double spawnInterval = 2.5,
    double scrollSpeed = 150.0,
    String? assetPath,
    Map<String, dynamic> params = const {},
  }) {
    return ObstacleSpawnerConfig(
      primaryType: ObstacleType.mixed,
      typeWeights: typeWeights,
      spawnInterval: spawnInterval,
      scrollSpeed: scrollSpeed,
      assetPath: assetPath,
      params: params,
    );
  }
  
  /// Create from JSON (e.g., from tournaments.json)
  factory ObstacleSpawnerConfig.fromJson(Map<String, dynamic> json) {
    final typeStr = json['obstacle_type'] as String? ?? 'pillar_pair';
    final primaryType = _parseObstacleType(typeStr);
    
    Map<ObstacleType, int>? typeWeights;
    if (json['type_weights'] != null) {
      final weightsJson = json['type_weights'] as Map<String, dynamic>;
      typeWeights = weightsJson.map((key, value) => 
        MapEntry(_parseObstacleType(key), (value as num).toInt())
      );
    }
    
    return ObstacleSpawnerConfig(
      primaryType: primaryType,
      typeWeights: typeWeights,
      spawnInterval: (json['spawn_interval'] as num?)?.toDouble() ?? 2.5,
      spawnVariance: (json['spawn_variance'] as num?)?.toDouble() ?? 0.2,
      scrollSpeed: (json['scroll_speed'] as num?)?.toDouble() ?? 150.0,
      assetPath: json['asset_path'] as String?,
      params: json['params'] as Map<String, dynamic>? ?? const {},
    );
  }
  
  static ObstacleType _parseObstacleType(String str) {
    switch (str) {
      case 'pillar_pair':
      case 'pillarPair':
        return ObstacleType.pillarPair;
      case 'single_vertical':
      case 'singleVertical':
        return ObstacleType.singleVertical;
      case 'single_approaching':
      case 'singleApproaching':
        return ObstacleType.singleApproaching;
      case 'single_diagonal':
      case 'singleDiagonal':
        return ObstacleType.singleDiagonal;
      case 'mixed':
        return ObstacleType.mixed;
      default:
        return ObstacleType.pillarPair;
    }
  }
  
  @override
  String toString() => 'ObstacleSpawnerConfig(type: $primaryType, interval: $spawnInterval)';
}

/// Abstract interface for obstacle spawners
/// 
/// All obstacle spawning systems implement this interface, allowing
/// FlappyGame to work with any type of obstacle system.
abstract class ObstacleSpawner extends Component with HasGameReference {
  /// Start spawning obstacles
  void startSpawning();
  
  /// Stop spawning obstacles
  void stopSpawning();
  
  /// Pause spawning (but keep existing obstacles moving)
  void pause();
  
  /// Resume spawning
  void resume();
  
  /// Clear all obstacles
  void clearObstacles();
  
  /// Reset to initial state
  void reset();
  
  /// Check if spawning is paused
  bool get isPaused;
  
  /// Get count of active obstacles
  int get activeObstacleCount;
  
  /// Get total obstacles spawned
  int get totalSpawned;
  
  /// Callback when player passes an obstacle (for scoring)
  void Function()? onObstaclePassed;
  
  /// Callback when player collides with obstacle
  void Function()? onObstacleCollision;
  
  /// Update story mode asset path
  void setAssetPath(String? path);
  
  /// Update difficulty settings
  void setDifficulty({
    double? spawnInterval,
    double? scrollSpeed,
    Map<String, dynamic>? additionalParams,
  });
}

/// Adapter to wrap existing ObstacleManager as an ObstacleSpawner
/// 
/// This allows the existing pillar-pair obstacle system to work
/// with the new unified interface without major refactoring.
class PillarPairSpawnerAdapter extends ObstacleSpawner {
  // We'll keep a reference to the actual manager
  // For now, this adapter just provides the interface
  
  bool _isPaused = false;
  bool _isActive = false;
  int _spawnCount = 0;
  
  @override
  void startSpawning() {
    _isActive = true;
  }
  
  @override
  void stopSpawning() {
    _isActive = false;
  }
  
  @override
  void pause() {
    _isPaused = true;
  }
  
  @override
  void resume() {
    _isPaused = false;
  }
  
  @override
  void clearObstacles() {
    _spawnCount = 0;
  }
  
  @override
  void reset() {
    _isPaused = false;
    _isActive = false;
    _spawnCount = 0;
  }
  
  @override
  bool get isPaused => _isPaused;
  
  /// Whether spawning is currently active
  bool get isActive => _isActive;
  
  @override
  int get activeObstacleCount => 0; // Managed by original ObstacleManager
  
  @override
  int get totalSpawned => _spawnCount;
  
  @override
  void Function()? onObstaclePassed;
  
  @override
  void Function()? onObstacleCollision;
  
  @override
  void setAssetPath(String? path) {
    // Delegated to original ObstacleManager
  }
  
  @override
  void setDifficulty({
    double? spawnInterval,
    double? scrollSpeed,
    Map<String, dynamic>? additionalParams,
  }) {
    // Delegated to original ObstacleManager
  }
}

