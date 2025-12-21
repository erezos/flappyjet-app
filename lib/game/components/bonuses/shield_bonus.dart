import 'package:flutter/material.dart';
import '../../../core/debug_logger.dart';
import '../../../models/bonus_config.dart';
import '../collectible_bonus.dart';

/// 🛡️ Shield Bonus - Grants temporary invulnerability
/// 
/// Three tiers with different durations:
/// - Bronze: 3 seconds (most common)
/// - Silver: 4 seconds (medium rarity)
/// - Gold: 5 seconds (rare)
class ShieldBonus extends CollectibleBonus {
  /// Shield tier determines duration and appearance
  final ShieldTier tier;
  
  /// Shield duration in seconds
  double get shieldDuration => tier.duration;
  
  ShieldBonus({
    required super.position,
    required super.speed,
    this.tier = ShieldTier.blue,
  }) : super(
    bonusSize: 56.0,
    glowColor: _getTierColor(tier),
  );
  
  @override
  BonusType get bonusType => BonusType.shield;
  
  /// Get color based on shield tier
  static Color _getTierColor(ShieldTier tier) {
    switch (tier) {
      case ShieldTier.blue:
        return const Color(0xFF2196F3); // Blue
      case ShieldTier.red:
        return const Color(0xFFF44336); // Red
      case ShieldTier.green:
        return const Color(0xFF4CAF50); // Green
    }
  }
  
  @override
  Future<void> loadBonusSprite() async {
    try {
      // Try to load tier-specific sprite
      sprite = await game.loadSprite('bonuses/${tier.assetName}');
      safePrint('🛡️ Loaded shield sprite: ${tier.assetName}');
    } catch (e) {
      safePrint('🛡️ Shield sprite not found, using fallback');
      // Fallback: create a procedural sprite will be handled in render
    }
  }
  
  @override
  Future<Map<String, dynamic>> onCollected() async {
    return {
      'type': 'shield',
      'tier': tier.name,
      'duration': shieldDuration,
    };
  }
  
  @override
  void render(Canvas canvas) {
    // If sprite loaded, use it with glow
    if (sprite != null) {
      _renderGlow(canvas);
      super.render(canvas);
      return;
    }
    
    // Fallback: Draw procedural shield
    _drawProceduralShield(canvas);
  }
  
  /// Render glow effect for the shield
  void _renderGlow(Canvas canvas) {
    final center = size / 2;
    final centerOffset = Offset(center.x, center.y);
    final radius = bonusSize * 0.4;
    
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 77 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(centerOffset, radius * 1.3, glowPaint);
  }
  
  /// Draw a procedural shield when sprite is not available
  void _drawProceduralShield(Canvas canvas) {
    final center = size / 2;
    final centerOffset = Offset(center.x, center.y);
    final radius = bonusSize * 0.4;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 77 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(centerOffset, radius * 1.3, glowPaint);
    
    // Main shield body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 230 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
          glowColor.withValues(alpha: 153 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
          glowColor.withValues(alpha: 77 / 255.0), // Fixed: convert 0-255 to 0.0-1.0
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));
    canvas.drawCircle(centerOffset, radius, bodyPaint);
    
    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 153 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(centerOffset, radius * 0.7, highlightPaint);
    
    // Shield icon (simple energy waves)
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 102 / 255.0) // Fixed: convert 0-255 to 0.0-1.0
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < 3; i++) {
      final waveRadius = radius * (0.3 + i * 0.2);
      canvas.drawCircle(centerOffset, waveRadius, wavePaint);
    }
  }
}

