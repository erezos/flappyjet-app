import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle_pool.dart';
import '../../core/debug_logger.dart';

/// High-performance particle system using hardware-accelerated sprites
class HardwareParticleSystem extends Component {
  final ParticlePool _pool = ParticlePool(maxParticles: 500);
  final List<Sprite> _particleSprites = [];
  final List<ParticleInstance> _activeParticles = [];
  bool _isInitialized = false;

  /// Pre-render particle sprites for hardware acceleration
  Future<void> preRenderParticles() async {
    if (_isInitialized) return;

    // Create pre-rendered sprites for each particle type
    await _createParticleSprites();
    _isInitialized = true;
  }

  Future<void> _createParticleSprites() async {
    // Create 5 variations for each particle type (different sizes)
    for (final type in ParticleType.values) {
      for (int size = 1; size <= 5; size++) {
        final sprite = await _renderParticleToSprite(type, size * 4.0);
        _particleSprites.add(sprite);
      }
    }
  }

  Future<Sprite> _renderParticleToSprite(ParticleType type, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    // Render particle shape
    switch (type) {
      case ParticleType.circle:
        paint.color = Colors.white;
        canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
        break;

      case ParticleType.star:
        _drawStar(canvas, Offset(size / 2, size / 2), size / 2, paint);
        break;

      case ParticleType.confetti:
        paint.color = Colors.white;
        final rect = Rect.fromCenter(
          center: Offset(size / 2, size / 2),
          width: size * 0.8,
          height: size * 0.3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
        break;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    return Sprite(image);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final isOuter = i % 2 == 0;
      final r = isOuter ? radius : radius * 0.5;
      final angle = (i * 3.14159 / points) + 3.14159; // Start from top
      final x = center.dx + r * sin(angle);
      final y = center.dy + r * cos(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Create a burst of particles
  void createBurst({
    required Vector2 position,
    required int count,
    required ParticleType type,
    required Color color,
    double lifetime = 1.0,
    double speed = 200.0,
    double spread = 3.14159 * 2, // Full circle
  }) {
    for (int i = 0; i < count; i++) {
      final particle = _pool.acquire();
      if (particle == null) break; // Pool exhausted

      // Randomize particle properties
      final angle = (i / count) * spread;
      final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

      particle.position = position.clone();
      particle.velocity = velocity;
      particle.lifetime =
          lifetime + (Random().nextDouble() - 0.5) * 0.2; // ±10% variation
      particle.size = 8.0 + Random().nextDouble() * 8.0; // 8-16px
      particle.type = type;
      particle.rotation = Random().nextDouble() * 3.14159 * 2;
      particle.angularVelocity =
          (Random().nextDouble() - 0.5) * 10.0; // ±5 rad/s
      particle.sizeGrowthPerSecond =
          -particle.size * 0.5; // Shrink over lifetime

      _activeParticles.add(particle);
    }
  }

  /// Create celebration burst (replaces _createCelebrationBurst)
  void createCelebrationBurst(Vector2 position, int score) {
    final random = Random();

    // Base count increases with score
    int baseCount = 8;
    if (score % 5 == 0) baseCount += 6;
    if (score % 10 == 0) baseCount += 10;

    // Create burst with hardware acceleration
    createBurst(
      position: position,
      count: baseCount,
      type: ParticleType.circle,
      color: _getCelebrationColor(random),
      lifetime: 0.8 + random.nextDouble() * 0.4,
      speed: 200.0 + random.nextDouble() * 100.0,
    );
  }

  /// Create crash burst (replaces _createCrashBurst)
  void createCrashBurst(Vector2 position) {
    final random = Random();
    final smokeCount = 12 + random.nextInt(6);

    // Smoke particles
    for (int i = 0; i < smokeCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * 3.14159;
      final speed = 80 + random.nextDouble() * 90;

      particle.position = position.clone();
      particle.velocity = Vector2(
        cos(angle) * speed * 0.6,
        sin(angle) * speed * 0.2 - 200, // Rise upward
      );
      particle.lifetime = 0.9 + random.nextDouble() * 0.8;
      particle.size = 10.0 + random.nextDouble() * 18.0;
      particle.type = ParticleType.circle;
      particle.sizeGrowthPerSecond = 12.0; // Expand as smoke
      particle.alpha = 0.9;

      _activeParticles.add(particle);
    }

    // Spark particles
    final sparkCount = 10 + random.nextInt(8);
    for (int i = 0; i < sparkCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * 3.14159;
      final speed = 220 + random.nextDouble() * 180;

      particle.position = position.clone();
      particle.velocity = Vector2(cos(angle) * speed, sin(angle) * speed - 60);
      particle.lifetime = 0.35 + random.nextDouble() * 0.35;
      particle.size = 3.0 + random.nextDouble() * 3.0;
      particle.type = ParticleType.confetti;
      particle.rotation = random.nextDouble() * 3.14159;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 14.0;
      particle.sizeGrowthPerSecond = -1.5;

      _activeParticles.add(particle);
    }
  }

  Color _getCelebrationColor(Random random) {
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.lightGreenAccent,
      Colors.purpleAccent,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void update(double dt) {
    if (!_isInitialized) return;

    // Update all active particles
    for (final particle in _activeParticles) {
      particle.update(dt);
    }

    // Remove dead particles efficiently
    final beforeCount = _activeParticles.length;
    _activeParticles.removeWhere((particle) {
      if (!particle.isAlive) {
        _pool.release(particle);
        return true;
      }
      return false;
    });
    final afterCount = _activeParticles.length;

    // Debug output for testing
    if (beforeCount != afterCount) {
      safePrint('Particle cleanup: $beforeCount -> $afterCount');
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isInitialized) return;

    // Hardware-accelerated rendering using pre-rendered sprites
    for (final particle in _activeParticles) {
      if (!particle.isAlive) continue;

      final spriteIndex = _getSpriteIndex(particle.type, particle.size);
      if (spriteIndex >= 0 && spriteIndex < _particleSprites.length) {
        final sprite = _particleSprites[spriteIndex];

        // Apply color tint and alpha
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: particle.alpha)
          ..blendMode = BlendMode.modulate;

        canvas.save();
        canvas.translate(particle.position.x, particle.position.y);
        canvas.rotate(particle.rotation);
        canvas.scale(particle.size / 16.0); // Normalize to sprite size

        // Render the pre-computed sprite
        sprite.render(canvas, position: Vector2.zero(), overridePaint: paint);

        canvas.restore();
      }
    }
  }

  int _getSpriteIndex(ParticleType type, double size) {
    final sizeIndex = (size / 4.0).clamp(1, 5).toInt() - 1;
    final typeIndex = type.index;
    return typeIndex * 5 + sizeIndex;
  }

  /// Get access to particle sprites for testing
  List<Sprite> get particleSprites => _particleSprites;

  /// Get access to active particles for testing
  List<ParticleInstance> get activeParticles => _activeParticles;

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'active_particles': _activeParticles.length,
      'pool_utilization': _pool.utilization,
      'pool_active': _pool.activeCount,
      'pool_available': _pool.availableCount,
      'sprites_loaded': _particleSprites.length,
      'is_initialized': _isInitialized,
    };
  }

  /// Clear all particles
  void clearAll() {
    for (final particle in _activeParticles) {
      _pool.release(particle);
    }
    _activeParticles.clear();
  }
}
