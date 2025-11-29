import 'dart:math';
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
/// - Jet gets shield (invulnerable) IMMEDIATELY - prevents any crash during transition
/// - Smooth transition phase (0.4s) - natural momentum decay, no "stuck" feeling
/// - Turbo exit phase - flies off screen with increasing speed
/// 
/// ✅ Flame best practice: Extends Component for game loop integration
/// ✅ Flutter best practice: Uses callbacks for UI notification
/// ✅ UX best practice: Smooth transition prevents abrupt physics changes
class VictoryController extends Component with HasGameReference<FlappyGame> {
  // Current state
  VictoryPhase _phase = VictoryPhase.idle;
  int _levelNumber = 0;
  
  // Animation timing
  double _animationTimer = 0;
  static const double _totalDuration = 2.0; // Total animation duration
  static const double _transitionDuration = 0.4; // Smooth transition phase
  
  // Turbo animation state
  double? _turboStartY;
  
  // ✅ NEW: Initial jet state for smooth transition
  double? _initialJetY;
  double? _initialJetVelocityY;
  
  // Callbacks for UI integration
  VoidCallback? onVictoryComplete;
  VoidCallback? onBannerShow;
  
  // Getters
  VictoryPhase get phase => _phase;
  bool get isActive => _phase != VictoryPhase.idle && _phase != VictoryPhase.complete;
  double get progress => _totalDuration > 0 ? (_animationTimer / _totalDuration).clamp(0.0, 1.0) : 0;
  
  // ✅ NEW: Expose transition duration for testing
  static double get transitionDurationSeconds => _transitionDuration;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    safePrint('🎉 VictoryController: Initialized (with smooth transition)');
  }
  
  /// Start victory sequence for the given level
  /// 
  /// [levelNumber] - The level that was completed
  /// 
  /// Returns false if victory is already in progress or complete
  /// 
  /// ✅ CRITICAL: Shield activates IMMEDIATELY to prevent any crash
  /// during the smooth transition phase
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
    
    // 🛡️ FIRST: Make jet invulnerable IMMEDIATELY (triggers existing neon shield effect)
    // This MUST happen before anything else to prevent crash during transition
    _makeJetInvulnerable();
    
    // 📸 SECOND: Capture initial jet state for smooth transition
    _captureInitialJetState();
    
    // Stop obstacle spawning
    _stopObstacleSpawning();
    
    // Start the turbo exit animation
    _startTurboExit();
    
    return true;
  }
  
  /// 📸 Capture the jet's current state for smooth transition blending
  void _captureInitialJetState() {
    try {
      final jet = game.jet;
      _initialJetY = jet.position.y;
      _initialJetVelocityY = jet.velocity.y;
      safePrint('📸 VictoryController: Captured initial state - Y: $_initialJetY, velocityY: $_initialJetVelocityY');
    } catch (e) {
      safePrint('⚠️ VictoryController: Failed to capture initial state: $e');
      _initialJetY = null;
      _initialJetVelocityY = 0;
    }
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
    safePrint('🚀 VictoryController: Starting Turbo Exit animation (with ${_transitionDuration}s smooth transition)');
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
    
    // Update turbo exit animation with smooth transition
    _updateTurboExit(dt);
    
    // Check if animation is complete
    if (_animationTimer >= _totalDuration) {
      _completeVictory();
    }
  }
  
  /// Update Turbo Exit animation with SMOOTH TRANSITION
  /// 
  /// Timeline:
  /// 0.0s: Shield activates (existing neon glow effect)
  /// 0.0s: Particle burst celebrates victory
  /// 0.0s-0.4s: TRANSITION PHASE - smooth blend from current momentum
  /// 0.4s-2.0s: FULL TURBO PHASE - locked level flight, accelerating exit
  /// 0.3s+: Continuous particle trail behind jet
  void _updateTurboExit(double dt) {
    final t = _animationTimer;
    
    // Update jet flight with smooth transition
    _updateJetTurboFlight(dt);
    
    // Notify UI at 0.5s (for any external banner/UI if needed)
    if (t >= 0.5 && t < 0.52) {
      onBannerShow?.call();
    }
    
    // Continuous turbo particle trail (after transition phase)
    if (t >= 0.3 && (t * 10).floor() % 2 == 0) {
      _createTurboTrail();
    }
  }
  
  /// ✅ NEW: Smooth jet flight with transition phase
  /// 
  /// Phase 1 (0-0.4s): TRANSITION
  /// - Jet's current momentum naturally decays (no abrupt stop)
  /// - Gradually blend Y position towards level flight
  /// - Slowly start horizontal movement
  /// 
  /// Phase 2 (0.4s-2.0s): FULL TURBO
  /// - Lock Y position to level flight
  /// - Full turbo acceleration to exit screen
  void _updateJetTurboFlight(double dt) {
    try {
      final jet = game.jet;
      final t = _animationTimer;
      
      // Calculate target Y (slightly above center for a nice flight path)
      final screenCenterY = game.size.y * 0.4;
      
      if (t < _transitionDuration) {
        // === TRANSITION PHASE ===
        // Smoothly blend from current momentum to level flight
        _updateTransitionPhase(jet, dt, t, screenCenterY);
      } else {
        // === FULL TURBO PHASE ===
        // Lock to level flight, full speed ahead
        _updateTurboPhase(jet, dt, t);
      }
      
      // Log when jet exits screen
      if (jet.position.x > game.size.x + 100) {
        safePrint('🚀 VictoryController: Jet has exited screen!');
      }
    } catch (e) {
      safePrint('⚠️ VictoryController: Turbo flight error: $e');
    }
  }
  
  /// ✅ NEW: Smooth transition phase - natural momentum decay
  void _updateTransitionPhase(dynamic jet, double dt, double t, double screenCenterY) {
    final transitionProgress = t / _transitionDuration;
    final easeProgress = _easeOutCubic(transitionProgress);
    
    // === VERTICAL MOVEMENT ===
    // Gradually reduce vertical velocity (natural momentum decay)
    final initialVelocityY = _initialJetVelocityY ?? 0;
    final velocityDecay = 1.0 - easeProgress;
    final currentVelocityY = initialVelocityY * velocityDecay;
    
    // Apply decaying velocity to Y position (feels natural)
    jet.position.y += currentVelocityY * dt;
    
    // Gently blend Y position towards target (not instant snap)
    // Use a soft lerp factor that increases over time
    final lerpFactor = easeProgress * 0.15; // Max 15% per frame at end of transition
    final targetY = screenCenterY;
    jet.position.y = _lerp(jet.position.y, targetY, lerpFactor);
    
    // === HORIZONTAL MOVEMENT ===
    // Start horizontal movement slowly, accelerating through transition
    final horizontalSpeed = 50 + (150 * easeProgress); // 50 -> 200 pixels/sec
    jet.position.x += horizontalSpeed * dt;
    
    // === ROTATION ===
    // Gradually level out any rotation
    jet.angle = (jet.angle as double) * (1 - easeProgress);
    
    // === VELOCITY ===
    // Gradually reduce velocity vector (let behaviors know we're taking over)
    jet.velocity.y = currentVelocityY;
    jet.velocity.x = 0; // We control horizontal movement directly
    
    // Debug log for transition progress
    if ((t * 10).floor() % 4 == 0) {
      safePrint('🔄 Transition: ${(transitionProgress * 100).toInt()}% - Y: ${jet.position.y.toStringAsFixed(1)}, velY: ${currentVelocityY.toStringAsFixed(1)}');
    }
  }
  
  /// ✅ Existing: Full turbo phase - locked level flight
  void _updateTurboPhase(dynamic jet, double dt, double t) {
    // Lock the Y position at start of turbo phase
    _turboStartY ??= jet.position.y;
    
    // Calculate turbo progress within turbo phase
    final turboProgress = (t - _transitionDuration) / (_totalDuration - _transitionDuration);
    final acceleration = _easeIn(turboProgress.clamp(0.0, 1.0));
    
    // === HORIZONTAL MOVEMENT ===
    // Full turbo speed - start at 200, end at 1000 pixels/sec
    final speed = 200 + (800 * acceleration);
    jet.position.x += speed * dt;
    
    // === VERTICAL MOVEMENT ===
    // Keep Y locked with slight upward drift for dramatic effect
    final targetY = _turboStartY! - (turboProgress * 30);
    jet.position.y = targetY;
    
    // === PHYSICS OVERRIDE ===
    // Full control - zero out velocity to prevent gravity
    jet.velocity = Vector2.zero();
    
    // === ROTATION ===
    // Keep jet perfectly level
    jet.angle = 0;
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
    _initialJetY = null;
    _initialJetVelocityY = null;
    
    safePrint('🔄 VictoryController: Reset');
  }
  
  /// Skip animation (for testing or impatient users)
  void skip() {
    if (_phase == VictoryPhase.animating) {
      _completeVictory();
    }
  }
  
  // === EASING FUNCTIONS ===
  
  /// Quadratic ease-in (accelerating) - for turbo speed
  double _easeIn(double t) => t * t;
  
  /// Cubic ease-out (decelerating) - for smooth transition
  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  
  /// Linear interpolation
  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
