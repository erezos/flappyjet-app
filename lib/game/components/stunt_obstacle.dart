/// 🎪 STUNT TOURNAMENT - Single Moving Obstacle
/// 
/// A single-sprite obstacle that moves vertically for stunt tournaments.
/// Unlike DynamicObstacle (two pillars with gap), this is a SINGLE obstacle
/// that players must dodge by flying above or below it.
/// 
/// ✅ Flame Best Practices:
/// - Extends PositionComponent with collision detection
/// - Uses ObstacleMovementBehavior for vertical oscillation
/// - Responsive sizing based on screen dimensions
/// - Zero allocations per frame
/// 
/// Configuration:
/// - obstacleSize: Width/height of the obstacle sprite
/// - speed: Horizontal scroll speed (pixels/second)
/// - verticalSpeed: Speed of vertical oscillation
/// - verticalRange: How far up/down the obstacle moves
library;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../behaviors/obstacle_movement_behavior.dart';
import 'obstacle_movement_config.dart';

/// Configuration for stunt obstacles
class StuntObstacleConfig {
  /// Size of the obstacle (responsive - percentage of screen width)
  final double sizePercent;
  
  /// Horizontal scroll speed (pixels/second)
  final double scrollSpeed;
  
  /// Vertical oscillation amplitude (percentage of playable height)
  final double verticalAmplitudePercent;
  
  /// Vertical oscillation frequency (Hz - cycles per second)
  final double verticalFrequency;
  
  /// Asset path for the obstacle sprite
  final String assetPath;
  
  /// Phase offset for staggered movement (0-1)
  final double phaseOffset;
  
  const StuntObstacleConfig({
    this.sizePercent = 0.2, // match regular pillar footprint
    this.scrollSpeed = 200.0,
    this.verticalAmplitudePercent = 0.18,
    this.verticalFrequency = 0.6,
    this.assetPath = 'obstacles/desert_obstacles.png',
    this.phaseOffset = 0.0,
  });
  
  /// Create from JSON tournament config
  factory StuntObstacleConfig.fromJson(Map<String, dynamic> json) {
    return StuntObstacleConfig(
      sizePercent: (json['size_percent'] as num?)?.toDouble() ?? 0.2,
      scrollSpeed: (json['scroll_speed'] as num?)?.toDouble() ?? 200.0,
      verticalAmplitudePercent: (json['vertical_amplitude_percent'] as num?)?.toDouble() ?? 0.18,
      verticalFrequency: (json['vertical_frequency'] as num?)?.toDouble() ?? 0.6,
      assetPath: json['asset_path'] as String? ?? 'obstacles/desert_obstacles.png',
      phaseOffset: (json['phase_offset'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Copy with modifications
  StuntObstacleConfig copyWith({
    double? sizePercent,
    double? scrollSpeed,
    double? verticalAmplitudePercent,
    double? verticalFrequency,
    String? assetPath,
    double? phaseOffset,
  }) {
    return StuntObstacleConfig(
      sizePercent: sizePercent ?? this.sizePercent,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      verticalAmplitudePercent: verticalAmplitudePercent ?? this.verticalAmplitudePercent,
      verticalFrequency: verticalFrequency ?? this.verticalFrequency,
      assetPath: assetPath ?? this.assetPath,
      phaseOffset: phaseOffset ?? this.phaseOffset,
    );
  }
  
  @override
  String toString() => 'StuntObstacleConfig(size:${(sizePercent*100).toInt()}%, speed:$scrollSpeed, amp:${(verticalAmplitudePercent*100).toInt()}%, freq:${verticalFrequency}Hz)';
}

/// Single moving obstacle for stunt tournaments
class StuntObstacle extends PositionComponent with HasGameReference, CollisionCallbacks {
  /// Configuration for this obstacle
  final StuntObstacleConfig config;
  
  /// Starting Y position (center of vertical oscillation)
  final double startY;
  
  /// Sprite component for rendering
  SpriteComponent? _sprite;
  
  /// Movement behavior for vertical oscillation
  ObstacleMovementBehavior? _movementBehavior;
  
  /// Whether obstacle has been loaded
  bool _isLoaded = false;
  
  /// Whether this obstacle has been passed (for scoring)
  bool hasBeenPassed = false;
  
  /// Callback when player collides with this obstacle
  final void Function(StuntObstacle)? onPlayerCollision;
  
  /// Callback when player passes this obstacle (for scoring)
  final void Function(StuntObstacle)? onPassed;
  
  StuntObstacle({
    required this.config,
    required this.startY,
    required Vector2 startPosition,
    this.onPlayerCollision,
    this.onPassed,
  }) : super(
    position: startPosition,
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Calculate responsive size based on screen dimensions
    final screenWidth = game.size.x;
    final obstacleSize = screenWidth * config.sizePercent;
    size = Vector2(obstacleSize, obstacleSize);
    
    // Load sprite
    try {
      final sprite = await Sprite.load(config.assetPath);
      _sprite = SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
      );
      add(_sprite!);
    } catch (e) {
      safePrint('🎪 ⚠️ Failed to load stunt obstacle sprite: ${config.assetPath} - $e');
      _createFallbackVisual();
    }
    
    // Add collision hitbox
    final hitbox = RectangleHitbox(
      size: size * 0.9, // Slightly smaller hitbox for fair gameplay
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    );
    add(hitbox);
    
    // Add vertical movement behavior
    await _addMovementBehavior();
    
    _isLoaded = true;
  }
  
  /// Add vertical oscillation movement
  Future<void> _addMovementBehavior() async {
    // Calculate playable height (screen height minus ground area)
    const groundOffset = 50.0; // Same as jet collision boundary
    final playableHeight = game.size.y - groundOffset;
    
    // Calculate amplitude in pixels
    final amplitude = playableHeight * config.verticalAmplitudePercent;
    
    // Calculate bounds to keep obstacle fully on screen
    final minY = size.y / 2 + 20; // Top margin
    final maxY = playableHeight - size.y / 2 - 20; // Bottom margin (above ground)
    
    final movementConfig = ObstacleMovementConfig.verticalOscillate(
      amplitude: amplitude,
      frequency: config.verticalFrequency,
      phaseOffset: config.phaseOffset,
    );
    
    _movementBehavior = ObstacleMovementBehavior(
      config: movementConfig,
      basePositionY: startY,
      minY: minY,
      maxY: maxY,
      clampToScreen: true,
    );
    
    await add(_movementBehavior!);
  }
  
  /// Create fallback visual when sprite fails to load
  void _createFallbackVisual() {
    final fallback = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.orange.withValues(alpha: 0.8),
      anchor: Anchor.center,
    );
    add(fallback);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle to the left (horizontal scroll)
    position.x -= config.scrollSpeed * dt;
    
    // Check if obstacle has been passed by player (jet is at x ~= 100)
    if (!hasBeenPassed && position.x + size.x / 2 < 100) {
      hasBeenPassed = true;
      onPassed?.call(this);
    }
    
    // Remove when off screen (left side)
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (!_isLoaded) {
      // Show loading placeholder
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        paint,
      );
      return;
    }
    
    super.render(canvas);
  }
  
  /// Get collision bounds for this obstacle
  Rect getCollisionBounds() {
    return Rect.fromCenter(
      center: position.toOffset(),
      width: size.x * 0.9,
      height: size.y * 0.9,
    );
  }
  
  /// Get current movement offset (for debugging)
  Vector2 get currentOffset => _movementBehavior?.currentOffset ?? Vector2.zero();
  
  /// Get oscillation phase (0-1)
  double get oscillationPhase => _movementBehavior?.oscillationPhase ?? 0.0;
  
  @override
  String toString() => 'StuntObstacle(pos: ${position.x.toInt()},${position.y.toInt()}, passed: $hasBeenPassed)';
}

