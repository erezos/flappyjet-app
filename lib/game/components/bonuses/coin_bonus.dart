import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/debug_logger.dart';
import '../../../models/bonus_config.dart';
import '../collectible_bonus.dart';

/// 🪙 Coin Bonus - Grants soft currency (coins)
/// 
/// Features:
/// - Configurable amount (10-25 typical)
/// - Gold glow animation
/// - Trail animation to HUD on collection
class CoinBonus extends CollectibleBonus with RewardTrailAnimation {
  /// Amount of coins to award
  final int amount;
  
  /// Rotation angle for spinning effect
  double _rotation = 0.0;
  
  CoinBonus({
    required super.position,
    required super.speed,
    required this.amount,
  }) : super(
    bonusSize: 44.0,
    glowColor: const Color(0xFFFFD700), // Gold
  );
  
  @override
  BonusType get bonusType => BonusType.coins;
  
  @override
  Future<void> loadBonusSprite() async {
    try {
      sprite = await game.loadSprite('bonuses/coin_bonus.png');
      safePrint('🪙 Loaded coin sprite');
    } catch (e) {
      safePrint('🪙 Coin sprite not found, using fallback');
      // Fallback: procedural coin will be drawn in render
    }
  }
  
  @override
  Future<Map<String, dynamic>> onCollected() async {
    return {
      'type': 'coins',
      'amount': amount,
    };
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Rotate the coin
    _rotation += dt * 3.0; // 3 rotations per second
    if (_rotation > math.pi * 2) {
      _rotation -= math.pi * 2;
    }
  }
  
  @override
  void render(Canvas canvas) {
    // If sprite loaded, use it with rotation effect (squash for 3D spin)
    if (sprite != null) {
      canvas.save();
      final center = size / 2;
      canvas.translate(center.x, center.y);
      
      // Create 3D spin effect by scaling X based on rotation
      final scaleX = math.cos(_rotation).abs().clamp(0.2, 1.0);
      canvas.scale(scaleX, 1.0);
      canvas.translate(-center.x, -center.y);
      
      // Render glow first
      _renderGlow(canvas);
      
      super.render(canvas);
      canvas.restore();
      return;
    }
    
    // Fallback: Draw procedural coin
    _drawProceduralCoin(canvas);
  }
  
  void _renderGlow(Canvas canvas) {
    final center = size / 2;
    final centerOffset = Offset(center.x, center.y);
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, bonusSize * 0.25);
    canvas.drawCircle(centerOffset, bonusSize * 0.4, glowPaint);
  }
  
  /// Draw a procedural coin when sprite is not available
  void _drawProceduralCoin(Canvas canvas) {
    canvas.save();
    final center = size / 2;
    canvas.translate(center.x, center.y);
    
    // Create 3D spin effect
    final scaleX = math.cos(_rotation).abs().clamp(0.2, 1.0);
    canvas.scale(scaleX, 1.0);
    
    final radius = bonusSize * 0.4;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(Offset.zero, radius * 1.2, glowPaint);
    
    // Coin body (gold gradient)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE566), // Light gold
          const Color(0xFFFFD700), // Gold
          const Color(0xFFB8860B), // Dark gold
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, bodyPaint);
    
    // Edge highlight
    final edgePaint = Paint()
      ..color = const Color(0xFFFFE566).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, radius * 0.85, edgePaint);
    
    // Inner detail ($ symbol or simple design)
    final detailPaint = Paint()
      ..color = const Color(0xFFB8860B).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.3, detailPaint);
    
    canvas.restore();
  }
}

