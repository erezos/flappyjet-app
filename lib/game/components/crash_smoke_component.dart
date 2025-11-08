import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 💨 Realistic Smoke Particle Component using actual smoke assets
/// Used for crash effects in-game
class SmokeParticleComponent extends SpriteComponent with HasGameReference {
  final Vector2 velocity;
  final double lifetime;
  final double rotationSpeed;
  final double expansionRate;
  
  double _age = 0.0;
  
  SmokeParticleComponent({
    required super.sprite,
    required super.position,
    required super.size,
    required this.velocity,
    required this.lifetime,
    required this.rotationSpeed,
    required this.expansionRate,
    super.anchor = Anchor.center,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _age += dt;
    
    // Remove when lifetime expires
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    
    // Calculate progress (0.0 to 1.0)
    final progress = _age / lifetime;
    
    // Move with velocity (slowing down over time due to drag)
    final drag = 0.9; // Simulate air resistance
    position.add(velocity * dt * (1.0 - progress * drag));
    
    // Expand size
    final newSize = size.x + (expansionRate * dt);
    size = Vector2.all(newSize);
    
    // Rotate
    angle += rotationSpeed * dt;
    
    // Fade out (more transparent as it ages)
    paint.color = Colors.white.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
  }
}

/// 🔥 Fire Spark Particle Component using actual fire spark assets
/// Used for fire effects in crash
class FireSparkComponent extends SpriteComponent with HasGameReference {
  final Vector2 velocity;
  final double lifetime;
  final double gravity;
  
  double _age = 0.0;
  
  FireSparkComponent({
    required super.sprite,
    required super.position,
    required super.size,
    required this.velocity,
    required this.lifetime,
    this.gravity = 100.0,
    super.anchor = Anchor.center,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _age += dt;
    
    // Remove when lifetime expires
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    
    // Calculate progress (0.0 to 1.0)
    final progress = _age / lifetime;
    
    // Move with velocity
    position.add(velocity * dt);
    
    // Apply gravity (sparks fall slightly)
    velocity.y += gravity * dt;
    
    // Fade and shrink
    final fadeProgress = (1.0 - progress).clamp(0.0, 1.0);
    paint.color = Colors.white.withValues(alpha: fadeProgress * 0.9);
    
    // Flicker effect (sine wave)
    final flicker = 0.7 + (0.3 * math.sin(_age * 10));
    paint.color = paint.color.withValues(alpha: paint.color.a * flicker);
    
    // Slight size reduction
    size = size * (1.0 - dt * 0.3);
  }
}

/// 🌫️ Crash Smoke System - Creates realistic smoke effect at crash location
class CrashSmokeSystem {
  final Component parent;
  final List<Sprite> smokeSprites;
  final List<Sprite> fireSprites;
  
  CrashSmokeSystem({
    required this.parent,
    required this.smokeSprites,
    required this.fireSprites,
  });
  
  /// Create a crash smoke effect at the given position (for player)
  void createCrashSmoke(Vector2 position) {
    _createCrashEffect(
      position: position,
      smokeCount: 6,
      smokeVariation: 4,
      smokeOpacity: 0.7, // More visible smoke
      fireCount: 4,
      fireVariation: 4,
      fireOpacity: 0.8,
    );
  }
  
  /// Create a bot crash effect (more fire, less smoke, orange tint)
  void createBotCrashSmoke(Vector2 position) {
    _createCrashEffect(
      position: position,
      smokeCount: 3, // Less smoke for bot
      smokeVariation: 3,
      smokeOpacity: 0.5, // More transparent smoke
      fireCount: 8, // MORE fire for dramatic bot crash
      fireVariation: 6,
      fireOpacity: 1.0, // Full opacity fire (more dramatic)
    );
  }
  
  /// Internal method to create crash effects with customizable parameters
  void _createCrashEffect({
    required Vector2 position,
    required int smokeCount,
    required int smokeVariation,
    required double smokeOpacity,
    required int fireCount,
    required int fireVariation,
    required double fireOpacity,
  }) {
    final random = math.Random();
    
    // === SMOKE PARTICLES (using real assets) ===
    final totalSmokeCount = smokeCount + random.nextInt(smokeVariation);
    for (int i = 0; i < totalSmokeCount; i++) {
      // Pick random smoke sprite
      final sprite = smokeSprites[random.nextInt(smokeSprites.length)];
      
      // Random velocity (rises upward with drift)
      final spreadAngle = (random.nextDouble() - 0.5) * math.pi * 0.5;
      final upwardSpeed = 40 + random.nextDouble() * 60;
      final lateralDrift = (random.nextDouble() - 0.5) * 40;
      
      final velocity = Vector2(
        math.sin(spreadAngle) * 30 + lateralDrift,
        -upwardSpeed, // Negative = up
      );
      
      // Create smoke particle
      final smoke = SmokeParticleComponent(
        sprite: sprite,
        position: position.clone() + Vector2(
          (random.nextDouble() - 0.5) * 10, // Slight position offset
          (random.nextDouble() - 0.5) * 10,
        ),
        size: Vector2.all(20 + random.nextDouble() * 15), // Start size
        velocity: velocity,
        lifetime: 1.5 + random.nextDouble() * 1.0,
        rotationSpeed: (random.nextDouble() - 0.5) * 2.0,
        expansionRate: 15 + random.nextDouble() * 10,
      );
      
      // Set initial opacity based on config
      smoke.paint.color = Colors.white.withValues(alpha: smokeOpacity);
      
      parent.add(smoke);
    }
    
    // === FIRE SPARKS (using real assets) ===
    final totalSparkCount = fireCount + random.nextInt(fireVariation);
    for (int i = 0; i < totalSparkCount; i++) {
      // Pick random fire spark sprite
      final sprite = fireSprites[random.nextInt(fireSprites.length)];
      
      // Sparks shoot out in all directions
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 80 + random.nextDouble() * 100;
      
      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed - 30, // Slight upward bias
      );
      
      // Create fire spark
      final spark = FireSparkComponent(
        sprite: sprite,
        position: position.clone(),
        size: Vector2.all(10 + random.nextDouble() * 8),
        velocity: velocity,
        lifetime: 0.4 + random.nextDouble() * 0.3,
        gravity: 150.0,
      );
      
      // Set initial opacity based on config (with orange tint for fire)
      spark.paint.color = Colors.orange.withValues(alpha: fireOpacity);
      
      parent.add(spark);
    }
  }
}

