import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle_pool.dart';
import '../../core/debug_logger.dart';

/// High-performance particle system using hardware-accelerated sprites
/// Enhanced with realistic smoke effects and vibrant celebration animations
class HardwareParticleSystem extends Component {
  final ParticlePool _pool = ParticlePool(maxParticles: 500);
  final List<Sprite> _particleSprites = [];
  final List<ParticleInstance> _activeParticles = [];
  bool _isInitialized = false;

  /// Check if the hardware particle system is ready
  bool get isInitialized => _isInitialized;

  /// Pre-render particle sprites for hardware acceleration
  Future<void> preRenderParticles() async {
    if (_isInitialized) return;

    // Create pre-rendered sprites for each particle type
    await _createParticleSprites();
    _isInitialized = true;
    
    safePrint('🚀 HardwareParticleSystem: Initialization complete - _isInitialized = $_isInitialized');
  }

  Future<void> _createParticleSprites() async {
    // Create 5 variations for each particle type (different sizes)
    for (final type in ParticleType.values) {
      for (int size = 1; size <= 5; size++) {
        final sprite = await _renderParticleToSprite(type, size * 4.0);
        _particleSprites.add(sprite);
        safePrint('🚀 HardwareParticleSystem: Created sprite for ${type.name} size ${size * 4.0}');
      }
    }
    safePrint('🚀 HardwareParticleSystem: Pre-rendered ${_particleSprites.length} particle sprites');
  }

  Future<Sprite> _renderParticleToSprite(ParticleType type, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    // Create a transparent background
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = Colors.transparent);

    // Render particle shape with proper colors
    switch (type) {
      case ParticleType.circle:
        // Create a gradient circle for better visual appeal
        final gradient = RadialGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.3)],
          stops: const [0.0, 1.0],
        );
        paint.shader = gradient.createShader(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2));
        canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
        break;

      case ParticleType.star:
        // Create a golden star with gradient
        final gradient = RadialGradient(
          colors: [Colors.amber, Colors.amber.withValues(alpha: 0.3)],
          stops: const [0.0, 1.0],
        );
        paint.shader = gradient.createShader(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2));
        _drawStar(canvas, Offset(size / 2, size / 2), size / 2, paint);
        break;

      case ParticleType.confetti:
        // Create colorful confetti with gradient
        final gradient = LinearGradient(
          colors: [Colors.red, Colors.blue, Colors.green],
          stops: const [0.0, 0.5, 1.0],
        );
        paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size, size));
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
      final angle = (i * math.pi / points) + math.pi; // Start from top
      final x = center.dx + r * math.sin(angle);
      final y = center.dy + r * math.cos(angle);

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
    double spread = math.pi * 2, // Full circle
  }) {
    for (int i = 0; i < count; i++) {
      final particle = _pool.acquire();
      if (particle == null) break; // Pool exhausted

      // Randomize particle properties
      final angle = (i / count) * spread;
      final velocity = Vector2(math.cos(angle) * speed, math.sin(angle) * speed);

      particle.position = position.clone();
      particle.velocity = velocity;
      particle.lifetime =
          lifetime + (math.Random().nextDouble() - 0.5) * 0.2; // ±10% variation
      particle.size = 8.0 + math.Random().nextDouble() * 8.0; // 8-16px
      particle.type = type;
      particle.rotation = math.Random().nextDouble() * math.pi * 2;
      particle.angularVelocity =
          (math.Random().nextDouble() - 0.5) * 10.0; // ±5 rad/s
      particle.sizeGrowthPerSecond =
          -particle.size * 0.5; // Shrink over lifetime

      _activeParticles.add(particle);
    }
  }

  /// Create casual crash burst for collision effects with realistic smoke and fire
  void createCrashBurst(Vector2 position) {
    // Creating casual crash burst
    final random = math.Random();
    
    // Create subtle smoke with realistic physics
    final smokeCount = 8 + random.nextInt(6); // Fewer, more subtle smoke particles
    // Creating subtle smoke particles

    for (int i = 0; i < smokeCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      // Realistic smoke physics - gentle upward movement with slight drift
      final angle = (random.nextDouble() - 0.5) * math.pi * 0.2; // Very narrow upward cone
      final speed = 30 + random.nextDouble() * 40; // Slower, more casual
      final drift = (random.nextDouble() - 0.5) * 20; // Gentle side-to-side drift

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.sin(angle) * speed + drift, // Gentle horizontal drift
        math.cos(angle) * speed - 80, // Upward movement (slower)
      );
      
      // Smoke properties for casual realism
      particle.lifetime = 1.5 + random.nextDouble() * 1.0; // Shorter, more subtle
      particle.size = 8.0 + random.nextDouble() * 12.0; // Smaller smoke particles
      particle.type = ParticleType.circle;
      particle.sizeGrowthPerSecond = 8.0; // Gentle expansion
      particle.alpha = 0.3 + random.nextDouble() * 0.2; // More transparent
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 1.0; // Very slow rotation

      _activeParticles.add(particle);
    }

    // Create small fire sparks
    final fireCount = 4 + random.nextInt(4); // Fewer, smaller fire particles
    // Creating small fire particles
    
    for (int i = 0; i < fireCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 80 + random.nextDouble() * 120; // Moderate speed

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 50, // Slight upward bias
      );
      
      particle.lifetime = 0.4 + random.nextDouble() * 0.3; // Short-lived fire
      particle.size = 3.0 + random.nextDouble() * 4.0; // Small fire particles
      particle.type = ParticleType.confetti;
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 8.0;
      particle.sizeGrowthPerSecond = -1.5; // Gentle fade
      particle.alpha = 0.7 + random.nextDouble() * 0.3; // Bright but not overwhelming

      _activeParticles.add(particle);
    }
    
    // Casual crash burst complete
  }

  /// Create celebration burst for score milestones with vibrant effects
  void createCelebrationBurst(Vector2 position, int score) {
    // Creating vibrant celebration burst
    final random = math.Random();
    
    // Calculate particle count based on score milestones
    final int baseCount = 12;
    final int bonus5 = (score % 5 == 0) ? 8 : 0; // Extra for every 5th
    final int bonus10 = (score % 10 == 0) ? 15 : 0; // Extra for every 10th
    final int count = baseCount + bonus5 + bonus10;
    
    // Creating celebration particles

    for (int i = 0; i < count; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * math.pi;
      final bool isMilestone = score % 10 == 0;
      final speed = (isMilestone ? 300 : 250) + random.nextDouble() * (isMilestone ? 200 : 150);
      
      particle.position = position.clone();
      particle.velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      // Enhanced particle properties
      particle.lifetime = 1.2 + random.nextDouble() * 0.8; // Longer celebration
      particle.size = 10.0 + random.nextDouble() * 15.0; // Larger particles
      
      // Choose particle type based on score and position
      if (isMilestone) {
        // Special effects for milestones
        particle.type = i % 3 == 0 ? ParticleType.star : ParticleType.confetti;
      } else {
        // Regular celebration mix
        particle.type = ParticleType.values[i % ParticleType.values.length];
      }
      
      particle.rotation = random.nextDouble() * 2 * math.pi;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 8.0; // Moderate rotation
      particle.alpha = 0.9 + random.nextDouble() * 0.1; // Bright and vibrant
      particle.sizeGrowthPerSecond = -1.5; // Gentle fade

      _activeParticles.add(particle);
    }
    
    // Celebration burst complete
  }

  @override
  void update(double dt) {
    if (!_isInitialized) return;

    // Update all active particles
    for (final particle in _activeParticles) {
      particle.update(dt);
    }

    // Remove dead particles efficiently
    _activeParticles.removeWhere((particle) {
      if (!particle.isAlive) {
        _pool.release(particle);
        return true;
      }
      return false;
    });

    // Debug output removed to reduce log spam
  }

  @override
  void render(Canvas canvas) {
    if (!_isInitialized) return;

    // Enhanced rendering with proper color application
    for (final particle in _activeParticles) {
      if (!particle.isAlive) continue;

      // Get appropriate color based on particle type and context
      Color particleColor = _getParticleColor(particle);
      
      // Create paint with proper blending
      final paint = Paint()
        ..color = particleColor.withValues(alpha: particle.alpha)
        ..blendMode = BlendMode.srcOver; // Use proper blending mode

      canvas.save();
      canvas.translate(particle.position.x, particle.position.y);
      canvas.rotate(particle.rotation);

      // Render particle shape directly for better control
      _renderParticleShape(canvas, particle, paint);
      
      canvas.restore();
    }
    
    // Render count log removed to reduce spam
  }

  /// Get appropriate color for particle based on type and context
  Color _getParticleColor(ParticleInstance particle) {
    final random = math.Random(particle.position.x.toInt() + particle.position.y.toInt());
    
    switch (particle.type) {
      case ParticleType.circle:
        // Check if this is smoke (low alpha) or celebration (high alpha)
        if (particle.alpha < 0.8) {
          // Smoke particles - realistic casual smoke colors
          final smokeColors = [
            Colors.grey.shade300,
            Colors.grey.shade400, 
            Colors.grey.shade500,
            Colors.white,
            Colors.grey.shade200,
            Colors.grey.shade600,
            Colors.grey.shade700,
            Colors.brown.shade300, // Slight brown tint for realism
          ];
          return smokeColors[random.nextInt(smokeColors.length)];
        } else {
          // Celebration circles - bright rainbow colors
          final celebrationColors = [
            Colors.yellow,
            Colors.orange,
            Colors.pink,
            Colors.cyan,
            Colors.lime,
            Colors.purple,
            Colors.red,
            Colors.blue,
          ];
          return celebrationColors[random.nextInt(celebrationColors.length)];
        }
        
      case ParticleType.star:
        // Stars - golden and bright colors
        final starColors = [
          Colors.amber,
          Colors.yellow,
          Colors.orange,
          Colors.deepOrange,
          Colors.amber.shade700,
          Colors.yellowAccent,
        ];
        return starColors[random.nextInt(starColors.length)];
        
      case ParticleType.confetti:
        // Check if this is fire (small size, short lifetime) or celebration confetti
        if (particle.size < 8.0 && particle.lifetime < 1.0) {
          // Fire particles - realistic fire colors
          final fireColors = [
            Colors.orange,
            Colors.deepOrange,
            Colors.red,
            Colors.orange.shade700,
            Colors.red.shade600,
            Colors.amber,
            Colors.yellow.shade600,
          ];
          return fireColors[random.nextInt(fireColors.length)];
        } else {
          // Celebration confetti - varied bright colors
          final confettiColors = [
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.purple,
            Colors.pink,
            Colors.teal,
            Colors.indigo,
            Colors.deepPurple,
          ];
          return confettiColors[random.nextInt(confettiColors.length)];
        }
    }
  }

  /// Render particle shape with enhanced visuals
  void _renderParticleShape(Canvas canvas, ParticleInstance particle, Paint paint) {
    switch (particle.type) {
      case ParticleType.circle:
        if (particle.alpha < 0.8) {
          // Smoke - render with realistic gradient for casual effect
          final gradient = RadialGradient(
            colors: [
              paint.color.withValues(alpha: particle.alpha * 0.8),
              paint.color.withValues(alpha: particle.alpha * 0.3),
              paint.color.withValues(alpha: particle.alpha * 0.1),
            ],
            stops: const [0.0, 0.6, 1.0],
          );
          final gradientPaint = Paint()
            ..shader = gradient.createShader(Rect.fromCircle(
              center: Offset.zero, 
              radius: particle.size / 2,
            ));
          canvas.drawCircle(Offset.zero, particle.size / 2, gradientPaint);
        } else {
          // Celebration circles - solid bright colors
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        }
        break;
        
      case ParticleType.star:
        _drawStar(canvas, Offset.zero, particle.size / 2, paint);
        break;
        
      case ParticleType.confetti:
        // Check if this is fire or celebration confetti
        if (particle.size < 8.0 && particle.lifetime < 1.0) {
          // Fire particles - render as small circles with glow effect
          final gradient = RadialGradient(
            colors: [
              paint.color.withValues(alpha: particle.alpha),
              paint.color.withValues(alpha: particle.alpha * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          );
          final gradientPaint = Paint()
            ..shader = gradient.createShader(Rect.fromCircle(
              center: Offset.zero, 
              radius: particle.size / 2,
            ));
          canvas.drawCircle(Offset.zero, particle.size / 2, gradientPaint);
        } else {
          // Celebration confetti - draw diamond shape
          final path = Path();
          path.moveTo(0, -particle.size / 2);
          path.lineTo(particle.size / 2, 0);
          path.lineTo(0, particle.size / 2);
          path.lineTo(-particle.size / 2, 0);
          path.close();
          canvas.drawPath(path, paint);
        }
        break;
    }
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