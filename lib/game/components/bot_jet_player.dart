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
  
  // Bot AI parameters - with human-like randomization
  double _timeSinceLastJump = 0;
  final Random _random = Random();
  
  // Human-like behavior parameters
  double _nextJumpTime = 0; // When bot will jump next (with randomization)
  bool _isHesitating = false; // Sometimes bot "hesitates" like a human
  double _hesitationTimer = 0;
  
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
    
    // Initialize human-like behavior - randomize first jump time
    _calculateNextJumpTime();
    
    safePrint('🤖 Bot jet loaded at position: $position');
    safePrint('🤖 Bot parameters: skill=$skillLevel, reaction=${reactionTime}s, mistakes=$mistakeRate');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isActive) return;
    
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
      // Bot crashed into ground - deactivate
      _isActive = false;
      safePrint('🤖 Bot crashed! Final score: $_score');
    }
  }
  
  /// Bot AI logic - makes the bot jump in a more human-like way
  void _updateBotAI(double dt) {
    _timeSinceLastJump += dt;
    
    // Handle hesitation (sometimes humans pause before jumping)
    if (_isHesitating) {
      _hesitationTimer -= dt;
      if (_hesitationTimer <= 0) {
        _isHesitating = false;
      }
      return; // Don't jump while hesitating
    }
    
    // Calculate target Y position with some variation
    // Human players don't fly perfectly in the center
    final centerY = game.size.y / 2;
    final variation = _random.nextDouble() * 60 - 30; // ±30 pixels from center
    _targetY = centerY + variation;
    
    // Check if it's time to jump based on randomized timing
    if (_timeSinceLastJump >= _nextJumpTime) {
      // Sometimes humans react a bit late (20% chance)
      if (_random.nextDouble() < 0.2) {
        _isHesitating = true;
        _hesitationTimer = 0.1 + _random.nextDouble() * 0.15; // 100-250ms delay
        return;
      }
      
      _jump();
      return;
    }
    
    // Emergency jump if falling too low (human panic reaction)
    final dangerZone = game.size.y - 150; // Close to ground
    if (position.y > dangerZone && velocity.y > 0) {
      // Quick reaction with slight randomness
      if (_random.nextDouble() < 0.9) { // 90% chance to react
        _jump();
      }
    }
    
    // Also jump if too high and still going up (human correction)
    final tooHigh = 100.0;
    if (position.y < tooHigh && velocity.y < -100) {
      // Let it fall naturally (humans stop jumping when too high)
      return;
    }
    
    // Smart jump based on current velocity and position (human prediction)
    // If falling and below target, jump with some randomness
    if (position.y > _targetY + 40 && velocity.y > 50) {
      // Not always perfect timing (80% accuracy)
      if (_random.nextDouble() < 0.8) {
        _jump();
      }
    }
  }
  
  /// Calculate next jump time with human-like variation
  void _calculateNextJumpTime() {
    // Use reactionTime as the base interval
    // reactionTime: 0.05s (50ms) = superhuman, 0.5s (500ms) = slow
    final baseInterval = reactionTime * 3; // Convert reaction time to jump interval
    
    // Variation based on mistakeRate (more mistakes = more inconsistency)
    final variationRange = mistakeRate * 2; // 0.02 = 4% variation, 0.20 = 40% variation
    final variation = 1.0 - variationRange + (_random.nextDouble() * variationRange * 2);
    
    _nextJumpTime = baseInterval * variation;
    
    // Skilled bots (low reaction time) are more consistent
    if (reactionTime < 0.2) {
      _nextJumpTime = baseInterval * (0.9 + _random.nextDouble() * 0.2); // 90-110% consistency
    }
  }
  
  /// Make the bot jump
  void _jump() {
    // ✅ REFACTOR v2.0.0 Phase 2: Use JumpBehavior
    _jumpBehavior.jump();
    _timeSinceLastJump = 0;
    
    // Calculate next jump time with variation (human-like inconsistency)
    _calculateNextJumpTime();
    
    // Add velocity randomness based on mistakeRate
    // Higher mistake rate = more random jumps
    final randomness = mistakeRate * 150; // 0.02 = 3 pixels, 0.20 = 30 pixels
    velocity.y += (_random.nextDouble() * randomness) - (randomness / 2);
  }
  
  /// Increment bot score when it passes an obstacle
  void incrementScore() {
    if (!_isActive) return;
    _score++;
    safePrint('🤖 Bot scored! Current score: $_score');
  }
  
  /// Get current bot score
  int get score => _score;
  
  /// Check if bot is still active
  bool get isActive => _isActive;
  
  /// Crash the bot (called when it hits an obstacle or ground)
  void crash() {
    if (!_isActive) return;
    _isActive = false;
    safePrint('🤖 Bot crashed! Final score: $_score');
  }
  
  /// Reset bot for new level
  void reset() {
    _score = 0;
    _isActive = true;
    velocity.setZero(); // ✅ REFACTOR v2.0.0 Phase 2: Reset velocity Vector2
    _timeSinceLastJump = 0;
    _isHesitating = false;
    _hesitationTimer = 0;
    _calculateNextJumpTime(); // Reset jump timing
    position.y = game.size.y / 2;
  }
}

