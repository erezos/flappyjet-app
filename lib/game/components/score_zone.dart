import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
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
    }
  }
  
  /// Reset scoring state (for object pooling)
  void reset() {
    _scored = false;
  }
}

