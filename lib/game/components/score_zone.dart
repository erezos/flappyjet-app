import 'package:flame/components.dart';
import 'package:flame/effects.dart'; // ✅ REFACTOR v1.7.0 Phase 3: Effect system for animations
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';

/// Invisible score trigger zone for detecting when player passes obstacles
/// ✅ REFACTOR v1.7.0: Uses Flame's collision system for score detection
class ScoreZone extends PositionComponent {
  bool _scored = false;
  
  /// Whether this zone has already been scored
  bool get hasScored => _scored;
  
  ScoreZone({
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
    anchor: Anchor.topLeft,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add hitbox for score detection
    // Passive type: only gets checked by active components (jet)
    await add(RectangleHitbox(
      size: size,
      anchor: Anchor.topLeft,
      collisionType: CollisionType.passive,
    ));
    
    safePrint('🎯 ScoreZone created at x=${position.x}, width=${size.x}, height=${size.y}');
  }
  
  /// Mark this zone as scored
  void markScored() {
    if (!_scored) {
      _scored = true;
      safePrint('✅ ScoreZone marked as scored at x=${position.x}');
      
      // ✅ REFACTOR v1.7.0 Phase 3: Trigger celebration effects
      onScored();
    }
  }
  
  /// ✅ REFACTOR v1.7.0 Phase 3: Celebration effects when scored
  /// Provides visual feedback for successful obstacle pass
  void onScored() {
    // Scale pulse effect (grow then shrink back)
    // Note: ScoreZone is invisible, so this effect won't be visible
    // but we keep it for consistency and potential debug rendering in the future
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.5),
          EffectController(duration: 0.2, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.2, curve: Curves.easeIn),
        ),
      ]),
    );
    
    // ColorEffect removed: ScoreZone doesn't have HasPaint mixin
    // (it's an invisible collision zone, not a rendered component)
  }
  
  /// Reset scoring state (for object pooling)
  void reset() {
    _scored = false;
  }
}

