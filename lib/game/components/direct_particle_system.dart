/// 🎨 DIRECT PARTICLE SYSTEM - Optimized particle effects for game
/// Extracted from EnhancedFlappyGame to improve maintainability and performance
library;

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Particle shape options for visual variety
enum ParticleShape { circle, star, confetti }

/// Individual particle with physics and rendering
class DirectParticle {
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

  DirectParticle({
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

  /// Update particle physics
  void update(double dt) {
    if (!isAlive) return;

    // Apply physics
    position += velocity * dt;
    velocity.y += gravityY * dt;

    // Size growth/shrinkage
    if (sizeGrowthPerSecond != 0.0) {
      size += sizeGrowthPerSecond * dt;
      if (size < 0) size = 0;
    }

    // Rotation
    rotation += angularVelocity * dt;

    // Age and lifetime
    age += dt;
    if (age >= lifetime) {
      isAlive = false;
    }
  }

  /// Render particle to canvas
  void render(Canvas canvas) {
    if (!isAlive) return;

    final alpha = (1 - age / lifetime).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color.fromRGBO((color.r * 255.0).round() & 0xff, (color.g * 255.0).round() & 0xff, (color.b * 255.0).round() & 0xff, alpha);

    final center = Offset(position.x, position.y);

    switch (shape) {
      case ParticleShape.circle:
        // Soft gradient circle
        final shader = ui.Gradient.radial(center, size / 2, [
          Color.fromRGBO((color.r * 255.0).round() & 0xff, (color.g * 255.0).round() & 0xff, (color.b * 255.0).round() & 0xff, alpha),
          colorSecondary != null
              ? Color.fromRGBO(
                  (colorSecondary!.r * 255.0).round() & 0xff,
                  (colorSecondary!.g * 255.0).round() & 0xff,
                  (colorSecondary!.b * 255.0).round() & 0xff,
                  alpha * 0.5,
                )
              : Colors.transparent,
        ]);
        canvas.drawCircle(center, size / 2, paint..shader = shader);

      case ParticleShape.star:
        // Simple star shape
        final path = Path();
        final outerRadius = size / 2;
        final innerRadius = size / 4;

        for (int i = 0; i < 10; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = (i * 36 - 90) * pi / 180;
          final point =
              center + Offset(cos(angle) * radius, sin(angle) * radius);

          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);

      case ParticleShape.confetti:
        // Rectangular confetti
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(rotation);

        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size,
          height: size * 0.3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size * 0.1)),
          paint,
        );

        canvas.restore();
    }
  }
}

/// 🎨 DIRECT PARTICLE SYSTEM - High-performance particle manager
class DirectParticleSystem {
  final List<DirectParticle> _particles = [];
  final Random _random = Random();

  /// Get current particle count
  int get particleCount => _particles.length;

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() => {
    'active_particles': _particles.length,
    'memory_mb': (_particles.length * 100) / 1024 / 1024, // Rough estimate
  };

  /// Create score burst effect
  void createScoreBurst(Vector2 position, String theme, int score) {
    final colors = _getThemeColors(theme);
    final particleCount = min(15 + (score ~/ 10), 30); // Scale with score

    for (int i = 0; i < particleCount; i++) {
      final angle = (_random.nextDouble() - 0.5) * pi; // -90 to 90 degrees
      final speed = 100 + _random.nextDouble() * 200;
      final lifetime = 1.0 + _random.nextDouble() * 2.0;

      _particles.add(
        DirectParticle(
          position: position.clone(),
          velocity: Vector2(
            cos(angle) * speed,
            sin(angle) * speed - 50,
          ), // Slight upward bias
          color: colors[_random.nextInt(colors.length)],
          size: 3 + _random.nextDouble() * 8,
          lifetime: lifetime,
          shape: _random.nextBool() ? ParticleShape.circle : ParticleShape.star,
          gravityY: 200,
          angularVelocity: (_random.nextDouble() - 0.5) * 10,
        ),
      );
    }
  }

  /// Create jet trail effect
  void createJetTrail(Vector2 position, Vector2 velocity, String theme) {
    final colors = _getThemeColors(theme);

    // Create trail particles
    for (int i = 0; i < 3; i++) {
      _particles.add(
        DirectParticle(
          position:
              position +
              Vector2(
                _random.nextDouble() * 10 - 5,
                _random.nextDouble() * 10 - 5,
              ),
          velocity:
              velocity * 0.3 +
              Vector2(
                (_random.nextDouble() - 0.5) * 50,
                (_random.nextDouble() - 0.5) * 50,
              ),
          color: Color.fromRGBO(
            (colors[_random.nextInt(colors.length)].r * 255.0).round() & 0xff,
            (colors[_random.nextInt(colors.length)].g * 255.0).round() & 0xff,
            (colors[_random.nextInt(colors.length)].b * 255.0).round() & 0xff,
            0.7,
          ),
          size: 2 + _random.nextDouble() * 4,
          lifetime: 0.5 + _random.nextDouble() * 0.5,
          shape: ParticleShape.circle,
          gravityY: 100,
        ),
      );
    }
  }

  /// Create theme transition effect
  void createThemeTransition(
    Vector2 position,
    String oldTheme,
    String newTheme,
  ) {
    final oldColors = _getThemeColors(oldTheme);
    final newColors = _getThemeColors(newTheme);

    // Transition particles
    for (int i = 0; i < 20; i++) {
      final progress = i / 19;
      final color = Color.lerp(oldColors[0], newColors[0], progress)!;

      _particles.add(
        DirectParticle(
          position: position.clone(),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 300,
            (_random.nextDouble() - 0.5) * 300,
          ),
          color: color,
          size: 4 + _random.nextDouble() * 6,
          lifetime: 2.0 + _random.nextDouble(),
          shape: ParticleShape.confetti,
          gravityY: 300,
          angularVelocity: (_random.nextDouble() - 0.5) * 15,
          sizeGrowthPerSecond: -5, // Shrink over time
        ),
      );
    }
  }

  /// Create ambient sparkle effects
  void createAmbientSparkles(double size, String theme) {
    final colors = _getThemeColors(theme);
    final sparkleCount = min(8 + (_random.nextInt(12)), 20);

    for (int i = 0; i < sparkleCount; i++) {
      final x = _random.nextDouble() * size;
      final y = _random.nextDouble() * size;

      _particles.add(
        DirectParticle(
          position: Vector2(x, y),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 20,
            (_random.nextDouble() - 0.5) * 20,
          ),
          color: Color.fromRGBO(
            (colors[_random.nextInt(colors.length)].r * 255.0).round() & 0xff,
            (colors[_random.nextInt(colors.length)].g * 255.0).round() & 0xff,
            (colors[_random.nextInt(colors.length)].b * 255.0).round() & 0xff,
            0.8,
          ),
          size: 1 + _random.nextDouble() * 3,
          lifetime: 3.0 + _random.nextDouble() * 4.0,
          shape: _random.nextBool() ? ParticleShape.star : ParticleShape.circle,
          gravityY: -10, // Slight upward drift
          angularVelocity: (_random.nextDouble() - 0.5) * 2,
        ),
      );
    }
  }

  /// Update all particles
  void update(double dt) {
    // Update existing particles
    for (final particle in _particles) {
      particle.update(dt);
    }

    // Remove dead particles
    _particles.removeWhere((particle) => !particle.isAlive);
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

  /// Get theme-specific colors
  List<Color> _getThemeColors(String theme) {
    switch (theme.toLowerCase()) {
      case 'sky rookie':
        return [Colors.blue.shade300, Colors.cyan.shade200, Colors.white];
      case 'space cadet':
        return [
          Colors.purple.shade300,
          Colors.indigo.shade300,
          Colors.blue.shade200,
        ];
      case 'storm ace':
        return [Colors.grey.shade300, Colors.blueGrey.shade300, Colors.white];
      case 'void master':
        return [
          Colors.deepPurple.shade300,
          Colors.purple.shade400,
          Colors.pink.shade200,
        ];
      case 'legend':
        return [
          Colors.yellow.shade300,
          Colors.orange.shade300,
          Colors.red.shade300,
        ];
      default:
        return [Colors.white, Colors.blue.shade200, Colors.cyan.shade200];
    }
  }
}
