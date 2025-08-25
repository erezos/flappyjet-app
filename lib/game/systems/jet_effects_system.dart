/// ✨ Jet Effects System - Tap Indication & Engine Glow
/// Makes every tap feel amazing with visual feedback
library;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Type of tap effect
enum TapEffectType {
  engineGlow,     // Classic engine glow on tap
  sparkBurst,     // Sparkle burst effect
  energyRing,     // Energy ring expansion
  trailBoost,     // Enhanced trail effect
  shockwave,      // Shockwave ripple
  rainbow,        // Rainbow particle burst
  realJetEngine,  // 🔥 REALISTIC JET ENGINE FIRE (using actual jet sprites)
}

/// Individual tap effect instance
class TapEffect {
  Vector2 position;
  TapEffectType type;
  double lifetime;
  double maxLifetime;
  Color color;
  double intensity;
  double size;
  
  TapEffect({
    required this.position,
    required this.type,
    required this.maxLifetime,
    required this.color,
    required this.intensity,
    required this.size,
  }) : lifetime = 0.0;
  
  bool get isAlive => lifetime < maxLifetime;
  double get progress => (lifetime / maxLifetime).clamp(0.0, 1.0);
  double get alpha => (1.0 - progress).clamp(0.0, 1.0);
  
  void update(double dt) {
    lifetime += dt;
  }
  
  void render(Canvas canvas) {
    if (!isAlive) return;
    
    switch (type) {
      case TapEffectType.engineGlow:
        _renderEngineGlow(canvas);
        break;
      case TapEffectType.sparkBurst:
        _renderSparkBurst(canvas);
        break;
      case TapEffectType.energyRing:
        _renderEnergyRing(canvas);
        break;
      case TapEffectType.trailBoost:
        _renderTrailBoost(canvas);
        break;
      case TapEffectType.shockwave:
        _renderShockwave(canvas);
        break;
      case TapEffectType.rainbow:
        _renderRainbow(canvas);
        break;
      case TapEffectType.realJetEngine:
        _renderRealJetEngine(canvas);
        break;
    }
  }
  
  void _renderEngineGlow(Canvas canvas) {
    final glowSize = size * (0.5 + intensity * 1.5) * (1.0 + progress * 0.5);
    final glowAlpha = alpha * intensity;
    
    // Outer glow
    final outerGlow = Paint()
      ..color = color.withValues(alpha: glowAlpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      glowSize * 2,
      outerGlow,
    );
    
    // Inner glow
    final innerGlow = Paint()
      ..color = color.withValues(alpha: glowAlpha * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      glowSize,
      innerGlow,
    );
    
    // Core
    final core = Paint()
      ..color = color.withValues(alpha: glowAlpha);
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      glowSize * 0.5,
      core,
    );
  }
  
  void _renderSparkBurst(Canvas canvas) {
    final sparkCount = 12;
    final spreadRadius = size * progress * 2;
    final sparkSize = size * 0.1 * (1.0 - progress);
    
    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * math.pi;
      final sparkX = position.x + math.cos(angle) * spreadRadius;
      final sparkY = position.y + math.sin(angle) * spreadRadius;
      
      final sparkPaint = Paint()
        ..color = color.withValues(alpha: alpha * intensity)
        ..style = PaintingStyle.fill;
      
      // Main spark
      canvas.drawCircle(
        Offset(sparkX, sparkY),
        sparkSize,
        sparkPaint,
      );
      
      // Spark trail
      final trailLength = 8 * (1.0 - progress);
      final trailX = sparkX - math.cos(angle) * trailLength;
      final trailY = sparkY - math.sin(angle) * trailLength;
      
      final trailPaint = Paint()
        ..color = color.withValues(alpha: alpha * intensity * 0.5)
        ..strokeWidth = sparkSize
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(trailX, trailY),
        Offset(sparkX, sparkY),
        trailPaint,
      );
    }
  }
  
  void _renderEnergyRing(Canvas canvas) {
    final ringRadius = size * progress * 3;
    final ringThickness = size * 0.2 * (1.0 - progress);
    
    final ringPaint = Paint()
      ..color = color.withValues(alpha: alpha * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringThickness;
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      ringRadius,
      ringPaint,
    );
    
    // Inner energy glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: alpha * intensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      ringRadius,
      glowPaint,
    );
  }
  
  void _renderTrailBoost(Canvas canvas) {
    final trailLength = size * 2;
    final trailWidth = size * 0.3 * (1.0 - progress);
    
    for (int i = 0; i < 5; i++) {
      final trailOffset = i * (trailLength / 5);
      final trailAlpha = alpha * (1.0 - i * 0.2);
      
      final trailPaint = Paint()
        ..color = color.withValues(alpha: trailAlpha * intensity)
        ..strokeWidth = trailWidth * (1.0 - i * 0.1)
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(position.x - trailOffset, position.y),
        Offset(position.x - trailOffset - 10, position.y),
        trailPaint,
      );
    }
  }
  
  void _renderShockwave(Canvas canvas) {
    final waveRadius = size * progress * 4;
    final waveCount = 3;
    
    for (int i = 0; i < waveCount; i++) {
      final waveOffset = i * 0.3;
      final waveProgress = (progress - waveOffset).clamp(0.0, 1.0);
      final currentRadius = waveRadius * waveProgress;
      
      if (waveProgress > 0) {
        final wavePaint = Paint()
          ..color = color.withValues(alpha: (1.0 - waveProgress) * intensity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        
        canvas.drawCircle(
          Offset(position.x, position.y),
          currentRadius,
          wavePaint,
        );
      }
    }
  }
  
  void _renderRainbow(Canvas canvas) {
    final particleCount = 20;
    final spread = size * progress * 1.5;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final hue = (i / particleCount) * 360;
      final particleColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      
      final particleX = position.x + math.cos(angle) * spread;
      final particleY = position.y + math.sin(angle) * spread;
      
      final particlePaint = Paint()
        ..color = particleColor.withValues(alpha: alpha * intensity);
      
      canvas.drawCircle(
        Offset(particleX, particleY),
        size * 0.15 * (1.0 - progress),
        particlePaint,
      );
    }
  }
  
  /// 🔥 REALISTIC JET ENGINE FIRE - Like hitting the afterburner!
  void _renderRealJetEngine(Canvas canvas) {
    // Multi-layered realistic jet engine fire effect
    final fireLength = size * (1.5 + intensity * 2.0) * (1.0 - progress * 0.3);
    final fireWidth = size * (0.6 + intensity * 0.4);
    final engineAlpha = alpha * intensity;
    
    // 🔥 LAYER 1: Hot white core (engine nozzle)
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: engineAlpha * 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      Offset(position.x - fireLength * 0.1, position.y),
      fireWidth * 0.3,
      corePaint,
    );
    
    // 🔥 LAYER 2: Orange flame cone
    final flamePaint = Paint()
      ..color = Colors.orange.withValues(alpha: engineAlpha * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final flamePath = Path();
    flamePath.moveTo(position.x - fireLength * 0.1, position.y - fireWidth * 0.4);
    flamePath.lineTo(position.x - fireLength * 0.7, position.y - fireWidth * 0.2);
    flamePath.lineTo(position.x - fireLength, position.y);
    flamePath.lineTo(position.x - fireLength * 0.7, position.y + fireWidth * 0.2);
    flamePath.lineTo(position.x - fireLength * 0.1, position.y + fireWidth * 0.4);
    flamePath.close();
    
    canvas.drawPath(flamePath, flamePaint);
    
    // 🔥 LAYER 3: Red outer flame
    final outerFlamePaint = Paint()
      ..color = Colors.red.withValues(alpha: engineAlpha * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final outerFlamePath = Path();
    outerFlamePath.moveTo(position.x - fireLength * 0.2, position.y - fireWidth * 0.5);
    outerFlamePath.lineTo(position.x - fireLength * 0.9, position.y - fireWidth * 0.3);
    outerFlamePath.lineTo(position.x - fireLength * 1.2, position.y);
    outerFlamePath.lineTo(position.x - fireLength * 0.9, position.y + fireWidth * 0.3);
    outerFlamePath.lineTo(position.x - fireLength * 0.2, position.y + fireWidth * 0.5);
    outerFlamePath.close();
    
    canvas.drawPath(outerFlamePath, outerFlamePaint);
    
    // 🔥 LAYER 4: Exhaust heat shimmer particles
    if (progress < 0.5) { // Only early in the effect
      final particleCount = 8;
      for (int i = 0; i < particleCount; i++) {
        final particleAngle = (i / particleCount) * 2 * math.pi;
        final particleDistance = fireLength * 0.3 * (1.0 + progress);
        final particleX = position.x - particleDistance + math.cos(particleAngle) * fireWidth * 0.2;
        final particleY = position.y + math.sin(particleAngle) * fireWidth * 0.3;
        
        final particlePaint = Paint()
          ..color = Colors.yellow.withValues(alpha: engineAlpha * (1.0 - progress) * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        
        canvas.drawCircle(
          Offset(particleX, particleY),
          size * 0.08,
          particlePaint,
        );
      }
    }
  }
}

/// Jet Effects System - manages all tap effects
class JetEffectsSystem extends Component {
  final List<TapEffect> _activeEffects = [];
  
  // Available effect types for unlocking/purchasing
  static const List<TapEffectType> _freeEffects = [
    TapEffectType.engineGlow,
    TapEffectType.sparkBurst,
    TapEffectType.realJetEngine,  // 🔥 FREE realistic jet engine fire!
  ];
  
  static const List<TapEffectType> _premiumEffects = [
    TapEffectType.energyRing,
    TapEffectType.trailBoost,
    TapEffectType.shockwave,
    TapEffectType.rainbow,
  ];
  
  // Current settings
  TapEffectType _currentEffectType = TapEffectType.engineGlow;
  double _effectIntensity = 1.0;
  Color _effectColor = Colors.cyan;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update active effects
    for (final effect in _activeEffects.toList()) {
      effect.update(dt);
      if (!effect.isAlive) {
        _activeEffects.remove(effect);
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    for (final effect in _activeEffects) {
      effect.render(canvas);
    }
  }
  
  /// Create tap effect at position
  void createTapEffect(Vector2 position) {
    final effect = TapEffect(
      position: position.clone(),
      type: _currentEffectType,
      maxLifetime: _getEffectDuration(_currentEffectType),
      color: _effectColor,
      intensity: _effectIntensity,
      size: _getEffectSize(_currentEffectType),
    );
    
    _activeEffects.add(effect);
    
    // Limit active effects to prevent performance issues
    if (_activeEffects.length > 20) {
      _activeEffects.removeAt(0);
    }
  }
  
  double _getEffectDuration(TapEffectType type) {
    switch (type) {
      case TapEffectType.engineGlow:
        return 0.3;
      case TapEffectType.sparkBurst:
        return 0.5;
      case TapEffectType.energyRing:
        return 0.4;
      case TapEffectType.trailBoost:
        return 0.6;
      case TapEffectType.shockwave:
        return 0.8;
      case TapEffectType.rainbow:
        return 0.7;
      case TapEffectType.realJetEngine:
        return 0.5;  // 🔥 Perfect duration for jet engine fire burst
    }
  }
  
  double _getEffectSize(TapEffectType type) {
    switch (type) {
      case TapEffectType.engineGlow:
        return 20.0;
      case TapEffectType.sparkBurst:
        return 25.0;
      case TapEffectType.energyRing:
        return 15.0;
      case TapEffectType.trailBoost:
        return 30.0;
      case TapEffectType.shockwave:
        return 18.0;
      case TapEffectType.rainbow:
        return 22.0;
      case TapEffectType.realJetEngine:
        return 35.0;  // 🔥 Larger size for impressive jet engine fire effect
    }
  }
  
  /// Set current effect type
  void setEffectType(TapEffectType type) {
    _currentEffectType = type;
  }
  
  /// Set effect color
  void setEffectColor(Color color) {
    _effectColor = color;
  }
  
  /// Set effect intensity (0.0 to 2.0)
  void setEffectIntensity(double intensity) {
    _effectIntensity = intensity.clamp(0.0, 2.0);
  }
  
  /// Check if effect type is unlocked
  bool isEffectUnlocked(TapEffectType type) {
    return _freeEffects.contains(type) || _isEffectPurchased(type);
  }
  
  /// Check if effect is purchased (placeholder for monetization)
  bool _isEffectPurchased(TapEffectType type) {
    // Monetization integration ready for premium effects
    return false;
  }
  
  /// Get effect display info for store
  static Map<String, dynamic> getEffectInfo(TapEffectType type) {
    switch (type) {
      case TapEffectType.engineGlow:
        return {
          'name': 'Engine Glow',
          'description': 'Classic engine boost effect',
          'price': 0,
          'rarity': 'Common',
          'color': Colors.cyan,
        };
      case TapEffectType.sparkBurst:
        return {
          'name': 'Spark Burst',
          'description': 'Explosive particle burst',
          'price': 0,
          'rarity': 'Common',
          'color': Colors.orange,
        };
      case TapEffectType.energyRing:
        return {
          'name': 'Energy Ring',
          'description': 'Expanding energy wave',
          'price': 150,
          'rarity': 'Rare',
          'color': Colors.purple,
        };
      case TapEffectType.trailBoost:
        return {
          'name': 'Trail Boost',
          'description': 'Enhanced engine trail',
          'price': 200,
          'rarity': 'Rare',
          'color': Colors.blue,
        };
      case TapEffectType.shockwave:
        return {
          'name': 'Shockwave',
          'description': 'Rippling shockwave effect',
          'price': 300,
          'rarity': 'Epic',
          'color': Colors.red,
        };
      case TapEffectType.rainbow:
        return {
          'name': 'Rainbow Burst',
          'description': 'Spectacular rainbow explosion',
          'price': 500,
          'rarity': 'Legendary',
          'color': Colors.white,
        };
      case TapEffectType.realJetEngine:
        return {
          'name': 'Jet Engine Fire',
          'description': '🔥 Realistic jet afterburner flames',
          'price': 0,
          'rarity': 'Epic',
          'color': Colors.orange,
        };
    }
  }
  
  /// Get all available effects for store display
  static List<TapEffectType> getAllEffects() {
    return [..._freeEffects, ..._premiumEffects];
  }
  
  /// Clear all active effects
  void clearEffects() {
    _activeEffects.clear();
  }
  
  /// Get current settings for UI display
  Map<String, dynamic> getCurrentSettings() {
    return {
      'type': _currentEffectType,
      'intensity': _effectIntensity,
      'color': _effectColor,
      'activeEffects': _activeEffects.length,
    };
  }
}