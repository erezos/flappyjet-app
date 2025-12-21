import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../models/bonus_config.dart';

/// 🎁 Base class for all collectible bonuses
/// 
/// Features:
/// - Floating animation (bob up/down)
/// - Glow/pulse effect
/// - Collision detection with player
/// - Auto-removal when off-screen or collected
/// 
/// NOTE: We extend PositionComponent instead of SpriteComponent because
/// asset loading may fail and we need graceful fallback to procedural rendering.
/// SpriteComponent has a hard assertion that sprite != null in onMount().
/// 
/// Subclasses must implement:
/// - [onCollected] - Apply the bonus effect
/// - [bonusType] - Return the bonus type
/// - [loadBonusSprite] - Load sprite or leave null for procedural fallback
abstract class CollectibleBonus extends PositionComponent with HasGameReference {
  /// Optional sprite (may be null if asset loading fails)
  Sprite? sprite;
  /// Whether this bonus has been collected
  bool _isCollected = false;
  
  /// The bonus type for analytics/tracking
  BonusType get bonusType;
  
  /// Speed at which the bonus moves left (matches obstacle speed)
  final double speed;
  
  /// Size of the bonus sprite
  final double bonusSize;
  
  /// Glow color for the bonus
  final Color glowColor;
  
  /// Animation state
  double _bobTime = 0.0;
  double _glowTime = 0.0;
  
  /// Bob animation settings
  static const double _bobAmount = 8.0;
  static const double _bobSpeed = 3.0;
  
  /// Glow animation settings
  static const double _glowSpeed = 4.0;
  static const double _minGlowOpacity = 0.3;
  static const double _maxGlowOpacity = 0.8;
  
  /// Starting Y position for bob animation
  late double _startY;
  
  CollectibleBonus({
    required Vector2 position,
    required this.speed,
    this.bonusSize = 48.0,
    this.glowColor = Colors.white,
  }) : super(
    position: position,
    size: Vector2.all(bonusSize),
    anchor: Anchor.center,
  );
  
  /// Whether this bonus has been collected
  bool get isCollected => _isCollected;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _startY = position.y;
    
    // Load the bonus sprite (implemented by subclasses)
    await loadBonusSprite();
    
    // Add circular hitbox for collision detection
    // Use passive type - jet (active) will detect collision with us
    await add(CircleHitbox(
      radius: bonusSize * 0.4, // Slightly smaller than visual for fair gameplay
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));
    
    // Add spawn animation (scale in)
    scale = Vector2.all(0.0);
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3, curve: Curves.elasticOut),
    ));
    
    safePrint('🎁 ${bonusType.name} bonus spawned at (${position.x.toInt()}, ${position.y.toInt()})');
  }
  
  /// Load the sprite for this bonus type (implemented by subclasses)
  Future<void> loadBonusSprite();
  
  /// Called when the player collects this bonus
  /// Returns the reward data for analytics/UI feedback
  Future<Map<String, dynamic>> onCollected();
  
  /// Mark this bonus as collected and trigger effects
  Future<Map<String, dynamic>> collect() async {
    if (_isCollected) {
      return {'alreadyCollected': true};
    }
    
    _isCollected = true;
    
    // Get reward data from subclass
    final rewardData = await onCollected();
    
    // Play collection animation
    _playCollectionAnimation();
    
    safePrint('🎁 ${bonusType.name} bonus collected! Reward: $rewardData');
    
    return rewardData;
  }
  
  /// Play the collection animation and remove
  void _playCollectionAnimation() {
    // Scale up then remove (no OpacityEffect - PositionComponent doesn't support it)
    add(ScaleEffect.to(
      Vector2.all(1.5),
      EffectController(duration: 0.2, curve: Curves.easeOut),
      onComplete: () {
        removeFromParent();
      },
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isCollected) return;
    
    // Move left (same as obstacles)
    position.x -= speed * dt;
    
    // Bob animation
    _bobTime += dt;
    final bobOffset = math.sin(_bobTime * _bobSpeed) * _bobAmount;
    position.y = _startY + bobOffset;
    
    // Glow animation
    _glowTime += dt;
    
    // Remove when off-screen
    if (position.x < -bonusSize) {
      safePrint('🎁 ${bonusType.name} bonus went off-screen (not collected)');
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Subclasses should handle their own glow effects
    // Base class only renders sprite if available
    if (sprite != null) {
      sprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    }
    // If no sprite, subclasses should override render() to draw procedurally
  }
  
  /// Render the sprite with custom glow (helper for subclasses)
  void renderSpriteWithGlow(Canvas canvas) {
    _renderGlow(canvas);
    if (sprite != null) {
      sprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    }
  }
  
  /// Render the pulsing glow effect
  void _renderGlow(Canvas canvas) {
    final glowPhase = math.sin(_glowTime * _glowSpeed);
    final glowOpacity = _minGlowOpacity + (glowPhase + 1) / 2 * (_maxGlowOpacity - _minGlowOpacity);
    
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowOpacity * 0.5) // Fixed: removed *255, withValues expects 0.0-1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, bonusSize * 0.3);
    
    final center = size / 2;
    canvas.drawCircle(
      Offset(center.x, center.y),
      bonusSize * 0.5,
      glowPaint,
    );
  }
  
  /// Create particle burst effect on collection
  /// Override in subclasses for custom particles
  void createCollectionParticles() {
    // Default implementation - can be overridden
    safePrint('🎁 Creating collection particles for ${bonusType.name}');
  }
}

/// Mixin for bonuses that need trail animation to HUD
mixin RewardTrailAnimation on CollectibleBonus {
  /// Create a trail animation from bonus position to target HUD position
  /// [targetPosition] - Screen position of the HUD element
  /// [particleColor] - Color of the trail particles
  /// [onArrival] - Callback when trail reaches destination
  void createRewardTrail({
    required Vector2 targetPosition,
    required Color particleColor,
    VoidCallback? onArrival,
  }) {
    // Trail animation is created by the game/HUD system
    // This mixin provides the interface for the bonus to request it
    safePrint('🎁 Reward trail requested: ${position.x.toInt()},${position.y.toInt()} → ${targetPosition.x.toInt()},${targetPosition.y.toInt()}');
  }
}

