import 'dart:collection';
import 'package:flame/components.dart';
import '../../core/debug_logger.dart';

/// Particle types for hardware-accelerated rendering
enum ParticleType { circle, star, confetti }

/// Represents a single particle instance with minimal memory footprint
class ParticleInstance {
  final int id;
  Vector2 position;
  Vector2 velocity;
  double size;
  double age;
  double lifetime;
  bool isAlive;
  ParticleType type;
  double rotation;
  double angularVelocity;
  double alpha;
  double sizeGrowthPerSecond;

  ParticleInstance(this.id)
    : position = Vector2.zero(),
      velocity = Vector2.zero(),
      size = 8.0,
      age = 0.0,
      lifetime = 1.0,
      isAlive = true,
      type = ParticleType.circle,
      rotation = 0.0,
      angularVelocity = 0.0,
      alpha = 1.0,
      sizeGrowthPerSecond = 0.0;

  void update(double dt) {
    if (!isAlive) return;

    position += velocity * dt;
    velocity.y += 800.0 * dt; // Gravity
    age += dt;
    rotation += angularVelocity * dt;

    if (sizeGrowthPerSecond != 0.0) {
      size += sizeGrowthPerSecond * dt;
      if (size < 0) size = 0;
    }

    alpha = 1.0 - (age / lifetime);
    if (alpha < 0) alpha = 0;

    if (age >= lifetime) {
      isAlive = false;
      // Debug output for testing
      safePrint('Particle $id died: age=$age, lifetime=$lifetime');
    }
  }

  void reset() {
    position = Vector2.zero();
    velocity = Vector2.zero();
    size = 8.0;
    age = 0.0;
    lifetime = 1.0;
    isAlive = true;
    rotation = 0.0;
    angularVelocity = 0.0;
    alpha = 1.0;
    sizeGrowthPerSecond = 0.0;
  }
}

/// High-performance particle pool for memory-efficient particle management
class ParticlePool {
  final int maxParticles;
  final Queue<ParticleInstance> _available = Queue<ParticleInstance>();
  final Set<ParticleInstance> _active = {};
  int _nextId = 0;

  ParticlePool({required this.maxParticles}) {
    // Pre-allocate all particles for zero-allocation runtime
    for (int i = 0; i < maxParticles; i++) {
      _available.add(ParticleInstance(_nextId++));
    }
  }

  /// Acquire a particle from the pool
  ParticleInstance? acquire() {
    if (_available.isNotEmpty) {
      final particle = _available.removeFirst();
      _active.add(particle);
      return particle;
    }
    return null;
  }

  /// Release a particle back to the pool
  void release(ParticleInstance particle) {
    if (_active.contains(particle)) {
      _active.remove(particle);
      particle.reset();
      _available.add(particle);
    }
  }

  /// Get the number of active particles
  int get activeCount => _active.length;

  /// Get the number of available particles
  int get availableCount => _available.length;

  /// Get total pool size
  int get totalCount => maxParticles;

  /// Clear all active particles
  void clearActive() {
    for (final particle in _active) {
      particle.reset();
      _available.add(particle);
    }
    _active.clear();
  }

  /// Get pool utilization percentage
  double get utilization => activeCount / maxParticles;
}
