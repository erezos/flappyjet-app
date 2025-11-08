/// 🤖 BOT JET PLAYER
/// 
/// A simplified AI-controlled jet that flies alongside the player in bot battle levels.
/// The bot follows a predetermined flight pattern and scores points automatically.
library;

import 'dart:math';
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../core/game_config.dart';
import '../behaviors/gravity_behavior.dart';
import '../behaviors/jump_behavior.dart';
import '../flappy_game.dart'; // For FlappyGame type cast

/// Map bot theme names to actual jet sprite files
String _getBotJetSpriteFileName(String botJetSkin) {
  // Direct mapping - bot skin IDs to actual asset file names
  const botToSpriteMap = {
    'police_patrol': 'police',
    'green_lightning': 'green_lightning',
    'desert_storm': 'desert_storm',
    'sky_prince': 'sky_prince',
    'stealth_fire': 'stealth_fire',
    'molten_devastator': 'magma_fracture',
    'storm_chaser': 'storm',
    'diamond_storm': 'diamond_jet',
    'stealth_dragon': 'stealth_dragon',
    'lord_of_war': 'lord_of_war',
    'blaze': 'blaze',
    'storm': 'storm',
    'stealth_bomber': 'stealth_bomber',
  };
  
  return botToSpriteMap[botJetSkin] ?? botJetSkin;  // Use skin name directly if not in map
}

/// ✅ REFACTOR v1.7.0: Using HasGameReference instead of deprecated HasGameRef
/// ✅ REFACTOR v2.0.0 Phase 2: Using Behavior Pattern (GravityBehavior, JumpBehavior)
/// Note: Property name changed from `gameRef` to `game`
class BotJetPlayer extends SpriteComponent with HasGameReference {
  final String skinId;
  final double skillLevel;      // 0.6-1.5 (actual skill level, not normalized 0-1)
  final double reactionTime;    // in seconds
  final double mistakeRate;     // 0.02-0.20
  
  // ✅ REFACTOR v2.0.0 Phase 2: Use velocity Vector2 for behaviors
  final Vector2 velocity = Vector2.zero();
  
  // ✅ REFACTOR v2.0.0 Phase 2: Behavior Components
  late final GravityBehavior _gravityBehavior;
  late final JumpBehavior _jumpBehavior;
  
  // Bot state
  double _targetY = 0;
  int _score = 0;
  bool _isActive = true;
  bool _hasHitGround = false; // Track if bot already hit ground (for explosion)
  
  // Bot obstacle navigation
  double? _nextObstacleGapY; // Target Y position of the next obstacle's gap center
  double? _nextObstacleX; // X position of the next obstacle
  
  // Bot AI parameters - with human-like randomization
  double _timeSinceLastJump = 0;
  final Random _random = Random();
  
  // Visual parameters (slightly larger than player jet for better visibility)
  static const double botSize = 75.0; // Bigger than player jet (60)
  static const double botXPosition = 50.0; // Flies on the left side
  
  BotJetPlayer({
    required this.skinId,
    required this.skillLevel,
    required this.reactionTime,
    required this.mistakeRate,
  });
  
  @override
  Future<void> onLoad() async {
    // Load bot jet skin with proper mapping
    final actualSkinName = _getBotJetSpriteFileName(skinId);
    final skinPath = 'jets/$actualSkinName.png';
    
    safePrint('🤖 Loading bot jet skin: $skinId -> $skinPath');
    
    try {
      sprite = await game.loadSprite(skinPath);
      safePrint('🤖 ✅ Bot jet skin loaded successfully: $actualSkinName');
    } catch (e) {
      safePrint('🤖 ❌ Failed to load bot skin: $e, using fallback');
      // Use sky_jet as final fallback
      sprite = await game.loadSprite('jets/sky_jet.png');
    }
    
    // Set size and initial position
    size = Vector2(botSize, botSize);
    position = Vector2(botXPosition, game.size.y / 2);
    anchor = Anchor.center;
    
    // ✅ REFACTOR v2.0.0 Phase 2: Initialize Behavior Components
    _gravityBehavior = GravityBehavior(
      velocity: velocity,
      maxFallSpeed: GameConfig.maxFallSpeed,
    );
    _jumpBehavior = JumpBehavior(
      velocity: velocity,
      jumpForce: GameConfig.jumpVelocity,
    );
    
    // Add behaviors to component tree
    await addAll([
      _gravityBehavior,
      _jumpBehavior,
    ]);
    
    safePrint('🤖 Bot jet loaded at position: $position');
    safePrint('🤖 Bot parameters: skill=$skillLevel, reaction=${reactionTime}s, mistakes=$mistakeRate');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // If bot is not active (crashed), make it sink to bottom dramatically
    if (!_isActive) {
      // Apply increasing gravity for dramatic sinking effect
      velocity.y += GameConfig.gravity * dt * 1.5; // 1.5x gravity for faster sink
      position.y += velocity.y * dt;
      
      // Add slight rotation for more dramatic crash effect (tumbling)
      angle += dt * 0.5; // Slow rotation as it sinks
      
      // 💥 GROUND IMPACT EXPLOSION - Check if bot hits the ground
      final groundY = game.size.y - 50; // 50 = ground height
      if (!_hasHitGround && position.y >= groundY) {
        _hasHitGround = true; // Only trigger explosion once
        
        // Create massive ground impact explosion at ground level
        if (game is FlappyGame) {
          final groundPosition = Vector2(position.x, groundY);
          (game as FlappyGame).createBotGroundExplosion(groundPosition);
        }
        
        safePrint('💥 Bot hit the ground! Creating explosion at ground level');
      }
      
      // Stop sinking when off-screen (performance optimization)
      if (position.y > game.size.y + 100) {
        velocity.y = 0; // Stop falling when far off screen
      }
      return; // Don't run AI when crashed
    }
    
    // Update bot AI
    _updateBotAI(dt);
    
    // ✅ REFACTOR v2.0.0 Phase 2: Gravity applied by GravityBehavior automatically
    // Just apply velocity to position
    position.y += velocity.y * dt;
    
    // Keep bot within bounds
    final minY = botSize / 2;
    final maxY = game.size.y - 50 - (botSize / 2); // 50 = ground height
    
    if (position.y < minY) {
      position.y = minY;
      velocity.y = 0;
    } else if (position.y > maxY) {
      position.y = maxY;
      velocity.y = 0;
      // Bot crashed into ground - deactivate and start sinking
      if (_isActive) {
        crash(); // Call crash to trigger smoke and sinking
      }
    }
  }
  
  /// Bot AI logic - THRESHOLD-BASED APPROACH (proven by ML research)
  /// Key insight: Flappy Bird is about simple threshold reactions, not complex prediction
  void _updateBotAI(double dt) {
    _timeSinceLastJump += dt;
    
    // Find the next obstacle to target
    _findNextObstacle();
    
    // Calculate target Y position based on next obstacle or default to center
    if (_nextObstacleGapY != null && _nextObstacleX != null) {
      // We have an obstacle to navigate!
      
      // Skill-based accuracy: how close to gap center the bot aims
      // High skill = aims closer to center, low skill = more variation
      final aimVariation = 30 * (1.0 - skillLevel); // 0.98 skill = ±0.6px, 0.6 skill = ±12px
      final aimOffset = (_random.nextDouble() * aimVariation * 2) - aimVariation;
      _targetY = _nextObstacleGapY! + aimOffset;
      
      final currentY = position.y;
      
      // 🎯 THRESHOLD-BASED DECISION (like successful ML models)
      // Define a threshold based on skill level - higher skill = tighter control
      final threshold = 15 + ((1.0 - skillLevel) * 25); // 0.98 skill = 15.5px, 0.6 skill = 25px
      
      // SIMPLE RULE: If we're BELOW target by more than threshold → JUMP
      // This is exactly how successful Flappy Bird AIs work!
      if (currentY > _targetY + threshold) {
        // We're too low - need to jump!
        if (_timeSinceLastJump >= reactionTime) {
          // Apply mistake rate: sometimes the bot fails to jump
          final jumpSuccess = _random.nextDouble() > mistakeRate;
          if (jumpSuccess) {
            safePrint('🤖 JUMP: Y=${currentY.toStringAsFixed(0)} → Target=${_targetY.toStringAsFixed(0)} (below by ${(currentY - _targetY).toStringAsFixed(0)}px)');
            _jump();
            return;
          } else {
            safePrint('🤖 MISTAKE: Missed jump (${(mistakeRate * 100).toStringAsFixed(0)}% rate)');
          }
        }
      }
      // Removed spammy "coast down" and "in target zone" logs
      
    } else {
      // No obstacle found, maintain center height
      final centerY = game.size.y / 2;
      if (position.y > centerY + 50 && _timeSinceLastJump >= reactionTime) {
        _jump();
      }
    }
    
    // Emergency: prevent hitting ground
    if (position.y > game.size.y - 100 && velocity.y > 0) {
      safePrint('🤖 EMERGENCY: Near ground at Y=${position.y.toStringAsFixed(0)} - JUMP!');
      _jump();
    }
  }
  
  /// Find the next obstacle ahead of the bot and set target
  void _findNextObstacle() {
    if (game is! FlappyGame) return;
    
    final flappyGame = game as FlappyGame;
    final obstacles = flappyGame.getObstacles();
    
    // Store previous state to detect changes
    final hadObstacle = _nextObstacleGapY != null;
    
    // Find the closest obstacle ahead of us
    double? closestX;
    double? closestGapY;
    
    for (final obstacle in obstacles) {
      final obstacleX = obstacle.position.x;
      
      // Only consider obstacles ahead of us (with some margin)
      if (obstacleX > position.x - 50) {
        if (closestX == null || obstacleX < closestX) {
          closestX = obstacleX;
          // Calculate gap center Y
          // obstacle.position.y is the TOP of the gap (Anchor.topLeft)
          closestGapY = obstacle.position.y + (obstacle.gapSize / 2);
        }
      }
    }
    
    _nextObstacleX = closestX;
    _nextObstacleGapY = closestGapY;
    
    // Only log when obstacle state changes (found new one or lost current one)
    if (_nextObstacleGapY != null && !hadObstacle) {
      safePrint('🤖 NEW TARGET: Gap at Y=${_nextObstacleGapY!.toStringAsFixed(0)}, dist=${(closestX! - position.x).toStringAsFixed(0)}px ahead');
    } else if (_nextObstacleGapY == null && hadObstacle) {
      safePrint('🤖 LOST TARGET: No obstacles ahead');
    }
  }
  
  /// Make the bot jump
  /// NOW USES SKILL LEVEL for jump accuracy!
  void _jump() {
    // ✅ REFACTOR v2.0.0 Phase 2: Use JumpBehavior
    _jumpBehavior.jump();
    _timeSinceLastJump = 0;
    
    // Add velocity randomness based on mistakeRate AND skill level
    // Higher skill = less random jumps, even with same mistakeRate
    final skillFactor = 1.0 - (skillLevel * 0.4); // 0.98 skill = 0.608x, 0.6 skill = 0.76x
    final randomness = mistakeRate * 150 * skillFactor; // High skill reduces randomness further
    velocity.y += (_random.nextDouble() * randomness) - (randomness / 2);
  }
  
  /// Increment bot score when it passes an obstacle
  void incrementScore() {
    if (!_isActive) return;
    _score++;
    // Only log milestone scores to reduce spam
    if (_score % 5 == 0 || _score <= 3) {
      safePrint('🤖 SCORE: $_score');
    }
  }
  
  /// Get current bot score
  int get score => _score;
  
  /// Check if bot is still active
  bool get isActive => _isActive;
  
  /// Crash the bot (called when it hits an obstacle or ground)
  void crash() {
    if (!_isActive) return;
    _isActive = false;
    
    // 💥 Create bot crash smoke effect (4x longer, more fire, less smoke than player)
    if (game is FlappyGame) {
      (game as FlappyGame).createBotCrashSmoke(position);
    }
    
    // 🌊 Start sinking animation - bot falls to bottom of screen dramatically
    velocity.y = 50.0; // Initial downward velocity (gentle start)
    
    safePrint('🤖 💥 CRASHED at Y=${position.y.toStringAsFixed(0)}, Final Score: $_score');
  }
  
  /// Reset bot for new level
  void reset() {
    _score = 0;
    _isActive = true;
    velocity.setZero(); // ✅ REFACTOR v2.0.0 Phase 2: Reset velocity Vector2
    _timeSinceLastJump = 0;
    position.y = game.size.y / 2;
  }
}

