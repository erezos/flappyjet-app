import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';
// 🔥 CLEANUP: Using manual collision detection - no automatic collision imports needed
import 'package:flutter/material.dart';

import '../core/game_config.dart';
import '../core/game_themes.dart';
import '../core/jet_skins.dart';
// import 'jet_fire_state.dart';
import '../flappy_game.dart'; // 🔥 FIX: Add type import for collision handling

/// Damage states for universal overlay system
enum JetDamageState {
  healthy,     // 3 hearts - no overlay
  damaged,     // 2 hearts - light damage overlay  
  critical,    // 1 heart  - heavy damage overlay
  invulnerable // Shield effect during immunity
}

/// Jet player with MONETIZABLE skin system + UNIVERSAL DAMAGE OVERLAYS
/// 🔥 BLOCKBUSTER: Uses manual collision detection for precise control!
class JetPlayer extends SpriteComponent with HasGameReference {
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
  JetDamageState? _pendingDamageState; // Damage state to apply when invulnerability ends
  double _damageFlashTime = 0.0;
  // Removed unused field // kept for future shield re-enable
  
  // Removed legacy fire state manager (temporary)
  
  JetPlayer(Vector2 position, this._environmentTheme, {JetSkin? jetSkin}) 
    : _currentSkin = jetSkin ?? JetSkinCatalog.starterJet,
      super(position: position, size: Vector2.all(GameConfig.jetSize)) {
    // 🔍 CRITICAL DEBUG: Track jet creation with full context
    safePrint('🚀 JET CREATION: HashCode=$hashCode, Position=$position, Theme=$_environmentTheme.displayName');
    safePrint('📍 CREATION STACK TRACE:');
    safePrint(StackTrace.current.toString().split('\n').take(10).join('\n'));
    safePrint('🚀 JET CREATION COMPLETE: $hashCode');
  }
  
  @override
  Future<void> onLoad() async {
    safePrint('🔄 JET ONLOAD START: HashCode=$hashCode, Position=$position');
    
    _startY = position.y;
    anchor = Anchor.center; // 🔥 BLOCKBUSTER: Proper anchor for collision detection
    
    // Fire system disabled temporarily
    await _loadJetSprite();
    await _loadDamageOverlays(); // Load universal damage effects
    
    // 🔥 BLOCKBUSTER: Using manual collision detection for precise control (no automatic hitbox)
    
    safePrint('✅ JET ONLOAD COMPLETE: HashCode=$hashCode - Enhanced Jet Player with fire system and collision loaded!');
  }
  
  /// Load universal damage overlays that work with ANY jet skin
  Future<void> _loadDamageOverlays() async {
    // ALWAYS use procedural effects for now - no asset loading crashes
    safePrint('💥 Using procedural damage effects (no asset dependencies)');
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
        safePrint('🧪 Attempting to load jet skin sprite from: $p');
        sprite = await Sprite.load(p);
        _usingImageAssets = true;
        safePrint('🛒 Loaded purchased skin: ${_currentSkin.displayName} (path: $p, price: \$${_currentSkin.price})');
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
        safePrint('⚠️ Failed to load sprite from "$p": $e');
      }
    }
    safePrint('💰 Purchased skin not found via any path, using programmatic sprite for ${_currentSkin.displayName}...');
    
    // Fallback: Simple programmatic sprite
    sprite = await _createProgrammaticSprite();
    _usingImageAssets = false;
    safePrint('🔧 Using simple programmatic sprite for ${_currentSkin.displayName}');
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
        // BULLETPROOF: Shield is ALWAYS visible when damage state is invulnerable
        // This ensures perfect synchronization between invulnerability and shield
        _renderShieldEffect(canvas);
        break;
    }
  }
  

  /// Render shield effect during invulnerability - Neon Outline Glow only
  void _renderShieldEffect(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2); // Center of the jet sprite
    final pulsePhase = (_invulnerabilityTime * 3.0) % (2 * math.pi); // 3 pulses per second
    final pulseIntensity = (math.sin(pulsePhase) * 0.3 + 0.7); // Pulse between 0.4 and 1.0
    
    // Always use Neon Outline Glow (Type 2)
    _renderNeonGlow(canvas, center, pulseIntensity, pulsePhase);
  }
  
  /// Circular Neon Shield - Vibrant circular shield with colorful neon effects
  void _renderNeonGlow(Canvas canvas, Offset center, double pulseIntensity, double pulsePhase) {
    final shieldRadius = size.x * 0.75; // Circular shield around the jet
    
    // Rainbow neon colors cycling through spectrum
    final colorPhase = (pulsePhase * 0.5) % (2 * math.pi);
    final neonColors = [
      const Color(0xFFFF0080), // Hot Pink
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF00FF41), // Neon Green
      const Color(0xFFFFD700), // Gold
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF4081), // Pink
    ];
    
    // Get current color by cycling through the spectrum
    final colorIndex = (colorPhase / (2 * math.pi) * neonColors.length).floor();
    final nextColorIndex = (colorIndex + 1) % neonColors.length;
    final colorLerp = (colorPhase / (2 * math.pi) * neonColors.length) % 1.0;
    
    final currentNeonColor = Color.lerp(
      neonColors[colorIndex],
      neonColors[nextColorIndex],
      colorLerp,
    )!;
    
    // Outer glow ring (largest, most transparent)
    final outerGlowPaint = Paint()
      ..color = currentNeonColor.withValues(alpha: 0.3 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    
    // Middle glow ring
    final middleGlowPaint = Paint()
      ..color = currentNeonColor.withValues(alpha: 0.6 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    
    // Main neon ring
    final neonPaint = Paint()
      ..color = currentNeonColor.withValues(alpha: 0.9 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    
    // Inner bright core ring
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Add pulsing effect to radius
    final pulsingRadius = shieldRadius + (math.sin(pulsePhase * 4) * 5 * pulseIntensity);
    
    // Draw concentric circular rings for layered neon effect
    canvas.drawCircle(center, pulsingRadius + 6, outerGlowPaint);
    canvas.drawCircle(center, pulsingRadius + 3, middleGlowPaint);
    canvas.drawCircle(center, pulsingRadius, neonPaint);
    canvas.drawCircle(center, pulsingRadius - 1, corePaint);
    
    // Add sparkle effects around the circle
    _drawSparkleEffects(canvas, center, pulsingRadius, pulsePhase, currentNeonColor, pulseIntensity);
  }
  
  /// Draw sparkle effects around the circular shield
  void _drawSparkleEffects(Canvas canvas, Offset center, double radius, double phase, Color neonColor, double intensity) {
    final sparkleCount = 8;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * math.pi + phase * 0.3;
      final sparkleRadius = radius + 15 + math.sin(phase * 2 + i) * 8;
      final sparkleX = center.dx + math.cos(angle) * sparkleRadius;
      final sparkleY = center.dy + math.sin(angle) * sparkleRadius;
      
      final sparklePaint = Paint()
        ..color = neonColor.withValues(alpha: 0.7 * intensity * ((math.sin(phase * 3 + i) + 1) / 2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      // Draw cross-shaped sparkles
      final sparkleSize = 4.0 * intensity;
      canvas.drawLine(
        Offset(sparkleX - sparkleSize, sparkleY),
        Offset(sparkleX + sparkleSize, sparkleY),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - sparkleSize),
        Offset(sparkleX, sparkleY + sparkleSize),
        sparklePaint,
      );
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
        setInvulnerable(false); // Use the method to ensure proper state transition
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
    // Apply pending damage state if available, otherwise default to healthy
    if (_damageState == JetDamageState.invulnerable) {
      _damageState = _pendingDamageState ?? JetDamageState.healthy;
      _pendingDamageState = null; // Clear pending state
      safePrint('🛡️ Applied pending damage state: ${_damageState.name}');
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
    safePrint('🚀 Enhanced Jet Player started - ${_currentSkin.displayName} skin active');
  }
  
  void stopPlaying() {
    _isPlaying = false;
    velocity = Vector2.zero(); // Stop all movement
    safePrint('🛑 Enhanced Jet Player stopped');
  }
  
  void setInvulnerable([bool invulnerable = true]) {
    _isInvulnerable = invulnerable;
    if (invulnerable) {
      _invulnerabilityTime = 0.0;
      _damageState = JetDamageState.invulnerable; // Show shield effect
      safePrint('🛡️ Neon Shield activated - invulnerable for ${GameConfig.invulnerabilityDuration}s');
    } else {
      // When invulnerability ends, return to appropriate damage state
      _updateDamageStateFromInvulnerability();
      safePrint('🛡️ Neon Shield deactivated - vulnerable again');
    }
  }
  
  /// Set damage state based on remaining lives (GAME INTEGRATION POINT)
  void setDamageStateFromLives(int remainingLives) {
    // CRITICAL: Never override invulnerability state - shield must stay synchronized
    if (_isInvulnerable) {
      // Store the target damage state for when invulnerability ends
      _pendingDamageState = _getDamageStateForLives(remainingLives);
      safePrint('💥 Damage state deferred during invulnerability: ${_pendingDamageState?.name} ($remainingLives lives remaining)');
      return;
    }
    
    _damageState = _getDamageStateForLives(remainingLives);
    safePrint('💥 Jet damage state: ${_damageState.name} ($remainingLives lives remaining)');
  }
  
  /// Get appropriate damage state for given lives (helper method)
  JetDamageState _getDamageStateForLives(int remainingLives) {
    switch (remainingLives) {
      case 3:
        return JetDamageState.healthy;
      case 2:
        _triggerDamageFlash();
        return JetDamageState.damaged;
      case 1:
        _triggerDamageFlash();
        return JetDamageState.critical;
      default:
        return JetDamageState.critical; // Game over state
    }
  }
  
  /// Trigger damage flash effect
  void _triggerDamageFlash() {
    _damageFlashTime = 0.5; // Flash for half a second
  }
  
  /// Heal the jet (when lives are restored)
  void healJet() {
    _damageState = JetDamageState.healthy;
    _damageFlashTime = 0.0;
    safePrint('💚 Jet healed to healthy state');
  }
  
  /// Update environment theme (automatic) - does NOT change jet skin
  Future<void> updateEnvironmentTheme(GameTheme newTheme) async {
    if (_environmentTheme.id != newTheme.id) {
      _environmentTheme = newTheme;
      // Only reload sprite if using generated graphics (not purchased assets)
      if (!_usingImageAssets) {
        await _loadJetSprite();
      }
      safePrint('🌍 Environment updated to ${newTheme.displayName} (jet skin unchanged: ${_currentSkin.displayName})');
    }
  }
  
  /// Change jet skin (player purchase) - MONETIZATION POINT
  Future<void> changeJetSkin(JetSkin newSkin) async {
    if (_currentSkin.id != newSkin.id) {
      _currentSkin = newSkin;
      await _loadJetSprite();
      safePrint('💰 SKIN CHANGED: Player equipped ${newSkin.displayName} (\$${newSkin.price})');
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
    _pendingDamageState = null;
    _damageFlashTime = 0.0;
          // Shield pulse reset removed
    
    // Reload sprite for new environment (but keep purchased skin)
    _loadJetSprite();
  }
  
  /// Update invulnerability - backward compatibility
  void updateInvulnerability(double dt) {
    // CRITICAL: This method should NOT be used - invulnerability is handled internally
    // But if called, ensure it uses proper setInvulnerable method for shield sync
    if (_isInvulnerable) {
      _invulnerabilityTime += dt;
      if (_invulnerabilityTime >= GameConfig.invulnerabilityDuration) {
        setInvulnerable(false); // ✅ Use proper method to sync shield
      }
    }
  }
  
  /// 🔥 BLOCKBUSTER: Handle ground collision properly
  void _handleGroundCollision() {
    safePrint('🔥 BLOCKBUSTER: Ground collision detected!');
    if (game is FlappyGame) {
      (game as FlappyGame).handleCollision();
    }
  }
  
  /// 🔥 BLOCKBUSTER: Handle top boundary collision (hitting ceiling)
  void _handleTopBoundaryCollision() {
    safePrint('🔥 BLOCKBUSTER: Top boundary collision detected!');
    if (game is FlappyGame) {
      (game as FlappyGame).handleCollision();
    }
  }

  /// Get collision bounds for this jet player
  ui.Rect getBounds() {
    final halfSize = size / 2;
    return ui.Rect.fromLTWH(
      position.x - halfSize.x,
      position.y - halfSize.y,
      size.x,
      size.y,
    );
  }
  
  // 🔥 BLOCKBUSTER: Using manual collision detection only (no automatic callbacks)
}