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
      }
    }
    // Single summary log instead of per-sprite logs
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
    // ✅ USER REQUEST: Enhanced smoke effect - modern, casual, and prominent
    final random = math.Random();
    
    // === SMOKE EFFECT ===
    // Multi-layered smoke cloud: Large → Medium → Small particles
    // This creates depth and realistic billowing smoke without assets
    
    // Layer 1: Large base smoke clouds (foundation)
    final largeSmokeCount = 8 + random.nextInt(5);
    for (int i = 0; i < largeSmokeCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final spreadAngle = (random.nextDouble() - 0.5) * math.pi * 0.4; // Wider spread
      final upwardSpeed = 60 + random.nextDouble() * 80; // Moderate upward
      final lateralDrift = (random.nextDouble() - 0.5) * 50;

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.sin(spreadAngle) * 40 + lateralDrift,
        -upwardSpeed, // Negative = up
      );
      
      // Large, slowly expanding smoke
      particle.lifetime = 2.5 + random.nextDouble() * 1.5; // Long-lasting
      particle.size = 20.0 + random.nextDouble() * 16.0; // LARGE base smoke
      particle.type = ParticleType.circle;
      particle.sizeGrowthPerSecond = 18.0; // Expand quickly for billowing effect
      particle.alpha = 0.35 + random.nextDouble() * 0.25; // Semi-transparent
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 1.0; // Slow rotation

      _activeParticles.add(particle);
    }
    
    // Layer 2: Medium smoke wisps (detail layer)
    final mediumSmokeCount = 12 + random.nextInt(8);
    for (int i = 0; i < mediumSmokeCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final spreadAngle = (random.nextDouble() - 0.5) * math.pi * 0.5;
      final upwardSpeed = 80 + random.nextDouble() * 100;
      final lateralDrift = (random.nextDouble() - 0.5) * 70;

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.sin(spreadAngle) * 50 + lateralDrift,
        -upwardSpeed,
      );
      
      particle.lifetime = 1.8 + random.nextDouble() * 1.2;
      particle.size = 12.0 + random.nextDouble() * 12.0; // Medium smoke
      particle.type = ParticleType.circle;
      particle.sizeGrowthPerSecond = 14.0; // Moderate expansion
      particle.alpha = 0.45 + random.nextDouble() * 0.3; // More opaque
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 1.5;

      _activeParticles.add(particle);
    }
    
    // Layer 3: Small smoke puffs (fine detail)
    final smallSmokeCount = 15 + random.nextInt(10);
    for (int i = 0; i < smallSmokeCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final spreadAngle = (random.nextDouble() - 0.5) * math.pi * 0.6;
      final upwardSpeed = 100 + random.nextDouble() * 120;
      final lateralDrift = (random.nextDouble() - 0.5) * 80;

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.sin(spreadAngle) * 60 + lateralDrift,
        -upwardSpeed,
      );
      
      particle.lifetime = 1.2 + random.nextDouble() * 0.8;
      particle.size = 6.0 + random.nextDouble() * 8.0; // Small puffs
      particle.type = ParticleType.circle;
      particle.sizeGrowthPerSecond = 10.0;
      particle.alpha = 0.5 + random.nextDouble() * 0.35; // Most opaque
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 2.0; // Faster rotation

      _activeParticles.add(particle);
    }

    // === FIRE/DEBRIS EFFECT ===
    // Add orange/yellow fire sparks and dark debris for impact
    final fireCount = 8 + random.nextInt(8);
    
    for (int i = 0; i < fireCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 100 + random.nextDouble() * 150;

      particle.position = position.clone();
      particle.velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 40, // Slight upward bias
      );
      
      particle.lifetime = 0.5 + random.nextDouble() * 0.4; // Quick flash
      particle.size = 4.0 + random.nextDouble() * 5.0;
      particle.type = ParticleType.confetti; // Rectangular fire sparks
      particle.rotation = random.nextDouble() * math.pi * 2;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 10.0; // Fast spin
      particle.sizeGrowthPerSecond = -2.0; // Shrink quickly
      particle.alpha = 0.8 + random.nextDouble() * 0.2; // Bright flash

      _activeParticles.add(particle);
    }
    
    // 🛑 PERFORMANCE FIX: Removed verbose logging for crash burst
    // (Crash is already logged elsewhere)
  }

  /// Create celebration burst for score milestones with vibrant effects
  void createCelebrationBurst(Vector2 position, int score) {
    // ✅ PERFORMANCE OPTIMIZED: Reduced particle counts for smoother gameplay
    final random = math.Random();
    
    // 🛑 PERFORMANCE FIX: Further reduced particle counts
    final int baseCount = 5; // Reduced from 8 for better performance
    final int bonus5 = (score % 5 == 0) ? 3 : 0; // Reduced from 4
    final int bonus10 = (score % 10 == 0) ? 5 : 0; // Reduced from 8
    final int count = baseCount + bonus5 + bonus10;
    
    final bool isMilestone = score % 10 == 0;
    final bool isHalfMilestone = score % 5 == 0;
    
    // === RING WAVE EFFECT ===
    // Create an expanding ring of particles for modern, satisfying feedback
    // 🛑 PERFORMANCE FIX: Reduced ring particle counts
    final ringParticleCount = isMilestone ? 6 : (isHalfMilestone ? 4 : 3);
    for (int i = 0; i < ringParticleCount; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;
      
      // Evenly distributed angles for perfect ring
      final angle = (i / ringParticleCount) * 2 * math.pi;
      final ringSpeed = isMilestone ? 220 : 180;
      
      particle.position = position.clone();
      particle.velocity = Vector2(
        math.cos(angle) * ringSpeed,
        math.sin(angle) * ringSpeed,
      );
      
      particle.lifetime = 0.6 + random.nextDouble() * 0.3;
      particle.size = isMilestone ? 8.0 : 6.0; // Smaller, more subtle
      particle.type = ParticleType.star; // Stars for ring effect
      particle.rotation = angle; // Rotate to face outward
      particle.angularVelocity = 0; // Keep orientation
      particle.alpha = 0.9;
      particle.sizeGrowthPerSecond = -3.0; // Quick fade

      _activeParticles.add(particle);
    }
    
    // === EXPLOSION BURST ===
    // Main celebration explosion with varied particles
    for (int i = 0; i < count; i++) {
      final particle = _pool.acquire();
      if (particle == null) continue;

      final angle = random.nextDouble() * 2 * math.pi;
      
      // ✅ MODERN: Varied speed patterns for more dynamic feel
      final speedMultiplier = isMilestone ? 1.5 : (isHalfMilestone ? 1.3 : 1.0);
      final speed = (180 * speedMultiplier) + random.nextDouble() * (200 * speedMultiplier);
      
      // ✅ CASUAL: Add some randomness to make it feel more playful
      final verticalBias = (random.nextDouble() - 0.5) * 100; // More vertical variety
      
      particle.position = position.clone();
      particle.velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed + verticalBias,
      );
      
      // ✅ SUBTLE: Smaller particles for cleaner look
      particle.lifetime = 1.0 + random.nextDouble() * 0.8; // Shorter lifetime
      particle.size = 8.0 + random.nextDouble() * 8.0; // Smaller particles (was 14-34)
      
      // ✅ MODERN: Choose particle type with better distribution
      if (isMilestone) {
        // Special sparkly effects for 10-point milestones
        final typeChoice = i % 3;
        particle.type = typeChoice == 0 ? ParticleType.star : 
                       typeChoice == 1 ? ParticleType.confetti : ParticleType.circle;
      } else if (isHalfMilestone) {
        // Mixed effects for 5-point milestones
        particle.type = i % 3 == 0 ? ParticleType.star : ParticleType.circle;
      } else {
        // Regular celebration mix - colorful variety
        particle.type = i % 2 == 0 ? ParticleType.circle : ParticleType.confetti;
      }
      
      particle.rotation = random.nextDouble() * 2 * math.pi;
      particle.angularVelocity = (random.nextDouble() - 0.5) * 12.0; // Fast rotation for excitement!
      particle.alpha = 0.85 + random.nextDouble() * 0.15; // Bright and vibrant
      particle.sizeGrowthPerSecond = isMilestone ? -0.5 : -1.5; // Milestones linger longer

      _activeParticles.add(particle);
    }
    
    // === SECONDARY WAVE ===
    // 🛑 PERFORMANCE FIX: Disabled secondary wave for regular scores
    // Only create secondary wave for milestones (10, 20, 30...)
    if (isMilestone) {
      Future.delayed(const Duration(milliseconds: 120), () {
        for (int i = 0; i < 3; i++) { // Reduced from 4
          final particle = _pool.acquire();
          if (particle == null) continue;
          
          final angle = random.nextDouble() * 2 * math.pi;
          final speed = 140 + random.nextDouble() * 120;
          
          particle.position = position.clone();
          particle.velocity = Vector2(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 60, // Upward bias for excitement
          );
          particle.lifetime = 0.8 + random.nextDouble() * 0.4;
          particle.size = 6.0 + random.nextDouble() * 6.0;
          particle.type = ParticleType.star;
          particle.rotation = random.nextDouble() * 2 * math.pi;
          particle.angularVelocity = (random.nextDouble() - 0.5) * 15.0;
          particle.alpha = 0.75 + random.nextDouble() * 0.25;
          particle.sizeGrowthPerSecond = -2.0;
          
          _activeParticles.add(particle);
        }
      });
    }
    
    // Celebration burst log removed - too verbose during gameplay
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