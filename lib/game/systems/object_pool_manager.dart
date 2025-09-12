/// 🏊 OBJECT POOL MANAGER - Reduces GC pressure and improves performance
/// Prevents frequent allocations that cause "Background concurrent mark compact GC"
library;
import '../../core/debug_logger.dart';

import 'dart:collection';
import 'package:flame/components.dart';

/// Poolable object interface
abstract class Poolable {
  /// Reset object state for reuse
  void reset();
  
  /// Check if object is currently in use
  bool get isInUse;
  
  /// Set usage state
  set isInUse(bool value);
  
  /// Get unique identifier for debugging
  String get poolId;
}

/// Pool entry wrapper for tracking
class PoolEntry<T extends Poolable> {
  final T object;
  DateTime lastUsed;
  bool isActive;
  
  PoolEntry(this.object) 
    : lastUsed = DateTime.now(),
      isActive = false;
}

/// Generic object pool for any Poolable type
class ObjectPool<T extends Poolable> {
  final String poolName;
  final T Function() factory;
  final Queue<PoolEntry<T>> _available = Queue<PoolEntry<T>>();
  final Set<PoolEntry<T>> _inUse = <PoolEntry<T>>{};
  
  // Configuration
  final int maxSize;
  final Duration maxIdleTime;
  
  // Performance tracking
  int _totalRequests = 0;
  int _poolHits = 0;
  int _poolMisses = 0;
  int _objectsCreated = 0;
  int _objectsDestroyed = 0;

  ObjectPool({
    required this.poolName,
    required this.factory,
    this.maxSize = 50,
    this.maxIdleTime = const Duration(minutes: 2),
    int initialSize = 5,
  }) {
    // Pre-populate pool
    for (int i = 0; i < initialSize; i++) {
      final obj = factory();
      _available.add(PoolEntry(obj));
      _objectsCreated++;
    }
    
    safePrint('🏊 Created pool "$poolName" with $initialSize objects');
  }

  /// Get object from pool
  T get() {
    _totalRequests++;
    
    // Try to get from available pool
    if (_available.isNotEmpty) {
      final entry = _available.removeFirst();
      entry.isActive = true;
      entry.lastUsed = DateTime.now();
      entry.object.isInUse = true;
      _inUse.add(entry);
      _poolHits++;
      
      safePrint('🏊 [$poolName] Pool hit - ${_available.length} available, ${_inUse.length} in use');
      return entry.object;
    }
    
    // Create new object if under limit
    if (_inUse.length < maxSize) {
      final obj = factory();
      final entry = PoolEntry(obj);
      entry.isActive = true;
      entry.object.isInUse = true;
      _inUse.add(entry);
      _objectsCreated++;
      _poolMisses++;
      
      safePrint('🏊 [$poolName] Pool miss - created new object (${_inUse.length}/$maxSize)');
      return obj;
    }
    
    // Pool exhausted - force create (should be rare)
    safePrint('⚠️ [$poolName] Pool exhausted! Creating emergency object');
    _poolMisses++;
    _objectsCreated++;
    return factory();
  }

  /// Return object to pool
  void returnToPool(T object) {
    // Find the entry
    PoolEntry<T>? targetEntry;
    for (final entry in _inUse) {
      if (identical(entry.object, object)) {
        targetEntry = entry;
        break;
      }
    }
    
    if (targetEntry == null) {
      safePrint('⚠️ [$poolName] Attempted to return unknown object');
      return;
    }
    
    // Reset object state
    object.reset();
    object.isInUse = false;
    
    // Move to available pool
    _inUse.remove(targetEntry);
    targetEntry.isActive = false;
    targetEntry.lastUsed = DateTime.now();
    
    // Only add back if under size limit
    if (_available.length < maxSize) {
      _available.add(targetEntry);
      safePrint('🏊 [$poolName] Object returned - ${_available.length} available, ${_inUse.length} in use');
    } else {
      _objectsDestroyed++;
      safePrint('🏊 [$poolName] Object destroyed (pool full)');
    }
  }

  /// Cleanup idle objects
  void cleanup() {
    final now = DateTime.now();
    final toRemove = <PoolEntry<T>>[];
    
    for (final entry in _available) {
      if (now.difference(entry.lastUsed) > maxIdleTime) {
        toRemove.add(entry);
      }
    }
    
    for (final entry in toRemove) {
      _available.remove(entry);
      _objectsDestroyed++;
    }
    
    if (toRemove.isNotEmpty) {
      safePrint('🧹 [$poolName] Cleaned up ${toRemove.length} idle objects');
    }
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    final hitRate = _totalRequests > 0 
        ? (_poolHits / _totalRequests * 100).toStringAsFixed(1)
        : '0.0';
    
    return {
      'pool_name': poolName,
      'available': _available.length,
      'in_use': _inUse.length,
      'total_requests': _totalRequests,
      'pool_hits': _poolHits,
      'pool_misses': _poolMisses,
      'hit_rate_percent': hitRate,
      'objects_created': _objectsCreated,
      'objects_destroyed': _objectsDestroyed,
      'max_size': maxSize,
    };
  }

  /// Dispose all objects
  void dispose() {
    _available.clear();
    _inUse.clear();
    safePrint('🏊 [$poolName] Pool disposed');
  }
}

/// 🏊 OBJECT POOL MANAGER - Centralized pool management
class ObjectPoolManager {
  static ObjectPoolManager? _instance;
  static ObjectPoolManager get instance => _instance ??= ObjectPoolManager._();
  
  ObjectPoolManager._();

  final Map<String, ObjectPool> _pools = {};
  
  /// Register a new pool
  void registerPool<T extends Poolable>(
    String name,
    T Function() factory, {
    int maxSize = 50,
    Duration maxIdleTime = const Duration(minutes: 2),
    int initialSize = 5,
  }) {
    _pools[name] = ObjectPool<T>(
      poolName: name,
      factory: factory,
      maxSize: maxSize,
      maxIdleTime: maxIdleTime,
      initialSize: initialSize,
    );
    
    safePrint('🏊 Registered pool "$name"');
  }

  /// Get object from named pool
  T getFromPool<T extends Poolable>(String poolName) {
    final pool = _pools[poolName] as ObjectPool<T>?;
    if (pool == null) {
      throw Exception('Pool "$poolName" not found. Register it first.');
    }
    return pool.get();
  }

  /// Return object to named pool
  void returnToPool<T extends Poolable>(String poolName, T object) {
    final pool = _pools[poolName] as ObjectPool<T>?;
    if (pool == null) {
      safePrint('⚠️ Pool "$poolName" not found for return');
      return;
    }
    pool.returnToPool(object);
  }

  /// Cleanup all pools
  void cleanupAll() {
    for (final pool in _pools.values) {
      pool.cleanup();
    }
  }

  /// Get statistics for all pools
  Map<String, dynamic> getAllStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _pools.entries) {
      stats[entry.key] = entry.value.getStats();
    }
    
    // Calculate totals
    int totalAvailable = 0;
    int totalInUse = 0;
    int totalRequests = 0;
    int totalHits = 0;
    
    for (final poolStats in stats.values) {
      totalAvailable += poolStats['available'] as int;
      totalInUse += poolStats['in_use'] as int;
      totalRequests += poolStats['total_requests'] as int;
      totalHits += poolStats['pool_hits'] as int;
    }
    
    final overallHitRate = totalRequests > 0 
        ? (totalHits / totalRequests * 100).toStringAsFixed(1)
        : '0.0';
    
    stats['_totals'] = {
      'total_pools': _pools.length,
      'total_available': totalAvailable,
      'total_in_use': totalInUse,
      'total_requests': totalRequests,
      'overall_hit_rate_percent': overallHitRate,
    };
    
    return stats;
  }

  /// Dispose all pools
  void dispose() {
    for (final pool in _pools.values) {
      pool.dispose();
    }
    _pools.clear();
    safePrint('🏊 All pools disposed');
  }
}

/// 🎮 COMMON POOLABLE OBJECTS

/// Poolable Vector2 for position calculations
class PoolableVector2 implements Poolable {
  bool _isInUse = false;
  static int _idCounter = 0;
  final int _id = _idCounter++;
  
  double x = 0.0;
  double y = 0.0;

  PoolableVector2([this.x = 0, this.y = 0]);
  
  /// Set both components
  void setValues(double x, double y) {
    this.x = x;
    this.y = y;
  }
  
  /// Set to zero
  void setZero() {
    x = 0.0;
    y = 0.0;
  }

  @override
  void reset() {
    setZero();
  }

  @override
  bool get isInUse => _isInUse;

  @override
  set isInUse(bool value) => _isInUse = value;

  @override
  String get poolId => 'Vector2_$_id';
}

/// Poolable particle for effects
class PoolableParticle implements Poolable {
  Vector2 position = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  double size = 1.0;
  double age = 0.0;
  double lifetime = 1.0;
  bool _isInUse = false;
  
  static int _idCounter = 0;
  final int _id = _idCounter++;

  @override
  void reset() {
    position.setZero();
    velocity.setZero();
    size = 1.0;
    age = 0.0;
    lifetime = 1.0;
  }

  @override
  bool get isInUse => _isInUse;

  @override
  set isInUse(bool value) => _isInUse = value;

  @override
  String get poolId => 'Particle_$_id';
}

/// Poolable collision data
class PoolableCollisionData implements Poolable {
  Vector2 position = Vector2.zero();
  Vector2 size = Vector2.zero();
  String objectId = '';
  double damage = 0.0;
  bool _isInUse = false;
  
  static int _idCounter = 0;
  final int _id = _idCounter++;

  @override
  void reset() {
    position.setZero();
    size.setZero();
    objectId = '';
    damage = 0.0;
  }

  @override
  bool get isInUse => _isInUse;

  @override
  set isInUse(bool value) => _isInUse = value;

  @override
  String get poolId => 'CollisionData_$_id';
}

/// 🏊 POOL EXTENSIONS - Convenience methods
extension PoolManagerExtensions on ObjectPoolManager {
  /// Initialize common pools
  void initializeCommonPools() {
    registerPool<PoolableVector2>(
      'vectors',
      () => PoolableVector2(),
      maxSize: 100,
      initialSize: 20,
    );
    
    registerPool<PoolableParticle>(
      'particles',
      () => PoolableParticle(),
      maxSize: 200,
      initialSize: 50,
    );
    
    registerPool<PoolableCollisionData>(
      'collisions',
      () => PoolableCollisionData(),
      maxSize: 50,
      initialSize: 10,
    );
    
    safePrint('🏊 Common pools initialized');
  }

  /// Quick vector pool access
  PoolableVector2 getVector() => getFromPool<PoolableVector2>('vectors');
  void returnVector(PoolableVector2 vector) => returnToPool('vectors', vector);

  /// Quick particle pool access
  PoolableParticle getParticle() => getFromPool<PoolableParticle>('particles');
  void returnParticle(PoolableParticle particle) => returnToPool('particles', particle);

  /// Quick collision data pool access
  PoolableCollisionData getCollisionData() => getFromPool<PoolableCollisionData>('collisions');
  void returnCollisionData(PoolableCollisionData data) => returnToPool('collisions', data);
}