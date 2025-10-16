import 'package:flame/components.dart';
import '../core/game_config.dart';

/// Handles jump mechanic with cooldown system
/// 
/// ✅ REFACTOR v1.7.0: Flame Component Behavior Pattern (2025)
/// 
/// Features:
/// - Jump cooldown to prevent spam
/// - Configurable jump force
/// - Zero allocations per frame
/// - Clean separation from component logic
/// 
/// Usage:
/// ```dart
/// class PlayerComponent extends PositionComponent {
///   final velocity = Vector2.zero();
///   late final JumpBehavior jumpBehavior;
///   
///   @override
///   Future<void> onLoad() async {
///     jumpBehavior = JumpBehavior(velocity: velocity);
///     await add(jumpBehavior);
///   }
///   
///   void onTap() {
///     jumpBehavior.jump();
///   }
/// }
/// ```
class JumpBehavior extends Component {
  /// The velocity vector to modify (passed by reference)
  final Vector2 velocity;
  
  /// Force applied when jumping (negative = upward)
  final double jumpForce;
  
  /// Cooldown duration between jumps (prevents spam)
  final double jumpCooldown;
  
  /// Pre-allocated jump vector (ZERO allocations per frame!)
  late final Vector2 _jumpVector;
  
  /// Current cooldown timer
  double _cooldownTimer = 0.0;
  
  JumpBehavior({
    required this.velocity,
    this.jumpForce = GameConfig.jumpVelocity,
    this.jumpCooldown = 0.1,
  }) {
    // Pre-calculate jump vector once (not per frame!)
    // Note: GameConfig.jumpVelocity is already negative
    _jumpVector = Vector2(0, jumpForce);
  }
  
  /// Whether the player can currently jump
  bool get canJump => _cooldownTimer <= 0;
  
  /// Perform a jump if cooldown allows
  void jump() {
    if (!canJump) return;
    
    // Apply jump force (upward)
    velocity.setFrom(_jumpVector);
    
    // Start cooldown
    _cooldownTimer = jumpCooldown;
  }
  
  @override
  void update(double dt) {
    // Update cooldown timer
    if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
    }
  }
}

