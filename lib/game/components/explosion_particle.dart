/// 💥 Explosion Particle Component - Visual explosion effects
library;

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Explosion particle for collision effects
class ExplosionParticle extends PositionComponent {
  final Color color;
  final double maxSize;
  final double duration;
  late final math.Random _random;

  ExplosionParticle({
    required Vector2 position,
    required this.color,
    this.maxSize = 20.0,
    this.duration = 0.5,
  }) : _random = math.Random() {
    this.position = position;
    size = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    // Scale up effect
    add(ScaleEffect.to(
      Vector2.all(maxSize),
      EffectController(duration: duration * 0.3),
    ));

    // Scale down effect
    add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(
        duration: duration * 0.7,
        startDelay: duration * 0.3,
      ),
      onComplete: () => removeFromParent(),
    ));

    // Fade out effect
    add(OpacityEffect.to(
      0.0,
      EffectController(duration: duration),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Draw explosion burst
    final center = size / 2;
    final radius = size.x / 2;

    // Draw multiple circles for explosion effect
    for (int i = 0; i < 5; i++) {
      final offset = Vector2(
        (_random.nextDouble() - 0.5) * radius * 0.5,
        (_random.nextDouble() - 0.5) * radius * 0.5,
      );
      
      canvas.drawCircle(
        Offset(center.x + offset.x, center.y + offset.y),
        radius * (0.3 + i * 0.15),
        paint..color = color.withValues(alpha: 0.8 - i * 0.15),
      );
    }
  }
}
