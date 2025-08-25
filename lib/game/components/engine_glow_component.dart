/// 🔥 Engine Glow Component - Continuous Visual Feedback
/// Provides satisfying visual feedback for jet engine activity
library;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Engine glow intensity levels
enum GlowIntensity {
  idle,      // Minimal glow when not accelerating
  boosting,  // Medium glow during normal flight
  burst,     // Maximum glow during tap/jump
}

/// Engine glow visual style
enum GlowStyle {
  classic,   // Traditional blue/white glow
  fire,      // Orange/red flame effect
  plasma,    // Purple/pink energy effect
  ice,       // Blue/cyan crystalline effect
  cosmic,    // Rainbow/stellar effect
  void_,     // Dark purple/black energy
}

/// Individual glow particle for advanced effects
class GlowParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifetime;
  double maxLifetime;
  
  GlowParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxLifetime,
  }) : lifetime = 0.0;
  
  bool get isAlive => lifetime < maxLifetime;
  double get alpha => (1.0 - lifetime / maxLifetime).clamp(0.0, 1.0);
  
  void update(double dt) {
    lifetime += dt;
    position.add(velocity * dt);
    velocity.scale(0.98); // Gradual deceleration
  }
  
  void render(Canvas canvas) {
    if (!isAlive) return;
    
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      size * alpha,
      paint,
    );
  }
}

/// Engine Glow Component - attached to jet player
class EngineGlowComponent extends Component {
  // Configuration
  GlowStyle _glowStyle = GlowStyle.classic;
  double _glowIntensity = 1.0;
  GlowIntensity _currentIntensity = GlowIntensity.idle;
  
  // Visual state
  Vector2 _enginePosition = Vector2.zero();
  double _animationPhase = 0.0;
  double _burstTime = 0.0;
  bool _isBursting = false;
  
  // Particle system for advanced effects
  final List<GlowParticle> _particles = [];
  final math.Random _random = math.Random();
  double _particleSpawnTimer = 0.0;
  
  // Glow properties
  late Color _primaryColor;
  late Color _secondaryColor;
  late List<Color> _gradientColors;
  
  EngineGlowComponent({
    GlowStyle style = GlowStyle.classic,
    double intensity = 1.0,
  }) {
    _glowStyle = style;
    _glowIntensity = intensity;
    _updateColors();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _animationPhase += dt * 4; // Base animation speed
    
    // Handle burst timing
    if (_isBursting) {
      _burstTime += dt;
      if (_burstTime >= 0.3) { // Burst duration
        _isBursting = false;
        _burstTime = 0.0;
        _currentIntensity = GlowIntensity.boosting;
      }
    }
    
    // Update particles
    for (final particle in _particles.toList()) {
      particle.update(dt);
      if (!particle.isAlive) {
        _particles.remove(particle);
      }
    }
    
    // Spawn new particles based on intensity
    _updateParticleSpawning(dt);
  }
  
  @override
  void render(Canvas canvas) {
    // Render particles first (behind main glow)
    for (final particle in _particles) {
      particle.render(canvas);
    }
    
    // Render main engine glow
    _renderMainGlow(canvas);
    
    // Render style-specific effects
    switch (_glowStyle) {
      case GlowStyle.classic:
        _renderClassicGlow(canvas);
        break;
      case GlowStyle.fire:
        _renderFireGlow(canvas);
        break;
      case GlowStyle.plasma:
        _renderPlasmaGlow(canvas);
        break;
      case GlowStyle.ice:
        _renderIceGlow(canvas);
        break;
      case GlowStyle.cosmic:
        _renderCosmicGlow(canvas);
        break;
      case GlowStyle.void_:
        _renderVoidGlow(canvas);
        break;
    }
  }
  
  void _renderMainGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    final glowSize = 20 * intensity * _glowIntensity;
    
    // Outer glow
    final outerGlow = Paint()
      ..color = _primaryColor.withValues(alpha: 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawCircle(
      Offset(_enginePosition.x, _enginePosition.y),
      glowSize * 1.5,
      outerGlow,
    );
    
    // Middle glow
    final middleGlow = Paint()
      ..color = _primaryColor.withValues(alpha: 0.6 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(
      Offset(_enginePosition.x, _enginePosition.y),
      glowSize,
      middleGlow,
    );
    
    // Inner core
    final innerGlow = Paint()
      ..color = _secondaryColor.withValues(alpha: 0.9 * intensity);
    
    canvas.drawCircle(
      Offset(_enginePosition.x, _enginePosition.y),
      glowSize * 0.5,
      innerGlow,
    );
  }
  
  void _renderClassicGlow(Canvas canvas) {
    // Simple, clean glow - no additional effects needed
  }
  
  void _renderFireGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    
    // Flame flicker effect
    for (int i = 0; i < 5; i++) {
      final flameOffset = math.sin(_animationPhase + i) * 8;
      final flameHeight = 15 + math.sin(_animationPhase * 2 + i) * 5;
      
      final flamePaint = Paint()
        ..color = Color.lerp(Colors.orange, Colors.red, i / 5)!
            .withValues(alpha: 0.7 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            _enginePosition.x + flameOffset,
            _enginePosition.y + flameHeight / 2,
          ),
          width: 8,
          height: flameHeight,
        ),
        flamePaint,
      );
    }
  }
  
  void _renderPlasmaGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    
    // Plasma energy arcs
    final arcPaint = Paint()
      ..color = _primaryColor.withValues(alpha: 0.8 * intensity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 3; i++) {
      final arcAngle = _animationPhase + i * math.pi / 3;
      final arcRadius = 15 + math.sin(_animationPhase * 3 + i) * 5;
      
      final startX = _enginePosition.x + math.cos(arcAngle) * arcRadius;
      final startY = _enginePosition.y + math.sin(arcAngle) * arcRadius;
      final endX = _enginePosition.x + math.cos(arcAngle + 0.5) * arcRadius;
      final endY = _enginePosition.y + math.sin(arcAngle + 0.5) * arcRadius;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        arcPaint,
      );
    }
  }
  
  void _renderIceGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    
    // Crystalline formations
    final crystalPaint = Paint()
      ..color = _primaryColor.withValues(alpha: 0.6 * intensity)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi + _animationPhase * 0.5;
      final distance = 12 + math.sin(_animationPhase * 2 + i) * 3;
      
      final crystalX = _enginePosition.x + math.cos(angle) * distance;
      final crystalY = _enginePosition.y + math.sin(angle) * distance;
      
      final crystalPath = Path();
      crystalPath.moveTo(crystalX, crystalY - 5);
      crystalPath.lineTo(crystalX + 3, crystalY + 2);
      crystalPath.lineTo(crystalX - 3, crystalY + 2);
      crystalPath.close();
      
      canvas.drawPath(crystalPath, crystalPaint);
    }
  }
  
  void _renderCosmicGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    
    // Stellar effect with multiple colors
    for (int i = 0; i < _gradientColors.length; i++) {
      final layerRadius = (25 - (i * 5)).toDouble();
      final layerAlpha = (0.8 - i * 0.2) * intensity;
      
      final layerPaint = Paint()
        ..color = _gradientColors[i].withValues(alpha: layerAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(
        Offset(_enginePosition.x, _enginePosition.y),
        layerRadius,
        layerPaint,
      );
    }
    
    // Cosmic sparkles
    for (int i = 0; i < 8; i++) {
      final sparkleAngle = (i / 8) * 2 * math.pi + _animationPhase;
      final sparkleDistance = 30 + math.sin(_animationPhase * 3 + i) * 8;
      
      final sparkleX = _enginePosition.x + math.cos(sparkleAngle) * sparkleDistance;
      final sparkleY = _enginePosition.y + math.sin(sparkleAngle) * sparkleDistance;
      
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * intensity)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      // Draw sparkle cross
      canvas.drawLine(
        Offset(sparkleX - 3, sparkleY),
        Offset(sparkleX + 3, sparkleY),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - 3),
        Offset(sparkleX, sparkleY + 3),
        sparklePaint,
      );
    }
  }
  
  void _renderVoidGlow(Canvas canvas) {
    final intensity = _getIntensityMultiplier();
    
    // Dark energy tendrils
    final voidPaint = Paint()
      ..color = _primaryColor.withValues(alpha: 0.7 * intensity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 4; i++) {
      final tendrilAngle = _animationPhase * 2 + i * math.pi / 2;
      final tendrilLength = 20 + math.sin(_animationPhase * 3 + i) * 10;
      
      final path = Path();
      path.moveTo(_enginePosition.x, _enginePosition.y);
      
      for (double t = 0; t <= 1; t += 0.1) {
        final x = _enginePosition.x + math.cos(tendrilAngle) * tendrilLength * t;
        final y = _enginePosition.y + math.sin(tendrilAngle) * tendrilLength * t +
                 math.sin(_animationPhase * 4 + t * 10) * 5;
        
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, voidPaint);
    }
  }
  
  void _updateParticleSpawning(double dt) {
    _particleSpawnTimer += dt;
    
    final spawnRate = _currentIntensity == GlowIntensity.burst ? 0.02 :
                     _currentIntensity == GlowIntensity.boosting ? 0.05 : 0.1;
    
    if (_particleSpawnTimer >= spawnRate && _particles.length < 30) {
      _spawnParticle();
      _particleSpawnTimer = 0.0;
    }
  }
  
  void _spawnParticle() {
    final angle = _random.nextDouble() * 2 * math.pi;
    final speed = 20 + _random.nextDouble() * 40;
    final size = 2 + _random.nextDouble() * 4;
    
    final particle = GlowParticle(
      position: _enginePosition.clone(),
      velocity: Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      ),
      color: _gradientColors[_random.nextInt(_gradientColors.length)],
      size: size,
      maxLifetime: 0.5 + _random.nextDouble() * 0.5,
    );
    
    _particles.add(particle);
  }
  
  double _getIntensityMultiplier() {
    switch (_currentIntensity) {
      case GlowIntensity.idle:
        return 0.3 + math.sin(_animationPhase) * 0.1;
      case GlowIntensity.boosting:
        return 0.7 + math.sin(_animationPhase * 2) * 0.2;
      case GlowIntensity.burst:
        return 1.0 + math.sin(_animationPhase * 4) * 0.3;
    }
  }
  
  void _updateColors() {
    switch (_glowStyle) {
      case GlowStyle.classic:
        _primaryColor = Colors.cyan;
        _secondaryColor = Colors.white;
        _gradientColors = [Colors.cyan, Colors.blue, Colors.white];
        break;
      case GlowStyle.fire:
        _primaryColor = Colors.orange;
        _secondaryColor = Colors.yellow;
        _gradientColors = [Colors.red, Colors.orange, Colors.yellow];
        break;
      case GlowStyle.plasma:
        _primaryColor = Colors.purple;
        _secondaryColor = Colors.pink;
        _gradientColors = [Colors.purple, Colors.pink, Colors.white];
        break;
      case GlowStyle.ice:
        _primaryColor = Colors.lightBlue;
        _secondaryColor = Colors.white;
        _gradientColors = [Colors.blue, Colors.lightBlue, Colors.white];
        break;
      case GlowStyle.cosmic:
        _primaryColor = Colors.purple;
        _secondaryColor = Colors.white;
        _gradientColors = [
          Colors.red, Colors.orange, Colors.yellow,
          Colors.green, Colors.blue, Colors.purple,
        ];
        break;
      case GlowStyle.void_:
        _primaryColor = const Color(0xFF4B0082);
        _secondaryColor = const Color(0xFF8B008B);
        _gradientColors = [
          const Color(0xFF2F0F2F),
          const Color(0xFF4B0082),
          const Color(0xFF8B008B),
        ];
        break;
    }
  }
  
  /// Update engine position (called by jet player)
  void updateEnginePosition(Vector2 position) {
    _enginePosition = position;
  }
  
  /// Set glow intensity level
  void setIntensity(GlowIntensity intensity) {
    _currentIntensity = intensity;
  }
  
  /// Trigger burst effect
  void triggerBurst() {
    _currentIntensity = GlowIntensity.burst;
    _isBursting = true;
    _burstTime = 0.0;
    
    // Spawn extra particles for dramatic effect
    for (int i = 0; i < 5; i++) {
      _spawnParticle();
    }
  }
  
  /// Set glow style
  void setGlowStyle(GlowStyle style) {
    _glowStyle = style;
    _updateColors();
  }
  
  /// Set glow intensity multiplier
  void setGlowIntensity(double intensity) {
    _glowIntensity = intensity.clamp(0.0, 2.0);
  }
  
  /// Clear all particles
  void clearParticles() {
    _particles.clear();
  }
  
  /// Get glow info for store display
  static Map<String, dynamic> getGlowStyleInfo(GlowStyle style) {
    switch (style) {
      case GlowStyle.classic:
        return {
          'name': 'Classic Glow',
          'description': 'Traditional engine glow',
          'price': 0,
          'rarity': 'Common',
          'primaryColor': Colors.cyan,
        };
      case GlowStyle.fire:
        return {
          'name': 'Fire Trail',
          'description': 'Blazing flame effect',
          'price': 100,
          'rarity': 'Uncommon',
          'primaryColor': Colors.orange,
        };
      case GlowStyle.plasma:
        return {
          'name': 'Plasma Core',
          'description': 'High-energy plasma effect',
          'price': 200,
          'rarity': 'Rare',
          'primaryColor': Colors.purple,
        };
      case GlowStyle.ice:
        return {
          'name': 'Frost Crystal',
          'description': 'Crystalline ice effect',
          'price': 250,
          'rarity': 'Rare',
          'primaryColor': Colors.lightBlue,
        };
      case GlowStyle.cosmic:
        return {
          'name': 'Cosmic Energy',
          'description': 'Rainbow stellar effect',
          'price': 400,
          'rarity': 'Epic',
          'primaryColor': Colors.purple,
        };
      case GlowStyle.void_:
        return {
          'name': 'Void Energy',
          'description': 'Dark dimensional power',
          'price': 600,
          'rarity': 'Legendary',
          'primaryColor': Color(0xFF4B0082),
        };
    }
  }
}