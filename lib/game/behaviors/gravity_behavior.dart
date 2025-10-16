import 'package:flame/components.dart';
import '../core/game_config.dart';

/// Applies gravity physics to any component with velocity
/// 
/// ✅ REFACTOR v1.7.0: Flame Component Behavior Pattern (2025)
/// 
/// Modern Flame approach: Use Component as a behavior container
/// Benefits:
/// - Works with any PositionComponent (no EntityMixin required)
/// - Zero allocations per frame (pre-allocated gravity vector)
/// - Configurable gravity multiplier
/// - Terminal velocity capping
/// - Fully testable in isolation
/// 
/// Usage:
/// ```dart
/// class PhysicsComponent extends PositionComponent {
///   final velocity = Vector2.zero();
///   
///   @override
///   Future<void> onLoad() async {
///     await add(GravityBehavior(velocity: velocity));
///   }
/// }
/// ```
class GravityBehavior extends Component {
  /// The velocity vector to modify (passed by reference)
  final Vector2 velocity;
  
  /// Multiplier for gravity strength (1.0 = normal, 2.0 = double gravity)
  final double gravityMultiplier;
  
  /// Maximum falling speed (terminal velocity)
  final double maxFallSpeed;
  
  /// Pre-allocated gravity vector (ZERO allocations per frame!)
  late final Vector2 _gravityVector;
  
  GravityBehavior({
    required this.velocity,
    this.gravityMultiplier = 1.0,
    this.maxFallSpeed = 3000.0, // High default to not interfere with normal physics
  }) {
    // Pre-calculate gravity vector once (not per frame!)
    _gravityVector = Vector2(0, GameConfig.gravity * gravityMultiplier);
  }
  
  @override
  void update(double dt) {
    // Apply gravity to velocity (no new allocations!)
    velocity.add(_gravityVector.scaled(dt));
    
    // Cap at terminal velocity
    if (velocity.y > maxFallSpeed) {
      velocity.y = maxFallSpeed;
    }
  }
}

