/// 🤖 BOT JET PLAYER
/// 
/// A simplified AI-controlled jet that flies alongside the player in bot battle levels.
/// The bot follows a predetermined flight pattern and scores points automatically.
library;

import 'dart:math';
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
import '../core/game_config.dart';

/// Map bot theme names to actual jet sprite files
String _getBotJetSpriteFileName(String botJetSkin) {
  // Direct mapping - bot skin names now match actual jet file names
  const botToSpriteMap = {
    'green_lightning': 'green_lightning',
    'desert_storm': 'desert_storm',
    'magma_fracture': 'magma_fracture',
    'blaze': 'blaze',
    'storm': 'storm',
    'stealth_dragon': 'stealth_dragon',
    'stealth_bomber': 'stealth_bomber',
  };
  
  return botToSpriteMap[botJetSkin] ?? botJetSkin;  // Use skin name directly if not in map
}

class BotJetPlayer extends SpriteComponent with HasGameRef {
  final String skinId;
  final double difficulty; // 0.0 = easy, 1.0 = hard
  
  // Bot state
  double _verticalVelocity = 0;
  double _targetY = 0;
  int _score = 0;
  bool _isActive = true;
  
  // Bot AI parameters
  final double _jumpInterval = 1.5; // Jump every 1.5 seconds
  double _timeSinceLastJump = 0;
  final double _gravity = GameConfig.gravity;
  final double _jumpVelocity = GameConfig.jumpVelocity;
  
  // Visual parameters (match player jet size from GameConfig)
  static const double botSize = 60.0; // Same as player jet
  static const double botXPosition = 50.0; // Flies on the left side
  
  BotJetPlayer({
    required this.skinId,
    required this.difficulty,
  });
  
  @override
  Future<void> onLoad() async {
    // Load bot jet skin with proper mapping
    final actualSkinName = _getBotJetSpriteFileName(skinId);
    final skinPath = 'jets/$actualSkinName.png';
    
    safePrint('🤖 Loading bot jet skin: $skinId -> $skinPath');
    
    try {
      sprite = await gameRef.loadSprite(skinPath);
      safePrint('🤖 ✅ Bot jet skin loaded successfully: $actualSkinName');
    } catch (e) {
      safePrint('🤖 ❌ Failed to load bot skin: $e, using fallback');
      // Use sky_jet as final fallback
      sprite = await gameRef.loadSprite('jets/sky_jet.png');
    }
    
    // Set size and initial position
    size = Vector2(botSize, botSize);
    position = Vector2(botXPosition, gameRef.size.y / 2);
    anchor = Anchor.center;
    
    // Adjust jump interval based on difficulty
    // Easier bots jump less frequently, harder bots jump more strategically
    
    safePrint('🤖 Bot jet loaded at position: $position with difficulty: $difficulty');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isActive) return;
    
    // Update bot AI
    _updateBotAI(dt);
    
    // Apply gravity and velocity
    _verticalVelocity += _gravity * dt;
    position.y += _verticalVelocity * dt;
    
    // Keep bot within bounds
    final minY = botSize / 2;
    final maxY = gameRef.size.y - 50 - (botSize / 2); // 50 = ground height
    
    if (position.y < minY) {
      position.y = minY;
      _verticalVelocity = 0;
    } else if (position.y > maxY) {
      position.y = maxY;
      _verticalVelocity = 0;
      // Bot crashed into ground - deactivate
      _isActive = false;
      safePrint('🤖 Bot crashed! Final score: $_score');
    }
  }
  
  /// Bot AI logic - makes the bot jump at strategic times
  void _updateBotAI(double dt) {
    _timeSinceLastJump += dt;
    
    // Calculate target Y position (center of screen)
    _targetY = gameRef.size.y / 2;
    
    // Jump if:
    // 1. Enough time has passed since last jump
    // 2. Bot is falling and below target position
    final shouldJump = _timeSinceLastJump >= _jumpInterval ||
        (position.y > _targetY + 50 && _verticalVelocity > 0);
    
    if (shouldJump) {
      _jump();
    }
  }
  
  /// Make the bot jump
  void _jump() {
    _verticalVelocity = _jumpVelocity;
    _timeSinceLastJump = 0;
    
    // Add some randomness based on difficulty
    final randomness = (1.0 - difficulty) * 50; // Less randomness for harder bots
    final random = Random();
    _verticalVelocity += (random.nextDouble() * randomness) - (randomness / 2);
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
    _verticalVelocity = 0;
    _timeSinceLastJump = 0;
    position.y = gameRef.size.y / 2;
  }
}

