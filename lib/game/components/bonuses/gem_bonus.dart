import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/debug_logger.dart';
import '../../../models/bonus_config.dart';
import '../collectible_bonus.dart';

/// 💎 Gem Bonus - Grants premium currency (gems)
/// 
/// Features:
/// - Configurable amount (1-3 typical, rare)
/// - Purple/magenta glow with sparkles
/// - Premium trail animation to HUD on collection
class GemBonus extends CollectibleBonus with RewardTrailAnimation {
  /// Amount of gems to award
  final int amount;
  
  /// Sparkle animation time
  double _sparkleTime = 0.0;
  
  GemBonus({
    required super.position,
    required super.speed,
    required this.amount,
  }) : super(
    bonusSize: 48.0,
    glowColor: const Color(0xFF9C27B0), // Purple
  );
  
  @override
  BonusType get bonusType => BonusType.gems;
  
  @override
  Future<void> loadBonusSprite() async {
    try {
      sprite = await game.loadSprite('bonuses/gem_bonus.png');
      safePrint('💎 Loaded gem sprite');
    } catch (e) {
      safePrint('💎 Gem sprite not found, using fallback');
      // Fallback: procedural gem will be drawn in render
    }
  }
  
  @override
  Future<Map<String, dynamic>> onCollected() async {
    return {
      'type': 'gems',
      'amount': amount,
    };
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update sparkle animation
    _sparkleTime += dt * 2.0;
  }
  
  @override
  void render(Canvas canvas) {
    // If sprite loaded, use it
    if (sprite != null) {
      _renderGlow(canvas);
      super.render(canvas);
      _renderSparkles(canvas);
      return;
    }
    
    // Fallback: Draw procedural gem
    _drawProceduralGem(canvas);
  }
  
  void _renderGlow(Canvas canvas) {
    final center = size / 2;
    final centerOffset = Offset(center.x, center.y);
    
    // Double glow for premium feel
    final outerGlow = Paint()
      ..color = glowColor.withValues(alpha: 51 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, bonusSize * 0.4);
    canvas.drawCircle(centerOffset, bonusSize * 0.5, outerGlow);
    
    final innerGlow = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 77 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, bonusSize * 0.2);
    canvas.drawCircle(centerOffset, bonusSize * 0.35, innerGlow);
  }
  
  /// Render sparkle effects around the gem
  void _renderSparkles(Canvas canvas) {
    final center = size / 2;
    
    final sparklePaint = Paint()
      ..color = Colors.white;
    
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2 + _sparkleTime;
      final distance = bonusSize * 0.4 + math.sin(_sparkleTime * 3 + i) * 5;
      final sparkleSize = 2.0 + math.sin(_sparkleTime * 4 + i) * 1.0;
      final opacity = (math.sin(_sparkleTime * 3 + i * 0.5) + 1) / 2 * 0.8;
      
      final x = center.x + math.cos(angle) * distance;
      final y = center.y + math.sin(angle) * distance;
      
      sparklePaint.color = Colors.white.withValues(alpha: opacity); // Fixed: removed *255, withValues expects 0.0-1.0
      
      // Draw cross-shaped sparkle
      canvas.drawLine(
        Offset(x - sparkleSize, y),
        Offset(x + sparkleSize, y),
        sparklePaint..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(x, y - sparkleSize),
        Offset(x, y + sparkleSize),
        sparklePaint,
      );
    }
  }
  
  /// Draw a procedural gem when sprite is not available
  void _drawProceduralGem(Canvas canvas) {
    final center = size / 2;
    final centerOffset = Offset(center.x, center.y);
    final gemSize = bonusSize * 0.4;
    
    // Glow effect
    _renderGlow(canvas);
    
    // Gem body (hexagonal shape)
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 - math.pi / 2;
      points.add(Offset(
        center.x + math.cos(angle) * gemSize,
        center.y + math.sin(angle) * gemSize,
      ));
    }
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    // Gradient fill
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE040FB), // Bright magenta
          const Color(0xFF9C27B0), // Purple
          const Color(0xFF6A1B9A), // Dark purple
        ],
      ).createShader(Rect.fromCenter(
        center: centerOffset,
        width: gemSize * 2,
        height: gemSize * 2,
      ));
    canvas.drawPath(path, bodyPaint);
    
    // Facet highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 102 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw internal facet lines
    canvas.drawLine(centerOffset, points[0], highlightPaint);
    canvas.drawLine(centerOffset, points[2], highlightPaint);
    canvas.drawLine(centerOffset, points[4], highlightPaint);
    
    // Top highlight
    final topHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 128 / 255.0); // Fixed: convert 0-255 to 0.0-1.0
    final topPath = Path()
      ..moveTo(center.x, center.y - gemSize * 0.3)
      ..lineTo(center.x - gemSize * 0.3, center.y)
      ..lineTo(center.x, center.y + gemSize * 0.2)
      ..close();
    canvas.drawPath(topPath, topHighlight);
    
    // Sparkles
    _renderSparkles(canvas);
  }
}

