import 'dart:math' as math;
import 'package:flame/components.dart';
import '../components/jet_player.dart'; // Import existing JetDamageState

/// Manages damage visualization with flash effects
/// 
/// ✅ REFACTOR v1.7.0: Flame Component Behavior Pattern (2025)
/// 
/// Features:
/// - Damage state tracking (healthy/damaged/critical)
/// - Flash animation on damage
/// - Pending state during invulnerability
/// - Configurable flash duration
/// 
/// Usage:
/// ```dart
/// class PlayerComponent extends SpriteComponent {
///   late final DamageVisualizationBehavior damageVisual;
///   late final InvulnerabilityBehavior invulnerability;
///   
///   @override
///   Future<void> onLoad() async {
///     damageVisual = DamageVisualizationBehavior();
///     await add(damageVisual);
///   }
///   
///   void takeDamage(int livesRemaining) {
///     damageVisual.updateFromLives(livesRemaining);
///   }
///   
///   @override
///   void render(Canvas canvas) {
///     opacity = damageVisual.flashOpacity;
///     super.render(canvas);
///   }
/// }
/// ```
class DamageVisualizationBehavior extends Component {
  /// Duration of flash effect in seconds
  final double flashDuration;
  
  /// Current damage state
  JetDamageState _currentState = JetDamageState.healthy;
  
  /// Pending damage state (applied after invulnerability ends)
  JetDamageState? _pendingState;
  
  /// Whether currently flashing
  bool _isFlashing = false;
  
  /// Flash timer
  double _flashTimer = 0.0;
  
  /// Whether currently invulnerable
  bool _isInvulnerable = false;
  
  DamageVisualizationBehavior({
    this.flashDuration = 0.2, // 200ms flash
  });
  
  /// Current damage state
  JetDamageState get currentState => _currentState;
  
  /// Whether currently flashing
  bool get isFlashing => _isFlashing;
  
  /// Whether there's a pending state change
  bool get hasPendingState => _pendingState != null;
  
  /// Opacity for flash effect (1.0 = normal, fades during flash)
  double get flashOpacity {
    if (!_isFlashing) return 1.0;
    
    // Sine wave fade in/out
    final progress = _flashTimer / flashDuration;
    final opacity = math.sin(progress * math.pi); // 0 → 1 → 0
    return 0.3 + (opacity * 0.7); // Maps to [0.3, 1.0]
  }
  
  /// Set invulnerability state (affects when pending states apply)
  void setInvulnerable(bool value) {
    _isInvulnerable = value;
    
    // Apply pending state when invulnerability ends
    if (!value && _pendingState != null) {
      _currentState = _pendingState!;
      _pendingState = null;
      _triggerFlash();
    }
  }
  
  /// Update damage state based on lives remaining
  void updateFromLives(int livesCount) {
    final newState = _stateFromLives(livesCount);
    
    // Only react if state actually changes
    if (newState == _currentState && !_isInvulnerable) {
      return; // No change, no flash
    }
    
    if (_isInvulnerable) {
      // Store as pending state
      _pendingState = newState;
    } else {
      // Apply immediately
      _currentState = newState;
      _triggerFlash();
    }
  }
  
  /// Convert lives count to damage state
  JetDamageState _stateFromLives(int lives) {
    if (lives >= 3) return JetDamageState.healthy;
    if (lives == 2) return JetDamageState.damaged;
    return JetDamageState.critical;
  }
  
  /// Start flash animation
  void _triggerFlash() {
    _isFlashing = true;
    _flashTimer = 0.0;
  }
  
  @override
  void update(double dt) {
    if (!_isFlashing) return;
    
    _flashTimer += dt;
    
    // End flash after duration
    if (_flashTimer >= flashDuration) {
      _isFlashing = false;
      _flashTimer = 0.0;
    }
  }
}

