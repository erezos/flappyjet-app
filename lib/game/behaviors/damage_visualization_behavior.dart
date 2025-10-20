import 'package:flame/components.dart';
import '../components/jet_player.dart'; // Import existing JetDamageState

/// ✅ SIMPLIFIED: Manages only invulnerability visual state
/// 
/// ✅ REFACTOR v1.7.0: Flame Component Behavior Pattern (2025)
/// 
/// Features:
/// - Tracks invulnerability state (healthy vs. invulnerable)
/// - No damage states (damaged/critical removed)
/// - Health is tracked by GameStateManager.lives and displayed in HUD
/// - Jet appearance is ALWAYS normal (no visual damage effects)
/// 
/// Usage:
/// ```dart
/// class PlayerComponent extends SpriteComponent {
///   late final DamageVisualizationBehavior damageVisual;
///   
///   @override
///   Future<void> onLoad() async {
///     damageVisual = DamageVisualizationBehavior();
///     await add(damageVisual);
///   }
///   
///   void setInvulnerable(bool value) {
///     damageVisual.setInvulnerable(value);
///   }
/// }
/// ```
class DamageVisualizationBehavior extends Component {
  /// Current visual state (healthy or invulnerable)
  JetDamageState _currentState = JetDamageState.healthy;
  
  /// Whether currently invulnerable
  bool _isInvulnerable = false;
  
  DamageVisualizationBehavior();
  
  /// Current visual state
  JetDamageState get currentState => _currentState;
  
  /// Whether currently invulnerable
  bool get isInvulnerable => _isInvulnerable;
  
  /// ✅ SIMPLIFIED: Set invulnerability state (only state we track now)
  void setInvulnerable(bool value) {
    // Early return if no state change
    if (_isInvulnerable == value) return;

    _isInvulnerable = value;

    if (value) {
      // Entering invulnerability
      _currentState = JetDamageState.invulnerable;
    } else {
      // Exiting invulnerability
      _currentState = JetDamageState.healthy;
    }
  }
  
  /// ✅ SIMPLIFIED: Reset to healthy state
  void reset() {
    _currentState = JetDamageState.healthy;
    _isInvulnerable = false;
  }
}
