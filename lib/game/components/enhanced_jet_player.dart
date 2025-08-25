import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
// 🔥 CLEANUP: Using manual collision detection - no automatic collision imports needed
import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../core/jet_skins.dart';
// import 'jet_fire_state.dart';
import '../enhanced_flappy_game.dart'; // 🔥 FIX: Add type import for collision handling

/// Damage states for universal overlay system
enum JetDamageState {
  healthy,     // 3 hearts - no overlay
  damaged,     // 2 hearts - light damage overlay  
  critical,    // 1 heart  - heavy damage overlay
  invulnerable // Shield effect during immunity
}

/// Enhanced jet player with MONETIZABLE skin system + UNIVERSAL DAMAGE OVERLAYS
/// 🔥 BLOCKBUSTER: Uses manual collision detection for precise control!
class EnhancedJetPlayer extends SpriteComponent with HasGameReference {
  Vector2 velocity = Vector2.zero();
  double _bobTime = 0.0;
  late double _startY;
  bool _isPlaying = false;
  bool _isInvulnerable = false;
  double _invulnerabilityTime = 0.0;
  GameTheme _environmentTheme; // Environmental theme (changes automatically)
  JetSkin _currentSkin;        // Jet skin (player choice, purchased)
  bool _usingImageAssets = false;
  
  // UNIVERSAL DAMAGE OVERLAY SYSTEM 🔥
  JetDamageState _damageState = JetDamageState.healthy;
  double _damageFlashTime = 0.0;
  // Removed unused field // kept for future shield re-enable
  
  // Removed legacy fire state manager (temporary)
  
  EnhancedJetPlayer(Vector2 position, this._environmentTheme, {JetSkin? jetSkin}) 
    : _currentSkin = jetSkin ?? JetSkinCatalog.starterJet,
      super(position: position, size: Vector2.all(GameConfig.jetSize)) {
    // 🔍 CRITICAL DEBUG: Track jet creation with full context
    debugPrint('🚀 JET CREATION: HashCode=$hashCode, Position=$position, Theme=$_environmentTheme.displayName');
    debugPrint('📍 CREATION STACK TRACE:');
    debugPrint(StackTrace.current.toString().split('\n').take(10).join('\n'));
    debugPrint('🚀 JET CREATION COMPLETE: $hashCode');
  }
  
  @override
  Future<void> onLoad() async {
    debugPrint('🔄 JET ONLOAD START: HashCode=$hashCode, Position=$position');
    
    _startY = position.y;
    anchor = Anchor.center; // 🔥 BLOCKBUSTER: Proper anchor for collision detection
    
    // Fire system disabled temporarily
    await _loadJetSprite();
    await _loadDamageOverlays(); // Load universal damage effects
    
    // 🔥 BLOCKBUSTER: Using manual collision detection for precise control (no automatic hitbox)
    
    debugPrint('✅ JET ONLOAD COMPLETE: HashCode=$hashCode - Enhanced Jet Player with fire system and collision loaded!');
  }
  
  /// Load universal damage overlays that work with ANY jet skin
  Future<void> _loadDamageOverlays() async {
    // ALWAYS use procedural effects for now - no asset loading crashes
    debugPrint('💥 Using procedural damage effects (no asset dependencies)');
    // Procedural damage effects are rendered directly in render() method
  }
  
  /// Load jet sprite - prioritizes PURCHASED skin, not theme
  Future<void> _loadJetSprite() async {
    // Try multiple candidate paths to be resilient to assetPath formats
    final List<String> candidates = [];
    final base = _currentSkin.assetPath.startsWith('assets/')
        ? _currentSkin.assetPath.substring('assets/'.length)
        : _currentSkin.assetPath;
    candidates.add(base); // e.g., images/jets/flame_jet.png or jets/sky_jet.png
    if (!base.startsWith('images/')) {
      candidates.add('images/$base'); // e.g., images/jets/...
    }
    if (!base.startsWith('assets/')) {
      candidates.add('assets/$base'); // e.g., assets/images/jets/...
    }
    if (!base.startsWith('assets/images/')) {
      candidates.add('assets/images/$base');
    }

    for (final p in candidates.toSet()) {
      try {
        debugPrint('🧪 Attempting to load jet skin sprite from: $p');
        sprite = await Sprite.load(p);
        _usingImageAssets = true;
        debugPrint('🛒 Loaded purchased skin: ${_currentSkin.displayName} (path: $p, price: \$${_currentSkin.price})');
        // Preserve aspect ratio of source sprite by using GameConfig.jetSize as target HEIGHT
        try {
          // If skin specifies explicit render size, use it
          if (_currentSkin.renderWidth != null && _currentSkin.renderHeight != null) {
            size = Vector2(_currentSkin.renderWidth!, _currentSkin.renderHeight!);
          } else {
            final src = sprite?.srcSize; // image size
            if (src != null && src.y > 0) {
              final targetHeight = GameConfig.jetSize;
              final targetWidth = (src.x / src.y) * targetHeight;
              size = Vector2(targetWidth, targetHeight);
            }
          }
        } catch (_) {}
        return;
      } catch (e) {
        debugPrint('⚠️ Failed to load sprite from "$p": $e');
      }
    }
    debugPrint('💰 Purchased skin not found via any path, using programmatic sprite for ${_currentSkin.displayName}...');
    
    // Fallback: Simple programmatic sprite
    sprite = await _createProgrammaticSprite();
    _usingImageAssets = false;
    debugPrint('🔧 Using simple programmatic sprite for ${_currentSkin.displayName}');
  }
  
  /// Create professional programmatic sprite as fallback
  Future<Sprite> _createProgrammaticSprite() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = Size(GameConfig.jetSize, GameConfig.jetSize);
    
    _paintJet(canvas, size);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    return Sprite(image);
  }
  
  /// Paint jet design with SKIN colors (not theme colors)
  void _paintJet(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final jetWidth = size.width * 0.8;
    final jetHeight = size.height * 0.6;
    
    // Use skin-specific colors based on rarity and type
    final rarityColor = JetSkinColors.getRarityColor(_currentSkin.rarity);
    final skinColor = _getSkinColor();
    
    // Draw jet body with skin colors
    final bodyPaint = Paint()
      ..color = skinColor
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    // Shadow (offset slightly)
    final shadowPath = _createJetPath(center.translate(1, 1), jetWidth, jetHeight);
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Main body
    final bodyPath = _createJetPath(center, jetWidth, jetHeight);
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Wing details with skin accent color
    _drawWingDetails(canvas, center, jetWidth, jetHeight, rarityColor);
    
    // Cockpit with skin colors
    _drawCockpit(canvas, center, jetWidth, jetHeight, rarityColor);
    
    // Thrust effect based on skin style
    if (_isPlaying && velocity.y < 0) {
      _drawThrustEffect(canvas, center, jetWidth, jetHeight);
    }
  }
  
  /// Get skin-specific color based on skin type
  Color _getSkinColor() {
    switch (_currentSkin.id) {
      case 'golden_falcon':
        return const Color(0xFFFFD700); // Gold
      case 'silver_lightning':
        return const Color(0xFFC0C0C0); // Silver
      case 'stealth_bomber':
        return const Color(0xFF2C2C2C); // Dark gray
      case 'neon_racer':
        return const Color(0xFF00FFFF); // Cyan
      case 'plasma_destroyer':
        return const Color(0xFF8A2BE2); // Blue violet
      case 'dragon_wing':
        return const Color(0xFF8B0000); // Dark red
      case 'phoenix_flame':
        return const Color(0xFFFF4500); // Orange red
      default:
        return const Color(0xFF4A90E2); // Default blue
    }
  }
  
  /// Create the main jet shape path
  Path _createJetPath(Offset center, double width, double height) {
    final path = Path();
    
    // Sleek fighter jet shape
    path.moveTo(center.dx + width * 0.3, center.dy); // nose
    path.lineTo(center.dx + width * 0.1, center.dy - height * 0.2); // top wing
    path.lineTo(center.dx - width * 0.2, center.dy - height * 0.3); // top wing back
    path.lineTo(center.dx - width * 0.3, center.dy - height * 0.1); // top body
    path.lineTo(center.dx - width * 0.4, center.dy); // tail center
    path.lineTo(center.dx - width * 0.3, center.dy + height * 0.1); // bottom body
    path.lineTo(center.dx - width * 0.2, center.dy + height * 0.3); // bottom wing back
    path.lineTo(center.dx + width * 0.1, center.dy + height * 0.2); // bottom wing
    path.close();
    
    return path;
  }
  
  /// Draw wing details
  void _drawWingDetails(Canvas canvas, Offset center, double width, double height, Color accentColor) {
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    
    // Wing stripes
    for (int i = 0; i < 2; i++) {
      final stripe = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - width * 0.1 + i * width * 0.1, center.dy),
          width: width * 0.05,
          height: height * 0.3,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(stripe, accentPaint);
    }
  }
  
  /// Draw cockpit
  void _drawCockpit(Canvas canvas, Offset center, double width, double height, Color accentColor) {
    final cockpitPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final cockpitRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + width * 0.1, center.dy),
        width: width * 0.3,
        height: height * 0.4,
      ),
      const Radius.circular(6),
    );
    
    canvas.drawRRect(cockpitRect, cockpitPaint);
    
    // Cockpit highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + width * 0.15, center.dy - height * 0.05),
        width: width * 0.15,
        height: height * 0.2,
      ),
      const Radius.circular(3),
    );
    
    canvas.drawRRect(highlightRect, highlightPaint);
  }
  
  /// Draw thrust effect using skin colors
  void _drawThrustEffect(Canvas canvas, Offset center, double width, double height) {
    final skinColor = _getSkinColor();
    final rarityColor = JetSkinColors.getRarityColor(_currentSkin.rarity);
    
    final thrustPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          skinColor.withValues(alpha: 0.8),
          rarityColor.withValues(alpha: 0.6),
          _environmentTheme.colors.background.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(center.dx - width * 0.4, center.dy),
        width: width * 0.3,
        height: height * 0.4,
      ));
    
    // Thrust flame with skin colors
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - width * 0.45, center.dy),
        width: width * 0.4,
        height: height * 0.3,
      ),
      thrustPaint,
    );
  }
  
  @override
  void render(Canvas canvas) {
    // Draw the base sprite normally
    super.render(canvas);

    // Shield/damage overlay in world space
    _renderDamageOverlay(canvas);
  }
  

  
  /// Render universal damage overlay that works with ANY jet skin
  void _renderDamageOverlay(Canvas canvas) {
    switch (_damageState) {
      case JetDamageState.healthy:
        // No overlay needed
        break;
        
      case JetDamageState.damaged:
        _renderDamageEffect(canvas, 0.6, Colors.orange);
        break;
        
      case JetDamageState.critical:
        _renderDamageEffect(canvas, 0.8, Colors.red);
        break;
        
       case JetDamageState.invulnerable:
        // Shield disabled for now
        break;
    }
  }
  
  /// Render damage effect with cracks and smoke
  void _renderDamageEffect(Canvas canvas, double intensity, Color damageColor) {
    // Damage flash effect
    if (_damageFlashTime > 0) {
      final flashAlpha = (math.sin(_damageFlashTime * 20) + 1) / 2;
      canvas.saveLayer(
        size.toRect(),
        Paint()..color = damageColor.withValues(alpha: flashAlpha * 0.3),
      );
      canvas.restore();
    }
    
    // Damage overlay tint
    canvas.saveLayer(
      size.toRect(),
      Paint()..color = damageColor.withValues(alpha: intensity * 0.2),
    );
    canvas.restore();
    
    // Procedural damage cracks if no assets available
    _drawProceduralDamage(canvas, intensity, damageColor);
  }
  
  // Shield effect disabled for now
  
  /// Draw procedural damage effects as fallback
  void _drawProceduralDamage(Canvas canvas, double intensity, Color damageColor) {
    final rect = size.toRect();
    final random = math.Random(42); // Fixed seed for consistent cracks
    
    // Draw crack lines
    final crackPaint = Paint()
      ..color = damageColor.withValues(alpha: intensity * 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < (intensity * 5).toInt(); i++) {
      final start = Offset(
        random.nextDouble() * rect.width,
        random.nextDouble() * rect.height,
      );
      final end = Offset(
        start.dx + (random.nextDouble() - 0.5) * 20,
        start.dy + (random.nextDouble() - 0.5) * 20,
      );
      
      canvas.drawLine(start, end, crackPaint);
    }
  }
  
  @override
  void update(double dt) {
    // Fire system disabled
    
    // Update invulnerability system
    if (_isInvulnerable) {
      _invulnerabilityTime += dt;
      if (_invulnerabilityTime >= GameConfig.invulnerabilityDuration) {
        _isInvulnerable = false;
        _invulnerabilityTime = 0.0;
        // Update damage state when invulnerability ends
        _updateDamageStateFromInvulnerability();
      }
    }
    
    // Update damage overlay animations
    _updateDamageAnimations(dt);
    
    if (_isPlaying) {
      updatePlaying(dt);
    } else {
      updateWaiting(dt);
    }
  }
  
  /// Update damage overlay animations
  void _updateDamageAnimations(double dt) {
    // Update damage flash timer
    if (_damageFlashTime > 0) {
      _damageFlashTime -= dt;
      if (_damageFlashTime <= 0) {
        _damageFlashTime = 0;
      }
    }
    
    // Shield pulse animation removed
  }
  
  /// Update damage state when invulnerability ends
  void _updateDamageStateFromInvulnerability() {
    // Return to appropriate damage state based on current health
    // This will be called by the game when lives change
    if (_damageState == JetDamageState.invulnerable) {
      _damageState = JetDamageState.healthy; // Default to healthy
    }
  }
  
  void updateWaiting(double dt) {
    _bobTime += dt;
    final bobOffset = math.sin(_bobTime * GameConfig.startScreenBobSpeed) * GameConfig.startScreenBobAmount;
    position.y = _startY + bobOffset;
  }
  
  void updatePlaying(double dt) {
    velocity.y += GameConfig.gravity * dt;
    
    // 🔥 BLOCKBUSTER: Apply velocity limits for better control
    velocity.y = velocity.y.clamp(-GameConfig.maxFallSpeed, GameConfig.maxFallSpeed);
    
    position.y += velocity.y * dt;
    
    // 🔥 BLOCKBUSTER: PROPER SCREEN BOUNDARIES aligned with ground
    final halfSize = size.y / 2;
    
    // Top boundary
    if (position.y - halfSize < 0) {
      position.y = halfSize;
      velocity.y = 0;
      // 🔥 BLOCKBUSTER: Top screen collision should also trigger collision (like bottom boundary)
      if (!_isInvulnerable && _isPlaying) {
        _handleTopBoundaryCollision();
      }
    }
    
    // Bottom boundary aligned with game's ground (game.size.y - 50)
    final groundY = game.size.y - 50;
    final groundLevel = groundY - halfSize;
    if (position.y + halfSize > groundY) {
      position.y = groundLevel;
      velocity.y = 0;
      // 🔥 BLOCKBUSTER: Trigger ground collision ONLY if not invulnerable and not already triggered
      if (!_isInvulnerable && _isPlaying) {
        _handleGroundCollision();
      }
    }
  }
  
  void jump() {
    velocity.y = GameConfig.jumpVelocity;
  }
  
  void startPlaying() {
    _isPlaying = true;
    debugPrint('🚀 Enhanced Jet Player started - ${_currentSkin.displayName} skin active');
  }
  
  void stopPlaying() {
    _isPlaying = false;
    velocity = Vector2.zero(); // Stop all movement
    debugPrint('🛑 Enhanced Jet Player stopped');
  }
  
  void setInvulnerable([bool invulnerable = true]) {
    _isInvulnerable = invulnerable;
    if (invulnerable) {
      _invulnerabilityTime = 0.0;
      _damageState = JetDamageState.invulnerable; // Show shield effect
      // Shield pulse reset removed
    }
  }
  
  /// Set damage state based on remaining lives (GAME INTEGRATION POINT)
  void setDamageStateFromLives(int remainingLives) {
    if (_isInvulnerable) {
      _damageState = JetDamageState.invulnerable;
      return;
    }
    
    switch (remainingLives) {
      case 3:
        _damageState = JetDamageState.healthy;
        break;
      case 2:
        _damageState = JetDamageState.damaged;
        _triggerDamageFlash();
        break;
      case 1:
        _damageState = JetDamageState.critical;
        _triggerDamageFlash();
        break;
      default:
        _damageState = JetDamageState.critical; // Game over state
        break;
    }
    
    debugPrint('💥 Jet damage state: ${_damageState.name} ($remainingLives lives remaining)');
  }
  
  /// Trigger damage flash effect
  void _triggerDamageFlash() {
    _damageFlashTime = 0.5; // Flash for half a second
  }
  
  /// Heal the jet (when lives are restored)
  void healJet() {
    _damageState = JetDamageState.healthy;
    _damageFlashTime = 0.0;
    debugPrint('💚 Jet healed to healthy state');
  }
  
  /// Update environment theme (automatic) - does NOT change jet skin
  Future<void> updateEnvironmentTheme(GameTheme newTheme) async {
    if (_environmentTheme.id != newTheme.id) {
      _environmentTheme = newTheme;
      // Only reload sprite if using generated graphics (not purchased assets)
      if (!_usingImageAssets) {
        await _loadJetSprite();
      }
      debugPrint('🌍 Environment updated to ${newTheme.displayName} (jet skin unchanged: ${_currentSkin.displayName})');
    }
  }
  
  /// Change jet skin (player purchase) - MONETIZATION POINT
  Future<void> changeJetSkin(JetSkin newSkin) async {
    if (_currentSkin.id != newSkin.id) {
      _currentSkin = newSkin;
      await _loadJetSprite();
      debugPrint('💰 SKIN CHANGED: Player equipped ${newSkin.displayName} (\$${newSkin.price})');
    }
  }
  
  bool get isInvulnerable => _isInvulnerable;
  bool get isUsingImageAssets => _usingImageAssets;
  JetSkin get currentSkin => _currentSkin;
  GameTheme get environmentTheme => _environmentTheme;
  
  /// Reset jet for new game - PRESERVES purchased skin
  void reset(Vector2 newPosition, GameTheme newEnvironmentTheme) {
    position = newPosition;
    _environmentTheme = newEnvironmentTheme;
    velocity = Vector2.zero();
    _isPlaying = false;
    _isInvulnerable = false;
    _invulnerabilityTime = 0.0;
    _bobTime = 0.0;
    _startY = newPosition.y;
    
    // Reset damage system to healthy state
    _damageState = JetDamageState.healthy;
    _damageFlashTime = 0.0;
          // Shield pulse reset removed
    
    // Reload sprite for new environment (but keep purchased skin)
    _loadJetSprite();
  }
  
  /// Update invulnerability - backward compatibility
  void updateInvulnerability(double dt) {
    // This is now handled internally in update()
    if (_isInvulnerable) {
      _invulnerabilityTime += dt;
      if (_invulnerabilityTime >= GameConfig.invulnerabilityDuration) {
        _isInvulnerable = false;
        _invulnerabilityTime = 0.0;
      }
    }
  }
  
  /// 🔥 BLOCKBUSTER: Handle ground collision properly
  void _handleGroundCollision() {
    debugPrint('🔥 BLOCKBUSTER: Ground collision detected!');
    if (game is EnhancedFlappyGame) {
      (game as EnhancedFlappyGame).handleCollision();
    }
  }
  
  /// 🔥 BLOCKBUSTER: Handle top boundary collision (hitting ceiling)
  void _handleTopBoundaryCollision() {
    debugPrint('🔥 BLOCKBUSTER: Top boundary collision detected!');
    if (game is EnhancedFlappyGame) {
      (game as EnhancedFlappyGame).handleCollision();
    }
  }
  
  // 🔥 BLOCKBUSTER: Using manual collision detection only (no automatic callbacks)
} 