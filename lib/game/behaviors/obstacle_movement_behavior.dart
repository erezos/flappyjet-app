import 'dart:math' as math;
import 'package:flame/components.dart';
import '../components/obstacle_movement_config.dart';

/// 🎮 Obstacle Movement Behavior
/// 
/// Applies movement patterns to obstacles during gameplay.
/// Implements Flame's Component-as-Behavior pattern for clean composition.
/// 
/// ✅ Flame Best Practices (2025):
/// - Zero allocations per frame (pre-calculated vectors)
/// - Works with any PositionComponent parent
/// - Configurable via immutable ObstacleMovementConfig
/// - Time-based movement (frame-rate independent)
/// - Fully testable in isolation
/// 
/// Supports:
/// - Vertical oscillation (sine wave up/down)
/// - Horizontal approach (accelerating towards player)
/// - Diagonal movement (constant velocity at angle)
/// 
/// Usage:
/// ```dart
/// final obstacle = DynamicObstacle(...);
/// obstacle.add(ObstacleMovementBehavior(
///   config: ObstacleMovementConfig.verticalOscillate(
///     amplitude: 30.0,
///     frequency: 0.5,
///   ),
///   basePositionY: obstacle.position.y,
/// ));
/// ```
class ObstacleMovementBehavior extends Component with ParentIsA<PositionComponent> {
  /// Movement configuration (immutable)
  final ObstacleMovementConfig config;
  
  /// Base Y position for oscillation (captured at spawn)
  final double basePositionY;
  
  /// Accumulated time for oscillation calculation
  double _elapsedTime = 0.0;
  
  /// Pre-calculated phase offset in radians
  late final double _phaseOffsetRadians;
  
  /// Screen bounds for clamping (prevents obstacles from going off-screen)
  double? minY;
  double? maxY;
  
  /// Whether to apply clamping to screen bounds
  final bool clampToScreen;

  ObstacleMovementBehavior({
    required this.config,
    required this.basePositionY,
    this.minY,
    this.maxY,
    this.clampToScreen = true,
  }) {
    _phaseOffsetRadians = config.phaseOffset * 2 * math.pi;
  }

  @override
  void update(double dt) {
    if (!config.hasMovement) return;
    
    _elapsedTime += dt;
    
    switch (config.type) {
      case MovementType.static:
        // No movement
        break;
        
      case MovementType.verticalOscillate:
        _applyVerticalOscillation();
        break;
        
      case MovementType.horizontalApproach:
        _applyHorizontalApproach(dt);
        break;
        
      case MovementType.diagonal:
        _applyDiagonalMovement(dt);
        break;
    }
    
    // Clamp to screen bounds if configured
    if (clampToScreen) {
      _clampToScreenBounds();
    }
  }

  /// Apply vertical oscillation (sine wave)
  void _applyVerticalOscillation() {
    // Calculate oscillation offset using sine wave
    // y = baseY + amplitude * sin(ωt + φ)
    final offset = config.amplitude * math.sin(
      config.angularFrequency * _elapsedTime + _phaseOffsetRadians,
    );
    
    parent.position.y = basePositionY + offset;
  }

  /// Apply horizontal approach (extra speed towards player)
  void _applyHorizontalApproach(double dt) {
    // Add extra horizontal velocity (negative = moving left towards player)
    parent.position.x -= config.approachSpeed * dt;
  }

  /// Apply diagonal movement
  void _applyDiagonalMovement(double dt) {
    // Apply velocity components
    // Note: X is typically handled by base obstacle speed,
    // but diagonal can add/subtract from it
    parent.position.x -= config.diagonalVelocityX * dt;
    parent.position.y += config.diagonalVelocityY * dt;
  }

  /// Clamp position to screen bounds (prevent going off-screen)
  void _clampToScreenBounds() {
    if (minY != null) {
      parent.position.y = math.max(parent.position.y, minY!);
    }
    if (maxY != null) {
      parent.position.y = math.min(parent.position.y, maxY!);
    }
  }

  /// Reset elapsed time (for behavior reuse)
  void reset() {
    _elapsedTime = 0.0;
  }

  /// Get current oscillation phase (0-1, useful for debugging/sync)
  double get oscillationPhase {
    if (config.type != MovementType.verticalOscillate) return 0.0;
    
    final phase = (config.angularFrequency * _elapsedTime + _phaseOffsetRadians) / (2 * math.pi);
    return phase - phase.floor(); // Normalize to 0-1
  }

  /// Get current offset from base position
  Vector2 get currentOffset {
    switch (config.type) {
      case MovementType.static:
        return Vector2.zero();
        
      case MovementType.verticalOscillate:
        return Vector2(0, parent.position.y - basePositionY);
        
      case MovementType.horizontalApproach:
      case MovementType.diagonal:
        // These modify absolute position, offset tracking not meaningful
        return Vector2.zero();
    }
  }

  @override
  String toString() => 'ObstacleMovementBehavior(${config.type.name}, elapsed: ${_elapsedTime.toStringAsFixed(2)}s)';
}

/// Extension for easy behavior attachment to obstacles
extension ObstacleMovementExtension on PositionComponent {
  /// Add movement behavior to this component
  Future<ObstacleMovementBehavior> addMovementBehavior({
    required ObstacleMovementConfig config,
    double? minY,
    double? maxY,
    bool clampToScreen = true,
  }) async {
    final behavior = ObstacleMovementBehavior(
      config: config,
      basePositionY: position.y,
      minY: minY,
      maxY: maxY,
      clampToScreen: clampToScreen,
    );
    
    await add(behavior);
    return behavior;
  }
  
  /// Find movement behavior if attached
  ObstacleMovementBehavior? get movementBehavior {
    try {
      return children.whereType<ObstacleMovementBehavior>().firstOrNull;
    } catch (_) {
      return null;
    }
  }
}

