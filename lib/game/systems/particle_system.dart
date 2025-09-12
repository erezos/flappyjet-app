/// 🎆 Production Particle System - High-performance visual effects
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/game_themes.dart';

/// Particle shapes for different visual effects
enum ParticleShape { circle, star, confetti, spark }

/// High-performance particle for visual effects
class GameParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  Color? colorSecondary;
  double size;
  double age;
  double lifetime;
  bool isAlive;
  ParticleShape shape;
  double rotation;
  double angularVelocity;
  double gravityY;
  double sizeGrowthPerSecond;

  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.colorSecondary,
    required this.size,
    required this.lifetime,
    this.shape = ParticleShape.circle,
    this.rotation = 0.0,
    this.angularVelocity = 0.0,
    this.gravityY = 800.0,
    this.sizeGrowthPerSecond = 0.0,
  }) : age = 0.0,
       isAlive = true;

  void update(double dt) {
    if (!isAlive) return;

    position += velocity * dt;
    velocity.y += gravityY * dt;
    if (sizeGrowthPerSecond != 0.0) {
      size += sizeGrowthPerSecond * dt;
      if (size < 0) size = 0;
    }
    age += dt;
    rotation += angularVelocity * dt;

    if (age >= lifetime) {
      isAlive = false;
    }
  }

  void render(Canvas canvas) {
    if (!isAlive || size <= 0) return;

    final paint = Paint()
      ..color = color.withValues(
        alpha: (1.0 - (age / lifetime)).clamp(0.0, 1.0),
      );

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
      case ParticleShape.star:
        _drawStar(canvas, paint, size);
        break;
      case ParticleShape.confetti:
        _drawConfetti(canvas, paint, size);
        break;
      case ParticleShape.spark:
        _drawSpark(canvas, paint, size);
        break;
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final radius = size / 2;
    final innerRadius = radius * 0.5;

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final r = i.isEven ? radius : innerRadius;
      final x = r * math.cos(angle - math.pi / 2);
      final y = r * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawConfetti(Canvas canvas, Paint paint, double size) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size,
      height: size * 0.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size * 0.1)),
      paint,
    );
  }

  void _drawSpark(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(-size / 2, 0);
    path.lineTo(size / 2, 0);
    path.moveTo(0, -size / 2);
    path.lineTo(0, size / 2);

    paint.strokeWidth = 2.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }
}

/// Production particle system for visual effects
class ParticleSystem {
  final List<GameParticle> _particles = [];
  final math.Random _random = math.Random();

  static const int _maxParticles = 200; // Performance limit

  /// Create score burst effect
  void createScoreBurst(Vector2 position, GameTheme theme, int score) {
    final particleCount = math.min(10 + (score ~/ 5), 20);
    final baseColor = theme.colors.primary;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final speed = 100.0 + _random.nextDouble() * 150.0;
      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 50.0, // Slight upward bias
      );

      _addParticle(
        GameParticle(
          position: position.clone(),
          velocity: velocity,
          color: Color.lerp(
            baseColor,
            Colors.white,
            _random.nextDouble() * 0.3,
          )!,
          size: 4.0 + _random.nextDouble() * 6.0,
          lifetime: 0.8 + _random.nextDouble() * 0.4,
          shape: ParticleShape.star,
          angularVelocity: (_random.nextDouble() - 0.5) * 10.0,
          gravityY: 300.0,
        ),
      );
    }
  }

  /// Create jet trail effect
  void createJetTrail(Vector2 position, Vector2 velocity, GameTheme theme) {
    if (_particles.length > _maxParticles - 5) return; // Performance guard

    for (int i = 0; i < 3; i++) {
      final offset = Vector2(
        (_random.nextDouble() - 0.5) * 10.0,
        (_random.nextDouble() - 0.5) * 10.0,
      );

      _addParticle(
        GameParticle(
          position: position + offset,
          velocity:
              velocity * -0.3 +
              Vector2(
                (_random.nextDouble() - 0.5) * 50.0,
                (_random.nextDouble() - 0.5) * 50.0,
              ),
          color: theme.colors.accent.withValues(alpha: 0.6),
          size: 2.0 + _random.nextDouble() * 3.0,
          lifetime: 0.3 + _random.nextDouble() * 0.2,
          shape: ParticleShape.circle,
          gravityY: 100.0,
          sizeGrowthPerSecond: -5.0,
        ),
      );
    }
  }

  /// Create theme transition effect
  void createThemeTransition(
    Vector2 position,
    GameTheme oldTheme,
    GameTheme newTheme,
  ) {
    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 50.0 + _random.nextDouble() * 100.0;
      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      final color = i < 15 ? oldTheme.colors.primary : newTheme.colors.primary;

      _addParticle(
        GameParticle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          size: 3.0 + _random.nextDouble() * 4.0,
          lifetime: 1.0 + _random.nextDouble() * 0.5,
          shape: ParticleShape.confetti,
          angularVelocity: (_random.nextDouble() - 0.5) * 8.0,
          gravityY: 200.0,
        ),
      );
    }
  }

  /// Create ambient sparkles
  void createAmbientSparkles(Vector2 size, GameTheme theme) {
    if (_particles.length > _maxParticles - 10) return;

    for (int i = 0; i < 5; i++) {
      final position = Vector2(
        _random.nextDouble() * size.x,
        _random.nextDouble() * size.y,
      );

      _addParticle(
        GameParticle(
          position: position,
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 20.0,
            -20.0 - _random.nextDouble() * 30.0,
          ),
          color: theme.colors.accent.withValues(alpha: 0.4),
          size: 1.0 + _random.nextDouble() * 2.0,
          lifetime: 2.0 + _random.nextDouble() * 1.0,
          shape: ParticleShape.spark,
          gravityY: 50.0,
        ),
      );
    }
  }

  /// Update all particles
  void update(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(dt);
      if (!_particles[i].isAlive) {
        _particles.removeAt(i);
      }
    }
  }

  /// Render all particles
  void render(Canvas canvas) {
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  /// Clear all particles
  void clearAll() {
    _particles.clear();
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'active_particles': _particles.length,
      'memory_mb': (_particles.length * 200) / 1024 / 1024, // Rough estimate
    };
  }

  void _addParticle(GameParticle particle) {
    if (_particles.length >= _maxParticles) {
      _particles.removeAt(0); // Remove oldest
    }
    _particles.add(particle);
  }
}
