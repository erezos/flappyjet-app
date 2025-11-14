import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/debug_logger.dart';
import '../core/jet_skins.dart';

/// Flame-based FTUE tutorial game with real physics
/// 
/// Best practices implemented:
/// - Real game physics (gravity, tap-to-jump)
/// - Boundary collision detection
/// - Educational pause messages
/// - Proper lifecycle management
class FTUETutorialGame extends FlameGame with TapDetector {
  FTUETutorialGame({
    required this.onComplete,
  });

  /// Callback when tutorial is completed or skipped
  final Function({required bool completed, required int taps, required Duration duration}) onComplete;

  // Tutorial state
  late DateTime _startTime;
  bool _isCompleted = false;
  int _tapCount = 0;
  
  // Game state
  bool _isPaused = false;
  String? _pauseMessage;
  
  // Timers
  static const Duration _tutorialDuration = Duration(seconds: 20);
  static const Duration _skipRevealDelay = Duration(seconds: 5);
  
  // Components
  late PhysicsJetComponent _jetComponent;
  late SkipButtonOverlay _skipButtonOverlay;
  late ParallaxComponent _background;
  late TutorialLabelComponent _tutorialLabel;
  PauseMessageOverlay? _pauseMessageOverlay;
  late InitialTapMessageOverlay _initialTapMessage;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _startTime = DateTime.now();
    
    // Start paused with initial message
    _isPaused = true;

    // Load and add components
    await _loadComponents();

    // Show initial "Tap to Fly!" message
    _initialTapMessage = InitialTapMessageOverlay();
    _initialTapMessage.position = size / 2;
    await add(_initialTapMessage);

    // Schedule skip button reveal after 5 seconds
    Future.delayed(_skipRevealDelay, () {
      if (!_isCompleted && isMounted) {
        _skipButtonOverlay.reveal();
        safePrint('🎮 FTUE Tutorial: Skip button revealed');
      }
    });

    // Auto-complete after 20 seconds
    Future.delayed(_tutorialDuration, () {
      if (!_isCompleted && isMounted) {
        _handleCompletion(completed: true);
      }
    });

    safePrint('🎮 FTUE Tutorial: Flame game loaded');
  }

  Future<void> _loadComponents() async {
    // Load parallax background first
    await _loadBackground();
    
    // Always use the starter jet for FTUE
    final starterJet = JetSkinCatalog.starterJet;

    // Create physics jet component (centered, starts falling)
    _jetComponent = PhysicsJetComponent(
      assetPath: starterJet.assetPath,
      size: Vector2.all(100), // Made bigger for better visibility
      onBoundaryHit: _handleBoundaryCollision,
    );
    _jetComponent.position = Vector2(size.x / 2, size.y / 2);
    _jetComponent.anchor = Anchor.center;
    await add(_jetComponent);

    // Create "Tutorial" label (top-left, subtle)
    _tutorialLabel = TutorialLabelComponent();
    _tutorialLabel.position = Vector2(16, 40);
    await add(_tutorialLabel);

    // Create skip button (top-right, hidden initially)
    _skipButtonOverlay = SkipButtonOverlay(
      onSkip: () => _handleCompletion(completed: false),
    );
    _skipButtonOverlay.position = Vector2(size.x - 140, 30);
    await add(_skipButtonOverlay);
  }

  /// Load scrolling parallax background
  Future<void> _loadBackground() async {
    try {
      const backgroundAsset = 'backgrounds/phase1_dawn_complete.png';
      
      _background = await loadParallaxComponent(
        [ParallaxImageData(backgroundAsset)],
        baseVelocity: Vector2(60, 0), // Slow scroll
        repeat: ImageRepeat.repeatX,
        priority: -100,
      );
      
      await add(_background);
      safePrint('🎮 FTUE Background: Loaded $backgroundAsset');
    } catch (e) {
      safePrint('🎮 FTUE Background: Failed to load - $e');
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (_isCompleted) return;
    
    // If paused with initial message, start the game
    if (_isPaused && _initialTapMessage.parent != null) {
      _initialTapMessage.removeFromParent();
      _resumeGame();
      // First jump to start the game
      _jetComponent.jump();
      _tapCount++;
      HapticFeedback.lightImpact();
      safePrint('🎮 FTUE Tutorial: First tap - game started');
      return;
    }
    
    // If paused (hit boundary), unpause on tap
    if (_isPaused) {
      _resumeGame();
      // If hit ground, jump to continue
      if (_jetComponent.position.y >= _jetComponent.bottomBoundary) {
        _jetComponent.jump();
        _tapCount++;
        HapticFeedback.lightImpact();
        safePrint('🎮 FTUE Tutorial: Tap $_tapCount (resumed from ground)');
      } else {
        // Hit ceiling, just resume (jet will fall naturally)
        safePrint('🎮 FTUE Tutorial: Resumed from ceiling');
      }
      return;
    }
    
    // Normal gameplay tap
    _tapCount++;
    _jetComponent.jump();
    HapticFeedback.lightImpact();
    safePrint('🎮 FTUE Tutorial: Tap $_tapCount');
  }

  void _handleBoundaryCollision(BoundaryType type) {
    if (_isPaused) return; // Already paused
    
    _pauseGame(type);
  }

  void _pauseGame(BoundaryType boundaryType) {
    _isPaused = true;
    _jetComponent.pause();
    
    // Set message based on boundary
    switch (boundaryType) {
      case BoundaryType.ground:
        _pauseMessage = 'Tap to keep flying! 🚀';
        break;
      case BoundaryType.ceiling:
        _pauseMessage = 'Easy there! Stay in bounds! ⬇️';
        break;
    }
    
    // Show pause message overlay
    if (_pauseMessageOverlay != null) {
      _pauseMessageOverlay!.removeFromParent();
    }
    
    _pauseMessageOverlay = PauseMessageOverlay(message: _pauseMessage!);
    _pauseMessageOverlay!.position = size / 2;
    add(_pauseMessageOverlay!);
    
    safePrint('🎮 FTUE Tutorial: Paused (${boundaryType.name})');
  }

  void _resumeGame() {
    _isPaused = false;
    _jetComponent.resume();
    
    // Remove pause message
    if (_pauseMessageOverlay != null) {
      _pauseMessageOverlay!.removeFromParent();
      _pauseMessageOverlay = null;
    }
    
    safePrint('🎮 FTUE Tutorial: Resumed');
  }

  void _handleCompletion({required bool completed}) {
    if (_isCompleted) return;
    
    _isCompleted = true;
    final duration = DateTime.now().difference(_startTime);

    safePrint('🎮 FTUE Tutorial: ${completed ? "Completed" : "Skipped"} ($_tapCount taps, ${duration.inSeconds}s)');

    // Call completion callback
    onComplete(
      completed: completed,
      taps: _tapCount,
      duration: duration,
    );
  }
}

/// Physics-based jet component with gravity and jump
class PhysicsJetComponent extends SpriteComponent with HasGameRef<FTUETutorialGame> {
  PhysicsJetComponent({
    required this.assetPath,
    required Vector2 size,
    required this.onBoundaryHit,
  }) : super(size: size);

  final String assetPath;
  final Function(BoundaryType) onBoundaryHit;
  
  // Physics properties
  Vector2 velocity = Vector2.zero();
  static const double gravity = 800.0; // pixels/second²
  static const double jumpVelocity = -350.0; // pixels/second (negative = up)
  static const double maxFallSpeed = 600.0; // terminal velocity
  
  bool _isPaused = false;
  
  // Boundaries (with padding)
  static const double topBoundary = 80.0;
  late double bottomBoundary;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    anchor = Anchor.center;
    bottomBoundary = gameRef.size.y - 80.0;
    
    try {
      sprite = await gameRef.loadSprite(assetPath);
      safePrint('🎮 FTUE Jet: Loaded sprite from $assetPath');
    } catch (e) {
      safePrint('🎮 FTUE Jet: Failed to load sprite - $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isPaused) return;
    
    // Apply gravity
    velocity.y += gravity * dt;
    
    // Clamp fall speed
    if (velocity.y > maxFallSpeed) {
      velocity.y = maxFallSpeed;
    }
    
    // Update position
    position += velocity * dt;
    
    // Check boundaries
    if (position.y <= topBoundary) {
      position.y = topBoundary;
      velocity.y = 0;
      onBoundaryHit(BoundaryType.ceiling);
    } else if (position.y >= bottomBoundary) {
      position.y = bottomBoundary;
      velocity.y = 0;
      onBoundaryHit(BoundaryType.ground);
    }
    
    // Rotate based on velocity (tilt up when rising, down when falling)
    angle = (velocity.y / 500.0).clamp(-0.3, 0.3);
  }

  void jump() {
    if (_isPaused) return;
    velocity.y = jumpVelocity;
  }

  void pause() {
    _isPaused = true;
    velocity = Vector2.zero();
  }

  void resume() {
    _isPaused = false;
  }
}

enum BoundaryType {
  ground,
  ceiling,
}

/// Small "Tutorial" label in top-left corner
class TutorialLabelComponent extends TextComponent {
  TutorialLabelComponent()
      : super(
          text: 'Tutorial',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 32, // Made bigger for better visibility
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        );
}

/// Initial "Tap to Fly!" message (large, centered)
class InitialTapMessageOverlay extends PositionComponent with HasGameRef {
  InitialTapMessageOverlay() : super(anchor: Anchor.center);

  late TextComponent _textComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _textComponent = TextComponent(
      text: 'Tap to Fly!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black87,
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
    );
    await add(_textComponent);
  }
}

/// Pause message overlay (centered, large text)
class PauseMessageOverlay extends PositionComponent with HasGameRef {
  PauseMessageOverlay({required this.message}) : super(anchor: Anchor.center);

  final String message;
  late TextComponent _textComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _textComponent = TextComponent(
      text: message,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black87,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
    );
    await add(_textComponent);
  }
}

/// Skip button overlay
class SkipButtonOverlay extends PositionComponent with HasGameRef<FTUETutorialGame>, TapCallbacks, HasPaint {
  SkipButtonOverlay({
    required this.onSkip,
  }) : super(size: Vector2(120, 50));

  final VoidCallback onSkip;
  bool isVisible = false;
  late TextComponent _textComponent;
  
  double _fadeProgress = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _textComponent = TextComponent(
      text: 'Skip',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    await add(_textComponent);
  }

  void reveal() {
    isVisible = true;
    _fadeProgress = 0.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Manual fade-in animation
    if (isVisible && _fadeProgress < 1.0) {
      _fadeProgress += dt * 2.0; // 0.5 second duration
      if (_fadeProgress > 1.0) _fadeProgress = 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw background
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(25));
    
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.black.withOpacity(0.6 * _fadeProgress),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(0.3 * _fadeProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isVisible) {
      onSkip();
    }
  }
}
