import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import '../flappy_game.dart';
import '../../core/debug_logger.dart';

/// Phase of the victory animation
enum VictoryPhase {
  /// Not active - waiting for victory trigger
  idle,
  
  /// Victory triggered - preparing to start animation
  triggered,
  
  /// Animation is in progress
  animating,
  
  /// Animation complete - ready for popup
  complete,
}

/// Controller for victory celebrations in story mode
/// 
/// Uses Turbo Exit animation for all levels:
/// - Jet gets shield (invulnerable) - uses existing neon shield effect
/// - Particle burst celebration
/// - Flies straight right off the screen with turbo speed
/// 
/// ✅ Flame best practice: Extends Component for game loop integration
/// ✅ Flutter best practice: Uses callbacks for UI notification
class VictoryController extends Component with HasGameReference<FlappyGame> {
  // Current state
  VictoryPhase _phase = VictoryPhase.idle;
  int _levelNumber = 0;
  
  // Animation timing
  double _animationTimer = 0;
  static const double _totalDuration = 2.0; // Turbo exit duration
  
  // Turbo animation state
  double? _turboStartY;
  
  // Callbacks for UI integration
  VoidCallback? onVictoryComplete;
  VoidCallback? onBannerShow;
  
  // Getters
  VictoryPhase get phase => _phase;
  bool get isActive => _phase != VictoryPhase.idle && _phase != VictoryPhase.complete;
  double get progress => _totalDuration > 0 ? (_animationTimer / _totalDuration).clamp(0.0, 1.0) : 0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    safePrint('🎉 VictoryController: Initialized (using procedural effects)');
  }
  
  /// Start victory sequence for the given level
  /// 
  /// [levelNumber] - The level that was completed
  /// 
  /// Returns false if victory is already in progress or complete
  bool startVictory(int levelNumber) {
    if (_phase != VictoryPhase.idle) {
      safePrint('🎉 VictoryController: Cannot start - already in phase $_phase');
      return false;
    }
    
    _levelNumber = levelNumber;
    _phase = VictoryPhase.triggered;
    _animationTimer = 0;
    _turboStartY = null;
    
    safePrint('🎉 VictoryController: Starting Turbo Exit for level $levelNumber');
    
    // Make jet invulnerable immediately (triggers existing neon shield effect)
    _makeJetInvulnerable();
    
    // Stop obstacle spawning
    _stopObstacleSpawning();
    
    // Start the turbo exit animation
    _startTurboExit();
    
    return true;
  }
  
  void _makeJetInvulnerable() {
    try {
      // This triggers the existing neon shield effect from JetPlayer
      game.jet.setInvulnerable(true);
      safePrint('🛡️ VictoryController: Jet is now invulnerable (shield active)');
    } catch (e) {
      safePrint('⚠️ VictoryController: Failed to make jet invulnerable: $e');
    }
  }
  
  void _stopObstacleSpawning() {
    try {
      safePrint('🛑 VictoryController: Obstacle spawning should be stopped');
    } catch (e) {
      safePrint('⚠️ VictoryController: Failed to stop obstacles: $e');
    }
  }
  
  void _startTurboExit() {
    _phase = VictoryPhase.animating;
    safePrint('🚀 VictoryController: Starting Turbo Exit animation');
    _triggerTurboEffect();
  }
  
  void _triggerTurboEffect() {
    try {
      // Play turbo/nitro sound
      game.audioManager.playAchievement();
      
      // Create particle burst for turbo activation
      game.celebrationSystem.createCelebrationBurst(
        game.jet.position,
        50, // Medium burst for turbo activation
      );
      
      safePrint('🔥 VictoryController: Turbo activated with particle burst!');
    } catch (e) {
      safePrint('⚠️ VictoryController: Turbo effect error: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_phase != VictoryPhase.animating) return;
    
    _animationTimer += dt;
    
    // Update turbo exit animation
    _updateTurboExit(dt);
    
    // Check if animation is complete
    if (_animationTimer >= _totalDuration) {
      _completeVictory();
    }
  }
  
  /// Update Turbo Exit animation
  /// Timeline:
  /// 0.0s: Shield activates (existing neon glow effect)
  /// 0.0s: Particle burst celebrates victory
  /// 0.1s-2.0s: Jet accelerates and flies right off screen
  /// 0.3s+: Continuous particle trail behind jet
  void _updateTurboExit(double dt) {
    final t = _animationTimer;
    
    // Phase 1: Turbo flight (continuous after 0.1s)
    if (t >= 0.1) {
      _updateJetTurboFlight(t);
    }
    
    // Phase 2: Notify UI at 0.5s (for any external banner/UI if needed)
    if (t >= 0.5 && t < 0.52) {
      onBannerShow?.call();
    }
    
    // Phase 3: Continuous turbo particle trail
    if (t >= 0.3 && (t * 10).floor() % 2 == 0) {
      _createTurboTrail();
    }
  }
  
  void _updateJetTurboFlight(double progress) {
    try {
      final jet = game.jet;
      final screenWidth = game.size.x;
      
      // Store the starting Y position on first frame
      _turboStartY ??= jet.position.y;
      
      // Calculate turbo speed - starts slow, then exponential acceleration
      // This creates a "whoosh" effect
      final normalizedProgress = (progress / _totalDuration).clamp(0.0, 1.0);
      final acceleration = _easeIn(normalizedProgress);
      
      // Move jet to the right with increasing speed
      // Start at 150 pixels/sec, end at 1000 pixels/sec for a dramatic exit
      final speed = 150 + (850 * acceleration);
      jet.position.x += speed * 0.016; // Assuming ~60fps
      
      // Keep jet flying LEVEL - counteract gravity completely
      // Lock the Y position to starting height with slight upward movement
      final targetY = _turboStartY! - (normalizedProgress * 30); // Slight rise during turbo
      jet.position.y = targetY;
      
      // Override velocity to prevent gravity from pulling jet down
      jet.velocity = Vector2.zero();
      
      // Keep jet level (no rotation/wobble during turbo)
      jet.angle = 0;
      
      // Log when jet exits screen
      if (jet.position.x > screenWidth + 100) {
        safePrint('🚀 VictoryController: Jet has exited screen!');
      }
    } catch (e) {
      safePrint('⚠️ VictoryController: Turbo flight error: $e');
    }
  }
  
  void _createTurboTrail() {
    try {
      final jet = game.jet;
      
      // Create small particle burst behind the jet for turbo trail
      game.celebrationSystem.createCelebrationBurst(
        Vector2(jet.position.x - 30, jet.position.y), // Behind the jet
        5, // Small burst for trail
      );
    } catch (e) {
      // Ignore trail errors - they're not critical
    }
  }
  
  void _completeVictory() {
    if (_phase == VictoryPhase.complete) return;
    
    _phase = VictoryPhase.complete;
    safePrint('🎉 VictoryController: Animation complete for level $_levelNumber');
    
    // Notify UI that victory animation is done
    onVictoryComplete?.call();
  }
  
  /// Reset controller for next level
  void reset() {
    _phase = VictoryPhase.idle;
    _animationTimer = 0;
    _levelNumber = 0;
    _turboStartY = null;
    
    safePrint('🔄 VictoryController: Reset');
  }
  
  /// Skip animation (for testing or impatient users)
  void skip() {
    if (_phase == VictoryPhase.animating) {
      _completeVictory();
    }
  }
  
  // Easing function for turbo acceleration
  double _easeIn(double t) => t * t; // Quadratic ease-in (accelerating)
}
