import 'dart:collection';
import 'package:flame/components.dart';
import '../components/particle_effect.dart';

/// Object pooling system used by AAA mobile games for performance
/// Instead of creating/destroying objects, we reuse them from a pool
class ObjectPool<T> {
  final Queue<T> _pool = Queue<T>();
  final T Function() _factory;
  final void Function(T)? _reset;
  
  int _totalCreated = 0;
  int _poolHits = 0;
  int _poolMisses = 0;

  ObjectPool(this._factory, {void Function(T)? reset}) : _reset = reset;

  /// Get an object from the pool or create a new one
  T acquire() {
    if (_pool.isNotEmpty) {
      _poolHits++;
      final obj = _pool.removeFirst();
      _reset?.call(obj);
      return obj;
    } else {
      _poolMisses++;
      _totalCreated++;
      return _factory();
    }
  }

  /// Return an object to the pool for reuse
  void release(T obj) {
    if (_pool.length < 50) { // Prevent pool from growing too large
      _pool.add(obj);
    }
  }

  /// Get pool statistics for performance monitoring
  Map<String, dynamic> getStats() {
    return {
      'poolSize': _pool.length,
      'totalCreated': _totalCreated,
      'poolHits': _poolHits,
      'poolMisses': _poolMisses,
      'hitRate': _poolHits / (_poolHits + _poolMisses),
    };
  }

  void clear() {
    _pool.clear();
  }
}

/// Particle pool for efficient particle system management
class ParticlePool {
  static final ObjectPool<ParticleEffect> _explosionPool = ObjectPool<ParticleEffect>(
    () => ParticleEffect(),
    reset: (particle) => particle.reset(),
  );

  static final ObjectPool<Vector2> _vectorPool = ObjectPool<Vector2>(
    () => Vector2.zero(),
    reset: (vector) => vector.setZero(),
  );

  static ParticleEffect getExplosionParticle() => _explosionPool.acquire();
  static void releaseExplosionParticle(ParticleEffect particle) => _explosionPool.release(particle);

  static Vector2 getVector() => _vectorPool.acquire();
  static void releaseVector(Vector2 vector) => _vectorPool.release(vector);

  static Map<String, dynamic> getStats() {
    return {
      'explosionPool': _explosionPool.getStats(),
      'vectorPool': _vectorPool.getStats(),
    };
  }
}
